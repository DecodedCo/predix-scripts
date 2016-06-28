#!/bin/bash
set -e
predixServicesSetupRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
predixServicesLogDir="$predixServicesSetupRootDir/../log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to instantiate the following Predix
# services: Timeseries, Asset, and UAA. The script will also configure each service with
# the necessary authorities and scopes, create a UAA user, create UAA client id, and
# post sample data to the Asset service
#

source "$predixServicesSetupRootDir/variables.sh"
source "$predixServicesSetupRootDir/error_handling_funcs.sh"
source "$predixServicesSetupRootDir/files_helper_funcs.sh"
source "$predixServicesSetupRootDir/curl_helper_funcs.sh"

PREDIX_SERVICES_TEXTFILE="$predixServicesLogDir/predix-services-summary.txt"

if ! [ -d "$predixServicesLogDir" ]; then
	mkdir "$predixServicesLogDir"
	chmod 744 "$predixServicesLogDir"
fi
touch "$predixServicesLogDir/quickstartlog.log"

# Trap ctrlc and exit if encountered
trap "trap_ctrlc" 2
__append_new_line_log "*** CONFIGURING, CREATING PREDIX SERVICES! ***" "$predixServicesLogDir"

__validate_num_arguments 1 $# "\"predix-services-setup.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$predixServicesLogDir"

# Push a test app to get VCAP information for the Predix Services

echo -e "Pushing \"$1\" to initially create Predix Microservices ...\n"
cd "$predixServicesSetupRootDir/../testapp"

if cf push $1 --no-start --random-route; then
	__append_new_line_log "App \"$1\" successfully pushed to CloudFoundry!" "$predixServicesLogDir"
else
	__error_exit "There was an error pushing the app \"$1\" to CloudFoundry..." "$predixServicesLogDir"
fi

# Create instance of Predix UAA Service

if cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"; then
	__append_new_line_log "UAA Service instance successfully created!" "$predixServicesLogDir"
else
	__append_new_line_log "Couldn't create UAA service. Retrying..." "$predixServicesLogDir"
	if cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"; then
		__append_new_line_log "UAA Service instance successfully created!" "$predixServicesLogDir"
	else
		__error_exit "Couldn't create UAA service instance..." "$predixServicesLogDir"
	fi
fi

# Bind Temp App to UAA instance

if cf bs $1 $UAA_INSTANCE_NAME; then
	__append_new_line_log "UAA instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
else
	if cf bs $1 $UAA_INSTANCE_NAME; then
    __append_new_line_log "UAA instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
  else
    __error_exit "There was an error binding the UAA service instance to the app \"$1\"!" "$predixServicesLogDir"
  fi
fi

# Get the UAA enviorment variables (VCAPS)

