#!/bin/bash
set -e
buildBasicAppRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
buildBasicAppLogDir="$buildBasicAppRootDir/../log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to clone the predix-nodejs-starter repo,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "$buildBasicAppRootDir/variables.sh"
source "$buildBasicAppRootDir/error_handling_funcs.sh"
source "$buildBasicAppRootDir/files_helper_funcs.sh"

trap "trap_ctrlc" 2

PROGNAME=$(basename $0)
GIT_FRONT_END_FILENAME="$buildBasicAppRootDir/../predix-nodejs-starter"
GIT_BRANCH_RASPBERRY_PI="TransformWorkshop"
BUILD_APP_TEXTFILE="$buildBasicAppLogDir/build-basic-app-summary.txt"

if ! [ -d "$buildBasicAppLogDir" ]; then
	mkdir "$buildBasicAppLogDir"
	chmod 744 "$buildBasicAppLogDir"
fi
touch "$buildBasicAppLogDir/quickstartlog.log"

PREDIX_SERVICES_TEXTFILE="$buildBasicAppLogDir/predix-services-summary.txt"

# ********************************** MAIN **********************************
__validate_num_arguments 2 $# "\"build-basic-app.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$buildBasicAppLogDir"

__append_new_line_log "*** BUILDING AND DEPLOYING FRONT END APPLICATION! ***" "$buildBasicAppLogDir"

# Get the UAA enviorment variables (VCAPS)

