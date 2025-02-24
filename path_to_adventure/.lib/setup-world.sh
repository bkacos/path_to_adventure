#!/bin/bash

###############################################################################
##                                                                           ##
##                           SETUP FUNCTIONS                                 ##
##                                                                           ##
###############################################################################
function setup_all {
    __pta_load_all "$SETUP_DIR"
}


###############################################################################
##                                                                           ##
##                          TEARDOWN FUNCTIONS                               ##
##                                                                           ##
###############################################################################
function cleanup {
  # Fix permissions on LIBRARY
  local CASTLE=$WORLD/castle
  local LIBRARY=$CASTLE/library
  sudo chmod u+rwx $LIBRARY
  # Remove link from root of directory
  [[ -L /World ]] && sudo rm /World
}
trap cleanup EXIT HUP QUIT TERM