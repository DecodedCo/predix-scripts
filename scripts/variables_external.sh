# Predix Cloud Foundry Credentials
# Keep all values inside double quotes

#########################################################
# Mandatory User configurations that need to be updated
#########################################################

############## Proxy Configurations #############

# Proxy settings in format proxy_host:proxy_port
# Leave as is if no proxy
ALL_PROXY=":8080"

############## Front End Configurations #############
# Name for your Frone End Application
FRONT_END_APP_NAME="$GLOBAL_APPENDER-nodejs-starter"

############### UAA Configurations ###############

# The username of the new user to authenticate with the application
UAA_USER_NAME="predix_user_1"

# The email address of username above
UAA_USER_EMAIL="predix_user_1@ge.com"

# The password of the user above
UAA_USER_PASSWORD="predix_user_1"

# The secret of the Admin client ID (Administrator Credentails)
UAA_ADMIN_SECRET="Pr3dix2016"

# The generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_GENERIC="app_client_id"

# The generic client ID password
UAA_CLIENTID_GENERIC_SECRET="secret"

############# Predix Asset Configurations #############

# Name of the "Asset" that is recorded to Predix Asset
ASSET_TYPE="asset"

# Name of the tag (Asset name ex: Wind Turbine) you want to ingest to timeseries with. NO SPACES
# To create multiple tags separate each tag with a single comma (,)
ASSET_TAG="device1"

#Description of the Machine that is recorded to Predix Asset
ASSET_DESCRIPTION="device1"

###############################
# Optional configurations
###############################

# GITHUB repo to pull predix-nodejs-starter
# Use this one for the non-internal GE repo = https://github.build.ge.com/adoption/predix-nodejs-starter
GIT_PREDIX_NODEJS_STARTER_URL="https://github.com/PredixDev/predix-nodejs-starter.git"

# Name for the temp_app application
TEMP_APP="simple-app"

############### UAA Configurations ###############

# The name of the UAA service you are binding to - default already set
UAA_SERVICE_NAME="predix-uaa"

# Name of the UAA plan (eg: Free) - default already set
UAA_PLAN="Tiered"

# Name of your UAA instance - default already set
UAA_INSTANCE_NAME="$GLOBAL_APPENDER-uaa-service"

############# Predix TimeSeries Configurations ##############

#The name of the TimeSeries service you are binding to - default already set
TIMESERIES_SERVICE_NAME="predix-timeseries"

#Name of the TimeSeries plan (eg: Free) - default already set
TIMESERIES_SERVICE_PLAN="Bronze"

#Name of your TimeSeries instance - default already set
TIMESERIES_INSTANCE_NAME="$GLOBAL_APPENDER-timeseries"

############# Predix Asset Configurations ##############

#The name of the Asset service you are binding to - default already set
ASSET_SERVICE_NAME="predix-asset"

#Name of the Asset plan (eg: Free) - default already set
ASSET_SERVICE_PLAN="Tiered"

#Name of your Asset instance - default already set
ASSET_INSTANCE_NAME="$GLOBAL_APPENDER-asset-service"

#Predix Enable modbus configuration using Modbus simulator
ENABLE_MODBUS_SIMULATOR="true"

#Device Specific Connection info
DEVICE_SPECIFIC_GITHUB_REPO_NAME="predix-machine-template-adapter-edison"
MACHINE_TEMPLATES_GITHUB_REPO_URL="https://github.com/PredixDev/predix-machine-templates.git"