if trustedIssuerID=$(cf env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$trustedIssuerID" == "" ]] ; then
    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$buildBasicAppLogDir"
  fi
  __append_new_line_log "trustedIssuerID copied from enviromental variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting the UAA trustedIssuerID..." "$buildBasicAppLogDir"
fi

if uaaURL=$(cf env $1 | grep predix-uaa | grep uri| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$uaaURL" == "" ]] ; then
    __error_exit "The UAA URL was not found for \"$1\"..." "$buildBasicAppLogDir"
  fi
  __append_new_line_log "UAA URL copied from enviromental variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting the UAA URL..." "$buildBasicAppLogDir"
fi

if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
  if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
    __error_exit "The TimeSeries Ingest URI was not found for \"$1\"..." "$buildBasicAppLogDir"
  fi
  __append_new_line_log " TIMESERIES_INGEST_URI copied from enviromental variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$buildBasicAppLogDir"
fi

if TIMESERIES_QUERY_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep time-series | awk -F"\"" '{print $4}'); then
  if [[ "$TIMESERIES_QUERY_URI" == "" ]] ; then
    __error_exit "The TimeSeries Query URI was not found for \"$1\"..." "$buildBasicAppLogDir"
  fi
  __append_new_line_log "TIMESERIES_QUERY_URI copied from enviromental variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$buildBasicAppLogDir"
fi

if TIMESERIES_ZONE_ID=$(cf env $1 | grep -m 1 zone-http-header-value | sed 's/"zone-http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	if [[ "$TIMESERIES_ZONE_ID" == "" ]] ; then
		__error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$buildBasicAppLogDir"
	fi
	__append_new_line_log "TIMESERIES_ZONE_ID copied from enviromental variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$buildBasicAppLogDir"
fi

if ASSET_ZONE_ID=$(cf env $1 | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	if [[ "$ASSET_ZONE_ID" == "" ]] ; then
		__error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$buildBasicAppLogDir"
	fi
	__append_new_line_log "ASSET_ZONE_ID copied from environment variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting ASSET_ZONE_ID..." "$buildBasicAppLogDir"
fi

if assetURI=$(cf env $1 | grep uri| grep asset | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
  if [[ "$assetURI" == "" ]] ; then
    __error_exit "The Asset URI was not found for \"$1\"..." "$buildBasicAppLogDir"
  fi
  __append_new_line_log "assetURI copied from environment variables!" "$buildBasicAppLogDir"
else
	__error_exit "There was an error getting assetURI..." "$buildBasicAppLogDir"
fi

ASSET_TYPE="$(echo -e "${ASSET_TYPE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TYPE_NOSPACE=${ASSET_TYPE// /_}
ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}
MYGENERICS_SECRET=$(echo -ne $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET | base64)

cd "$buildBasicAppRootDir/.."

# Checkout the repo

if [ -d "$GIT_FRONT_END_FILENAME" ]
then
    echo "Deleting existing directory \"$GIT_FRONT_END_FILENAME\"..."
	if rm -rf "$GIT_FRONT_END_FILENAME"; then
		echo "Successfully deleted"
	else
		__error_exit "There was an error deleting the directory: \"$GIT_FRONT_END_FILENAME\"" "$buildBasicAppLogDir"
	fi
fi

if git clone -b "$GIT_BRANCH_RASPBERRY_PI" "$GIT_PREDIX_NODEJS_STARTER_URL" "$GIT_FRONT_END_FILENAME"; then
	cd "$GIT_FRONT_END_FILENAME"
	echo "Successfully cloned \"$GIT_FRONT_END_FILENAME\" and checkout the branch \"$GIT_BRANCH_RASPBERRY_PI\""
else
	__error_exit "There was an error cloning the repo \"$GIT_FRONT_END_FILENAME\". Be sure to have permissions to the repo, or SSH keys created for your account" "$buildBasicAppLogDir"
fi

# Edit the manifest.yml files

#		a) Modify the name of the applications
__find_and_replace "- name: .*" "- name: $FRONT_END_APP_NAME" "manifest.yml" "$buildBasicAppLogDir"

#		b) Add the services to bind to the application
__find_and_replace "\#services:" "services:" "manifest.yml" "$buildBasicAppLogDir"
__find_and_append_new_line "services:" "- $UAA_INSTANCE_NAME" "manifest.yml" "$buildBasicAppLogDir"
__find_and_append_new_line "services:" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$buildBasicAppLogDir"
__find_and_append_new_line "services:" "- $ASSET_INSTANCE_NAME" "manifest.yml" "$buildBasicAppLogDir"

#		c) Set the clientid and base64ClientCredentials
__find_and_replace "\#clientId: .*" "clientId: $UAA_CLIENTID_GENERIC" "manifest.yml" "$buildBasicAppLogDir"
__find_and_replace "\#base64ClientCredential: .*" "base64ClientCredential: $MYGENERICS_SECRET" "manifest.yml" "$buildBasicAppLogDir"

#		d) Set the timeseries and asset information to query the services
__find_and_replace "\#assetMachine: .*" "assetMachine: $ASSET_TYPE_NOSPACE" "manifest.yml" "$buildBasicAppLogDir"
__find_and_replace "\#tagname: .*" "tagname: $ASSET_TAG_NOSPACE" "manifest.yml" "$buildBasicAppLogDir"

# Edit the applications config.json file

__find_and_replace ".*uaaUri\":.*" "    \"uaaURL\": \"$uaaURL\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace ".*timeseries_zone\":.*" "    \"timeseries_zone\": \"$TIMESERIES_ZONE_ID\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace ".*assetZoneId\":.*" "    \"assetZoneId\": \"$ASSET_ZONE_ID\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace ".*tagname\":.*" "    \"tagname\": \"$ASSET_TAG_NOSPACE\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace ".*clientId\":.*" "    \"clientId\": \"$UAA_CLIENTID_GENERIC\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace ".*base64ClientCredential\":.*" "    \"base64ClientCredential\": \"$MYGENERICS_SECRET\"," "config.json" "$buildBasicAppLogDir"

# Add the required Timeseries and Asset URIs
#__find_and_replace ".*\"windServiceUrl\":.*" "    timeseriesURL: $TIMESERIES_QUERY_URI," "config.json" "$buildBasicAppLogDir"
#__find_and_replace ".*\"windServiceUrl\":.*" "    assetURL: $assetURI/$ASSET_TYPE_NOSPACE," "config.json" "$buildBasicAppLogDir"
__find_and_replace "    timeseriesURL: $TIMESERIES_QUERY_URI," "    \"timeseriesURL\": \"$TIMESERIES_QUERY_URI\"," "config.json" "$buildBasicAppLogDir"
__find_and_replace "    assetURL: $assetURI/$ASSET_TYPE_NOSPACE," "    \"assetURL\": \"$assetURI/$ASSET_TYPE_NOSPACE\"," "config.json" "$buildBasicAppLogDir"

# Edit the /public/secure.html file
cd public
__find_and_replace "<\!--" "" "secure.html" "$buildBasicAppLogDir"
__find_and_replace "-->" "" "secure.html" "$buildBasicAppLogDir"
cd ..

# Build the application

#echo "Building the application \"$FRONT_END_APP_NAME\"..."
#if npm install; then
#	echo "Succesfully built!"
#else
#	__error_exit "There was an error building the app with: \"npm install\"" "$buildBasicAppLogDir"
#fi

# Push the application

echo "Pushing the application \"$FRONT_END_APP_NAME\" to Cloud Foundry..."
if cf push; then
	echo "Succesfully pushed the application!"
else
	echo "Failed to push application. Retrying..."
	if cf push; then
		echo "Succesfully pushed the application!"
	else
		__error_exit "There was an error pushing using: \"cf push\"" "$buildBasicAppLogDir"
	fi
fi

# Generate the build-basic-app-summary.txt

cd "$buildBasicAppRootDir/.."
if [ -f "$BUILD_APP_TEXTFILE" ]
then
    echo "Deleting existing summary file \"$BUILD_APP_TEXTFILE\"..."
		if rm -f "$BUILD_APP_TEXTFILE"; then
			echo "Successfully deleted"
		else
			__error_exit "There was an error deleting the file: \"$BUILD_APP_TEXTFILE\"" "$buildBasicAppLogDir"
		fi
fi

if cf start $FRONT_END_APP_NAME; then
	printout="$FRONT_END_APP_NAME started!"
	__append_new_line_log "$printout" "$buildBasicAppLogDir" 1>&2
else
	__error_exit "Couldn't start $FRONT_END_APP_NAME" "$buildBasicAppLogDir"
fi

if [ "$2" == "0" ]
then
	__append_new_line_log "Predix Services Configurations found in file: \"$PREDIX_SERVICES_TEXTFILE\"" "$buildBasicAppLogDir"
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
