#!/bin/bash
set -e
predixMachineSetupRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
predixMachineLogDir="$predixMachineSetupRootDir/../log"

PREDIX_SERVICES_TEXTFILE="$predixMachineLogDir/predix-services-summary.txt"
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to configure a Predix Machine Container
# with the values corresponding to the Predix Services and Predix Application created
#

source "$predixMachineSetupRootDir/variables.sh"
source "$predixMachineSetupRootDir/error_handling_funcs.sh"
source "$predixMachineSetupRootDir/files_helper_funcs.sh"
source "$predixMachineSetupRootDir/curl_helper_funcs.sh"

if ! [ -d "$predixMachineLogDir" ]; then
	mkdir "$predixMachineLogDir"
	chmod 744 "$predixMachineLogDir"
fi
touch "$predixMachineLogDir/quickstartlog.log"

# Trap ctrlc and exit if encountered

trap "trap_ctrlc" 2
__validate_num_arguments 2 $# "\"predix-machine-setup.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$predixMachineLogDir"

__append_new_line_log "*** CONFIGURING, CREATING PREDIX MACHINE CONTAINER! ***" "$predixMachineLogDir"
__append_new_line_log "Setting predix machine configurations" "$predixMachineLogDir"

# Get the UAA enviorment variables (VCAPS)

