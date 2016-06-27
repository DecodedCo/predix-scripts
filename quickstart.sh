#!/bin/bash
set -e
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Be sure to set all your variables in the variables.sh file before you run quick start!

quickstartRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
quickstartLogDir="$quickstartRootDir/log"
PREDIX_SERVICES_TEXTFILE="$quickstartLogDir/predix-services-summary.txt"
rm -rf 	$PREDIX_SERVICES_TEXTFILE

source "$quickstartRootDir/scripts/error_handling_funcs.sh"
source "$quickstartRootDir/scripts/files_helper_funcs.sh"
source "$quickstartRootDir/scripts/curl_helper_funcs.sh"

run_services=0
run_machine=0
run_frontend=0
run_password=0
run_cleanup=0

# Trap ctrlc and exit if encountered

trap "trap_ctrlc" 2

# Creating a logfile if it doesn't exist
if ! [ -d "$quickstartLogDir" ]; then
	mkdir "$quickstartLogDir"
	chmod 744 "$quickstartLogDir"
fi

touch "$quickstartLogDir/quickstartlog.log"

#flag handling

#Flag handling
#no argument -> run everything
if (($# == 0)); then
	__append_new_line_log "# Will perform default run #" "$quickstartLogDir"
  run_services=1
  run_machine=1
  run_frontend=1
  run_cleanup=1
fi


while getopts ":hp:smfc" opt; do
  case $opt in
  	h)
		__print_out_usage
		exit
		;;
    s)
      __append_new_line_log "# Services option selected! #" "$quickstartLogDir"
      run_services=1
      ;;
    m)
      __append_new_line_log "# Machine configuration option selected! #" "$quickstartLogDir"
      run_machine=1
      ;;
    f)
      __append_new_line_log "# Frontend option selected! #" "$quickstartLogDir"
      run_frontend=1
      ;;

    p)
		  run_password=1
			if [ ${#OPTARG} -eq 2 ] && [[ "${OPTARG:0:1}" == "-" ]]; then
				echo "Option: \"$opt\" requires a value"
				exit 1
			fi

		  CF_PASSWORD=$OPTARG
	  ;;
	c)
		__append_new_line_log "# Clean up option selected! #" "$quickstartLogDir"
		run_cleanup=1
	  ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

#if  [ $run_services -ne 1 ] ; then
#	__append_new_line_log "# Running the script without Services option is not allowed! #" "$quickstartLogDir"
#	exit 1
#fi

__append_new_line_log "# quickstart.sh script started! #" "$quickstartLogDir"
echo -e "Welcome to the Predix Quick start script!\n"

#GLOBAL APPENDER
GLOBAL_APPENDER=""
CF_HOST="api.system.aws-usw02-pr.ice.predix.io"
echo "Apps and Services in the Predix Cloud need a unique url.  Enter your global appender, e.g. thomas-edison, for Predix Services and Applications followed by ENTER"
read GLOBAL_APPENDER
export GLOBAL_APPENDER

source "$quickstartRootDir/scripts/variables.sh"

# Login into Cloud Foundy using the user input or password entered on request

#echo -e "Be sure to set all your variables in the varcf iables.sh file before you run quick start!\n\n"
echo -e " ### Checking if you are logged into Cloud Foundry ### \n"

# Login into Cloud Foundy using the user input or password entered on request
userSpace="`cf t | grep Space | awk '{print $2}'`"
if [[ "$userSpace" == "" ]] ; then
	if [ $run_password -eq 1 ] ; then
		__append_new_line_log "Using the provided authentication passed to the script..." "$quickstartLogDir"

	else
		echo "Enter your CF username followed by ENTER"
		read CF_USERNAME
		echo "Enter your CF password followed by ENTER"
		read -s CF_PASSWORD
	fi

	__append_new_line_log "Attempting to login user \"$CF_USERNAME\" to host \"$CF_HOST\" Cloud Foundry. Space: \"$CF_SPACE\" Org: \"$CF_ORG\"" "$quickstartLogDir"
	if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD --skip-ssl-validation; then
		__append_new_line_log "Successfully logged into CloudFoundry" "$quickstartLogDir"
	else
		__error_exit "There was an error logging into CloudFoundry. Is the password correct?" "$quickstartLogDir"
	fi
fi
if [[ $run_cleanup -eq 1 ]]; then
	./scripts/cleanup.sh "$TEMP_APP"
fi

# Instantiate, configure, and push the following Predix services: Timeseries, Asset, and UAA.
if [ $run_services -eq 1 ]; then	
	./scripts/predix_services_setup.sh "$TEMP_APP"
fi


# Build Predix Machine container using properties from Predix Services Created above
if [ $run_machine -eq 1 ]; then
	./scripts//predix_machine_setup.sh "$TEMP_APP" "$run_services"
fi


# Build our application from the 'predix-nodejs-starter' repo, passing it our MS instances
if [ $run_frontend -eq 1 ]; then
	./scripts//build-basic-app.sh "$TEMP_APP" "$run_services"
fi



# Delete the TEMP APP created earlier
#__append_new_line_log "Deleting the $TEMP_APP" "$quickstartLogDir"
#if cf d $TEMP_APP -f -r; then
#	__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#else
#	__append_new_line_log "Failed to delete $TEMP_APP. Retrying..." "$quickstartLogDir"
#	if cf d $TEMP_APP -f -r; then
#		__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#	else
#		__append_new_line_log "Failed to delete $TEMP_APP. Last attempt..." "$quickstartLogDir"
#		if cf d $TEMP_APP -f -r; then
#			__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#		else
#			__error_exit "Failed to delete $TEMP_APP. Giving up" "$quickstartLogDir"
#		fi
#	fi
#fi
echo "adsfadsfadsf"
cat $PREDIX_SERVICES_TEXTFILE
