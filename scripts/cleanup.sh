#!/bin/bash
set -e
# Cleanup Script
# Authors: GE SDLP 2015
#
cleanUpPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cleanUpLogDirectory="$cleanUpPath/../log"

source "$cleanUpPath/variables.sh"
source "$cleanUpPath/files_helper_funcs.sh"
source "$cleanUpPath/error_handling_funcs.sh"

if ! [ -d "$cleanUpLogDirectory" ]; then
	mkdir "$cleanUpLogDirectory"
	chmod 744 "$cleanUpLogDirectory"
fi

touch "$cleanUpLogDirectory/quickstartlog.log"

# Unbind any possible services
# *****************************
__append_new_line_log "######## CLEAN UP IN PROGRESS ########" "$cleanUpLogDirectory"

if cf us $TEMP_APP $TIMESERIES_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$TIMESERIES_INSTANCE_NAME\" from \"$TEMP_APP\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $TEMP_APP might not exist" "$cleanUpLogDirectory"
fi

if cf us $FRONT_END_APP_NAME $TIMESERIES_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$TIMESERIES_INSTANCE_NAME\" from \"$FRONT_END_APP_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $FRONT_END_APP_NAME might not exist" "$cleanUpLogDirectory"
fi

if cf us $TEMP_APP $ASSET_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$ASSET_INSTANCE_NAME\" from \"$TEMP_APP\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $TEMP_APP might not exist" "$cleanUpLogDirectory"
fi

if cf us $FRONT_END_APP_NAME $ASSET_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$ASSET_INSTANCE_NAME\" from \"$FRONT_END_APP_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $FRONT_END_APP_NAME might not exist" "$cleanUpLogDirectory"
fi

if cf us $TEMP_APP $UAA_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$UAA_INSTANCE_NAME\" from \"$TEMP_APP\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $TEMP_APP might not exist" "$cleanUpLogDirectory"
fi

if cf us $FRONT_END_APP_NAME $UAA_INSTANCE_NAME; then
  __append_new_line_log "Successfully unbinded \"$UAA_INSTANCE_NAME\" from \"$FRONT_END_APP_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete. $FRONT_END_APP_NAME might not exist" "$cleanUpLogDirectory"
fi

# Delete the applications
# *****************************

if cf d $FRONT_END_APP_NAME -f -r; then
  __append_new_line_log "Successfully deleted \"$FRONT_END_APP_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete \"$FRONT_END_APP_NAME\". Retrying..." "$cleanUpLogDirectory"
  if cf d $FRONT_END_APP_NAME -f -r; then
    __append_new_line_log "Successfully deleted \"$FRONT_END_APP_NAME\"" "$cleanUpLogDirectory"
  else
    __append_new_line_log "Failed to delete \"$FRONT_END_APP_NAME\". Giving up." "$cleanUpLogDirectory"
  fi
fi

if cf d $TEMP_APP -f -r; then
  __append_new_line_log "Successfully deleted \"$TEMP_APP\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete \"$TEMP_APP\". Retrying..." "$cleanUpLogDirectory"
  if cf d $TEMP_APP -f -r; then
    __append_new_line_log "Successfully deleted \"$TEMP_APP\"" "$cleanUpLogDirectory"
  else
    __append_new_line_log "Failed to delete \"$TEMP_APP\". Giving up." "$cleanUpLogDirectory"
  fi
fi

# Delete the services
# *****************************
if cf ds $UAA_INSTANCE_NAME -f; then
  __append_new_line_log "Successfully deleted \"$UAA_INSTANCE_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete \"$UAA_INSTANCE_NAME\". Retrying..." "$cleanUpLogDirectory"
  if cf d $UAA_INSTANCE_NAME -f; then
    __append_new_line_log "Successfully deleted \"$UAA_INSTANCE_NAME\"" "$cleanUpLogDirectory"
  else
    __append_new_line_log "Failed to delete \"$UAA_INSTANCE_NAME\". Giving up." "$cleanUpLogDirectory"
  fi
fi

if cf ds $TIMESERIES_INSTANCE_NAME -f; then
  __append_new_line_log "Successfully deleted \"$TIMESERIES_INSTANCE_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete \"$TIMESERIES_INSTANCE_NAME\". Retrying..." "$cleanUpLogDirectory"
  if cf d $TIMESERIES_INSTANCE_NAME -f; then
    __append_new_line_log "Successfully deleted \"$TIMESERIES_INSTANCE_NAME\"" "$cleanUpLogDirectory"
  else
    __append_new_line_log "Failed to delete \"$TIMESERIES_INSTANCE_NAME\". Giving up." "$cleanUpLogDirectory"
  fi
fi

if cf ds $ASSET_INSTANCE_NAME -f; then
  __append_new_line_log "Successfully deleted \"$ASSET_INSTANCE_NAME\"" "$cleanUpLogDirectory"
else
  __append_new_line_log "Failed to delete \"$ASSET_INSTANCE_NAME\". Retrying..." "$cleanUpLogDirectory"
  if cf d $ASSET_INSTANCE_NAME -f; then
    __append_new_line_log "Successfully deleted \"$ASSET_INSTANCE_NAME\"" "$cleanUpLogDirectory"
  else
    __append_new_line_log "Failed to delete \"$ASSET_INSTANCE_NAME\". Giving up." "$cleanUpLogDirectory"
  fi
fi

__append_new_line_log "######## CLEAN UP COMPLETE ########" "$cleanUpLogDirectory"