if trustedIssuerID=$(cf env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$trustedIssuerID" == "" ]] ; then
    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$predixMachineLogDir"
  fi
  __append_new_line_log "trustedIssuerID copied from enviromental variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting the UAA trustedIssuerID..." "$predixMachineLogDir"
fi

if uaaURL=$(cf env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$uaaURL" == "" ]] ; then
    __error_exit "The UAA URL was not found for \"$1\"..." "$predixMachineLogDir"
  fi
  __append_new_line_log "UAA URL copied from enviromental variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting the UAA URL..." "$predixMachineLogDir"
fi

if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
	if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
		__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$predixMachineLogDir"
	fi
	__append_new_line_log " TIMESERIES_INGEST_URI copied from enviromental variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$predixMachineLogDir"
fi

if TIMESERIES_QUERY_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep time-series | awk -F"\"" '{print $4}'); then
	if [[ "$TIMESERIES_QUERY_URI" == "" ]] ; then
		__error_exit "The TIMESERIES_QUERY_URI was not found for \"$1\"..." "$predixMachineLogDir"
	fi
	__append_new_line_log "TIMESERIES_QUERY_URI copied from enviromental variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$predixMachineLogDir"
fi

if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
	echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
	__append_new_line_log "TIMESERIES_ZONE_ID copied from enviromental variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$predixMachineLogDir"
fi

# Get the Zone ID from the enviroment variables (for use when querying Asset data)
if ASSET_ZONE_ID=$(cf env $1 | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	if [[ "$ASSET_ZONE_ID" == "" ]] ; then
		__error_exit "The Asset Zone ID was not found for \"$1\"..." "$predixMachineLogDir"
	fi
	__append_new_line_log "ASSET_ZONE_ID copied from environment variables!" "$predixMachineLogDir"
else
	__error_exit "There was an error getting ASSET_ZONE_ID..." "$predixMachineLogDir"
fi
# Get the asset URL from the enviroment variables (for use when querying Asset data)
if assetURI=$(cf env $TEMP_APP | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
	__append_new_line_log "assetURI copied from environment variables! $assetURI" "$predixMachineLogDir"
else
	__error_exit "There was an error getting assetURI..." "$predixMachineLogDir"
fi

PREDIX_MACHINE_HOME="$predixMachineSetupRootDir/../PredixMachine"
echo $PREDIX_MACHINE_HOME
if [ "$MACHINE_TEMPLATES_GITHUB_REPO_URL" != "" ]
then
	echo "Going to $predixMachineSetupRootDir"
	machineTemplatesRepoName="`echo $MACHINE_TEMPLATES_GITHUB_REPO_URL | awk -F"/" '{print $5}' | awk -F"." '{print $1}'`"
	echo "Repo Nanme : $DEVICE_SPECIFIC_GITHUB_REPO_NAME"
	echo "Git URL : $MACHINE_TEMPLATES_GITHUB_REPO_URL"
	echo "Removing $machineTemplatesRepoName"
	rm -rf $machineTemplatesRepoName
	git clone $MACHINE_TEMPLATES_GITHUB_REPO_URL --recursive
	
	#Unzip the original PredixMachine container
	rm -rf $PREDIX_MACHINE_HOME
	unzip -oq $machineTemplatesRepoName/PredixMachine.zip -d $PREDIX_MACHINE_HOME

	$predixMachineSetupRootDir/machineconfig.sh "$trustedIssuerID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$uaaURL" "$PREDIX_MACHINE_HOME"

	SCRIPT_RUN_DIR="$predixMachineSetupRootDir/../$machineTemplatesRepoName/$DEVICE_SPECIFIC_GITHUB_REPO_NAME"

	$SCRIPT_RUN_DIR/quickstart.sh "$PREDIX_MACHINE_HOME"
	echo "Removing $machineTemplatesRepoName"
	rm -rf $machineTemplatesRepoName
fi

if [ "$(uname -s)" == "Darwin" -o "$(expr substr $(uname -s) 1 5)" == "Linux" ]
then
	__append_new_line_log "Zipping up the configured Predix Machine..." "$predixMachineLogDir"
	rm -rf PredixMachineContainer.zip
	
	if zip -rq PredixMachineContainer.zip PredixMachine; then
		__append_new_line_log "Zipped up the configured Predix Machine and storing in PredixMachineContainer.zip" "$predixMachineLogDir"
	else
		__error_exit "Failed to zip up PredixMachine" "$predixMachineLogDir"
	fi
	
	#rm -rf PredixMachine
	TARGETDEVICEIP=""
	TARGETDEVICEUSER=""
	echo "Enter the ipaddress of your device followed by ENTER"
	read TARGETDEVICEIP
	echo "Enter the user name of your device followed by ENTER"
	read TARGETDEVICEUSER
	echo "scp PredixMachineContainer.zip $TARGETDEVICEUSER@$TARGETDEVICEIP:PredixMachineContainer.zip"
	scp PredixMachineContainer.zip $TARGETDEVICEUSER@$TARGETDEVICEIP:PredixMachineContainer.zip
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]
then
	__append_new_line_log "You must manually zip of PredixMachine_16.1.0 to port it to the Raspberry Pi" "$predixMachineLogDir"
elif [ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]
then
	__append_new_line_log "You must manually zip of PredixMachine_16.1.0 to port it to the Raspberry Pi" "$predixMachineLogDir"
fi
# Call the correct zip depending on the OS... and get the base64 of the UAA base64ClientCredential
__append_new_line_log "*** SUCCESSFULLY CONFIGURED PREDIX MACHINE CONTAINER! ***" "$predixMachineLogDir"

if [ "$2" == "0" ] 
then
	__append_new_line_log "Predix Services Configurations found in file: \"$PREDIX_SERVICES_TEXTFILE\"" "$predixMachineLogDir"
	echo "" > $PREDIX_SERVICES_TEXTFILE
	echo "**********************SUCCESS*************************" >> $PREDIX_SERVICES_TEXTFILE
	echo "echoing properties from $PREDIX_SERVICES_TEXTFILE"  >> $PREDIX_SERVICES_TEXTFILE
	echo "What did we do:"  >> $PREDIX_SERVICES_TEXTFILE
	echo "We created a Basic Predix App with Predix Machine integration"  >> $PREDIX_SERVICES_TEXTFILE
	echo "Installed UAA with a client_id/secret (for your app) and a user/password (for your users to log in to your app)" >> $PREDIX_SERVICES_TEXTFILE
	echo "Installed Time Series and added time series scopes as client_id authorities" >> $PREDIX_SERVICES_TEXTFILE
	echo "Installed Asset and added asset scopes as client_id authorities" >> $PREDIX_SERVICES_TEXTFILE
	echo "Installed a simple front-end named $FRONT_END_APP_NAME and updated the property files and manifest.yml with UAA, Time Series and Asset info" >> $PREDIX_SERVICES_TEXTFILE
	echo "Installed Predix Machine and updated the property files with UAA and Time Series info" >> $PREDIX_SERVICES_TEXTFILE
	echo "" >> $PREDIX_SERVICES_TEXTFILE
	echo "Predix Dev Bootstrap Configuration" >> $PREDIX_SERVICES_TEXTFILE
	echo "Authors SDLP v1 2015" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA URL: $uaaURL" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA Admin Client ID: admin" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA Admin Client Secret: $UAA_ADMIN_SECRET" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA Generic Client ID: $UAA_CLIENTID_GENERIC" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA Generic Client Secret: $UAA_CLIENTID_GENERIC_SECRET" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA User ID: $UAA_USER_NAME" >> $PREDIX_SERVICES_TEXTFILE
	echo "UAA User PASSWORD: $UAA_USER_PASSWORD" >> $PREDIX_SERVICES_TEXTFILE
	echo "TimeSeries Ingest URL:  $TIMESERIES_INGEST_URI" >> $PREDIX_SERVICES_TEXTFILE
	echo "TimeSeries Query URL:  $TIMESERIES_QUERY_URI" >> $PREDIX_SERVICES_TEXTFILE
	echo "TimeSeries ZoneID: $TIMESERIES_ZONE_ID" >> $PREDIX_SERVICES_TEXTFILE
	echo "Asset URL:  $assetURI" >> $PREDIX_SERVICES_TEXTFILE
	echo "Asset Zone ID: $ASSET_ZONE_ID" >> $PREDIX_SERVICES_TEXTFILE
	echo "Front end App Name URL: https://$FRONT_END_APP_NAME.run.aws-usw02-pr.ice.predix.io" >> $PREDIX_SERVICES_TEXTFILE
	echo "" >> $PREDIX_SERVICES_TEXTFILE
	echo -e "You can execute 'cf env "$FRONT_END_APP_NAME"' to view info about your front-end app, UAA, Asset, and Time Series" >> $PREDIX_SERVICES_TEXTFILE
	echo -e "In your web browser, navigate to your front end application endpoint" >> $PREDIX_SERVICES_TEXTFILE
fi