if trustedIssuerID=$(cf env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$trustedIssuerID" == "" ]] ; then
    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$predixServicesLogDir"
  fi
  __append_new_line_log "trustedIssuerID copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting the UAA trustedIssuerID..." "$predixServicesLogDir"
fi

if uaaURL=$(cf env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$uaaURL" == "" ]] ; then
    __error_exit "The UAA URL was not found for \"$1\"..." "$predixServicesLogDir"
  fi
  __append_new_line_log "UAA URL copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting the UAA URL..." "$predixServicesLogDir"
fi


# Create instance of Predix TimeSeries Service

if cf cs $TIMESERIES_SERVICE_NAME $TIMESERIES_SERVICE_PLAN $TIMESERIES_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "Predix TimeSeries Service instance successfully created!" "$predixServicesLogDir"
else
	if cf cs $TIMESERIES_SERVICE_NAME $TIMESERIES_SERVICE_PLAN $TIMESERIES_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "Predix TimeSeries Service instance successfully created!" "$predixServicesLogDir"
  else
    __error_exit "Couldn't create Predix TimeSeries service instance..." "$predixServicesLogDir"
  fi
fi

# Bind Temp App to TimeSeries Instance

if cf bs $1 $TIMESERIES_INSTANCE_NAME; then
	__append_new_line_log "Predix TimeSeries instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
else
	if cf bs $1 $TIMESERIES_INSTANCE_NAME; then
    __append_new_line_log "Predix TimeSeries instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
  else
    __error_exit "There was an error binding the Predix TimeSeries service instance to the app \"$1\"!" "$predixServicesLogDir"
  fi
fi


# Get the Zone ID and URIs from the enviroment variables (for use when querying and ingesting data)
if TIMESERIES_ZONE_HEADER_NAME=$(cf env $TEMP_APP | grep -m 100 zone-http-header-name | sed 's/"zone-http-header-name": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "TIMESERIES_ZONE_HEADER_NAME : $TIMESERIES_ZONE_HEADER_NAME"
	__append_new_line_log "TIMESERIES_ZONE_HEADER_NAME copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_HEADER_NAME..." "$predixServicesLogDir"
fi

if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
	echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
	__append_new_line_log "TIMESERIES_ZONE_ID copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$predixServicesLogDir"
fi

if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
	echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
	__append_new_line_log " TIMESERIES_INGEST_URI copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$predixServicesLogDir"
fi

if TIMESERIES_QUERY_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep time-series | awk -F"\"" '{print $4}'); then
	__append_new_line_log "TIMESERIES_QUERY_URI copied from enviromental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$predixServicesLogDir"
fi

# Create instance of Predix Asset Service
echo -e "cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}""
if cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "Predix Asset Service instance successfully created!" "$predixServicesLogDir"
else
	echo -e "cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}""
	if cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "Predix Asset Service instance successfully created!" "$predixServicesLogDir"
  else
    __error_exit "Couldn't create Predix Asset service instance..." "$predixServicesLogDir"
  fi
fi

# Bind Temp App to Asset Instance

if cf bs $1 $ASSET_INSTANCE_NAME; then
	__append_new_line_log "Predix Asset instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
else
	if cf bs $1 $ASSET_INSTANCE_NAME; then
		__append_new_line_log "Predix Asset instance successfully binded to app \"$1\"!" "$predixServicesLogDir"
	else
		__error_exit "There was an error binding the Predix Asset service instance to the app \"$1\"!" "$predixServicesLogDir"
	fi
fi

# Get the Zone ID from the enviroment variables (for use when querying Asset data)
if ASSET_ZONE_ID=$(cf env $1 | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	if [[ "$ASSET_ZONE_ID" == "" ]] ; then
		__error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$predixServicesLogDir"
	fi
	__append_new_line_log "ASSET_ZONE_ID copied from environment variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting ASSET_ZONE_ID..." "$predixServicesLogDir"
fi

# Create client ID for generic use by applications - including timeseries and asset scope

__createUaaClient "$uaaURL" "$TIMESERIES_ZONE_ID" "$ASSET_SERVICE_NAME" "$ASSET_ZONE_ID"

# Create a new user account

__addUaaUser "$uaaURL"

echo "Add user complete"
# Get the Asset URI and generate Asset body from the enviroment variables (for use when querying and posting data)
echo -e "cf env $TEMP_APP | grep -m 100 uri | grep asset | awk -F\"\\\"\" '{print \$4}'"
if assetURI=$(cf env $TEMP_APP | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
	__append_new_line_log "assetURI copied from environment variables! $assetURI" "$predixServicesLogDir"
else
	__error_exit "There was an error getting assetURI..." "$predixServicesLogDir"
fi

# Clean input for machine type and tag, no spaces allowed

ASSET_TYPE="$(echo -e "${ASSET_TYPE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TYPE_NOSPACE=${ASSET_TYPE// /_}
ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}
if assetPostBody=$(printf "[{\"uri\": \"%s\", \"tag\": \"%s\", \"description\": \"%s\"}]%s" "/$ASSET_TYPE_NOSPACE/$ASSET_TAG_NOSPACE" "$ASSET_TAG_NOSPACE" "$ASSET_DESCRIPTION"); then
 	__append_new_line_log "assetPostBody updated with tag: $ACTUAL_TAGNAME_INSTANCE" "$predixServicesLogDir"

else
	__error_exit "There was an error getting assetPostBody..." "$predixServicesLogDir"
fi
echo "ASSET Post Body : $assetPostBody"
echo "Asset URL : $assetURI"
createAsset "$uaaURL" "$assetURI" "$ASSET_ZONE_ID" "$assetPostBody"


cd "$predixServicesSetupRootDir"

__append_new_line_log "Predix Services Configurations found in file: \"$PREDIX_SERVICES_TEXTFILE\"" "$predixServicesLogDir"

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

__append_new_line_log "*** SUCCESSFULLY CREATED PREDIX SERVICES! ***" "$predixServicesLogDir"
