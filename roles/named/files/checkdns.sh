#!/bin/bash

# Usage
# bash /usr/local/bin/checkdns.sh internal/public

JSONCreator(){
    if [ -z "$JSON" ]; then
        JSON=$(jq -n '{}')
    fi

    if [[ "$1" == "add-entry" ]]; then
        JSON=$(echo "$JSON" | jq --arg value "$3" ".$2 = \$value")
    elif [[ "$1" == "add-to-list" ]]; then
        JSON=$(echo "$JSON" | jq --arg value "$3" ".$2 += [\$value]")
    elif [[ "$1" == "create-empty-list" ]]; then
        JSON=$(echo "$JSON" | jq ".$2 = []")
    fi
}


Digger(){
    /usr/bin/dig +timeout=1 +tries=1 $1 2> /dev/null
}


CheckForGlobalConfigurationErrors(){
    if ! named-checkconf &> /dev/null; then
        JSONCreator "add-entry" "CheckForGlobalConfigurationErrors" "FAILURE"
        echo "$JSON"
        exit 1
    else
        JSONCreator "add-entry" "CheckForGlobalConfigurationErrors" "SUCCESS"
    fi
}


CheckForNamedConfConfigurationErrors(){
    if ! named-checkconf -z /etc/named.conf &> /dev/null; then
        JSONCreator "add-entry" "CheckForNamedConfConfigurationErrors" "FAILURE"
        echo "$JSON"
        exit 1
    else
        JSONCreator "add-entry" "CheckForNamedConfConfigurationErrors" "SUCCESS"
    fi
}


CheckForZoneConfigurationErrors(){
    for FILE in /var/named/data/*.zone; do
        if ! (named-checkzone localhost $FILE) > /dev/null; then
	        JSONCreator "add-entry" "CheckForZoneConfigurationErrors" "FAILURE FILE:$FILE"
            echo "$JSON"
            exit 1
        else
            JSONCreator "add-entry" "CheckForZoneConfigurationErrors" "SUCCESS"	
        fi
    done
}


CheckForNamedConfConfigurationWarning(){
    JSONCreator "create-empty-list" "CheckForNamedConfConfigurationWarning"
    local WARNING_LIST="$(/usr/sbin/named-checkconf -z /etc/named.conf | grep -v 'loaded serial')"
    while IFS= read -r ITEM; do
        local FILE=$(echo "$ITEM" | awk -F ': ' '{print $1}')
        local WARNING=$(echo "$ITEM" | awk -F ': ' '{print substr($0, index($0,$2))}')
        if [ -n "$FILE" ]; then
            JSONCreator "add-to-list" "CheckForNamedConfConfigurationWarning" "FILE:${FILE} WARNING:${WARNING}"
        fi
    done <<< "$WARNING_LIST"
}


ZonesQueryForwardersErrors(){
    JSONCreator "create-empty-list" "ZonesQueryForwardersErrors"
    FORWARDERS_ZONES=$(awk '/[forwarders,zones]/{
if(match($0, /zone "(.*)".*IN.*{/, a)) {
  zone=a[1];
}
if(zone!="" && match($0, /forwarders { (.*) }/, a)) {
  gsub(/ /, "", a[1]);
  n = split(a[1], forwarders, ";")
  for (i = 0; ++i < n;)
    print zone "," forwarders[i] ";"
  zone="";
  delete forwarders;
}
}' /etc/named/*forward.zones)

    while read -r LINE; do
        IFS=',' read -r ZONE FORWARDER <<< "$(echo $LINE | tr -d ';')"
        DIG_RESULT=$(Digger "+short $ZONE soa @$FORWARDER")
        if test $? -ne 0; then
            JSONCreator "add-to-list" "ZonesQueryForwardersErrors" "FAILED_QUERY ZONE:$ZONE FORWARDER:$FORWARDER"
        fi
        if ! test $(echo $DIG_RESULT | wc -c) -gt 1; then
            JSONCreator "add-to-list" "ZonesQueryForwardersErrors" "EMPTY_ANSWER ZONE:$ZONE FORWARDER:$FORWARDER"
        fi
    done <<< "$FORWARDERS_ZONES"
}


CheckForSlavesInNamed(){
    JSONCreator "create-empty-list" "CheckForSlavesInNamed"
    for FILE in $(ls /var/named/slaves/); do
        if ! grep -q $FILE /etc/named/*; then
	        JSONCreator "add-to-list" "CheckForSlavesInNamed" "SLAVE_FILE_NOT_USED FILE:$FILE"
            EXIT_CODE=1
        fi
    done
}


CheckForZonesNotInNamed(){
    JSONCreator "create-empty-list" "CheckForZonesNotInNamed"
    for FILE in $(ls /etc/named/*.zones); do
        if ! grep -q $FILE /etc/named.conf; then
	        JSONCreator "add-to-list" "CheckForZonesNotInNamed" "FILE_NOT_IN_NAMED_CONF FILE:$FILE"
            EXIT_CODE=1
        fi
    done
}


CheckClientsZonesAreInView(){
    JSONCreator "create-empty-list" "CheckClientsZonesAreInView"
    FILE="/etc/named/all-clients.forward-and-master.zones"
    for VIEW in $(awk '/^view/{ if(match($0, /view \"(ebrc-trusted-.*)\"/, m)) print m[1]}' /etc/named/ebrc-trusted.conf); do
	    if ! sed -n "/^view \"$VIEW\" {/,/^}/{p}" /etc/named/ebrc-trusted.conf | grep -q $FILE; then
            JSONCreator "add-to-list" "CheckClientsZonesAreInView" "FILE_SHOULD_BE_INCLUDED FILE:$FILE VIEW:$VIEW"
            EXIT_CODE=1
        fi
    done
    for VIEW in $(awk '/^view/{ if(match($0, /view \"(ebrc-untrusted-.*)\"/, m)) print m[1]}' /etc/named/ebrc-trusted.conf); do
       if sed -n "/^view \"$VIEW\" {/,/^}/{p}" /etc/named/ebrc-trusted.conf | grep -q $FILE; then
	       JSONCreator "add-to-list" "CheckClientsZonesAreInView" "FILE_SHOULD_NOT_BE_INCLUDED FILE:$FILE VIEW:$VIEW"
           EXIT_CODE=1
       fi
    done
}


CheckClientsZonesAreIncludedInAllClients(){
    JSONCreator "create-empty-list" "CheckClientsZonesAreIncludedInAllClients"
    for FILE in $(ls /etc/named/ | egrep "[[:digit:]][[:digit:]][[:digit:]][[:digit:]]\.(forward|master|slave)\.zones"); do
        if ! cat /etc/named/all-clients.forward-and-master.zones | grep -q $FILE; then
	        JSONCreator "add-to-list" "CheckClientsZonesAreIncludedInAllClients" "FILE_SHOULD_BE_INCLUDED FILE:$FILE ZONE:/etc/named/all-clients.forward-and-master.zones"
            EXIT_CODE=1
        fi
    done
}


CheckClientsZonesIsntIncludedInView(){
    JSONCreator "create-empty-list" "CheckClientsZonesIsntIncludedInView"
    for FILE in $(ls /etc/named/ | egrep "[[:digit:]][[:digit:]][[:digit:]][[:digit:]]\.(forward|master|slave)\.zones"); do
        if sed -n "/^view \"ebrc-vdomroot\" {/,/^}/{p}" /etc/named/ebrc-trusted.conf | grep -q $FILE; then
	        JSONCreator "add-to-list" "CheckClientsZonesIsntIncludedInView" "FILE_SHOULD_NOT_BE_INCLUDED FILE:$FILE VIEW:[ebrc-vdomroot]"
            EXIT_CODE=1
        fi
    done
}


CheckForUnusedACLs(){
    JSONCreator "create-empty-list" "CheckForUnusedACLs"
    for ACL in $(grep -s "^acl" /etc/named/ACLs.conf | cut -d'"' -f2 | sort | uniq); do
        grep -q "match-[clients|destinations].*{.*$ACL;.*}" /etc/named/ebrc-trusted.conf /etc/named/managed-customers.conf /etc/named/managed-7938.conf
        if [ $? -ne 0 ]; then
            JSONCreator "add-to-list" "CheckForUnusedACLs" "ACL_UNUSED ACL:$ACL"
            EXIT_CODE=1
        fi
    done
}


CheckForACLNetworkRoute(){
    JSONCreator "create-empty-list" "CheckForACLNetworkRoute"
    if test $(ip route show table main | grep ^default | wc -l) -gt 0; then
	    JSONCreator "add-to-list" "CheckForACLNetworkRoute" "SKIPPED_DEFAULT_GW_IS_CONFIGURED"
    else
        for NETWORK in $(grepcidr 0.0.0.0/0 /etc/named/ACLs.conf | awk '{print $1}' | sed 's/;$//' | grep -E -v '^//' | grep -E '\/[0-9]+'); do
            if [ $((ip route list table main scope global ; ip route list table main scope link) | grepcidr -x $NETWORK -c) -eq 0 ]; then
                JSONCreator "add-to-list" "CheckForACLNetworkRoute" "NO_ROUTE_TO_NET NETWORK:$NETWORK"
                EXIT_CODE=1
            fi
        done
    fi
}


CheckClientsReverseZones(){
    JSONCreator "create-empty-list" "CheckClientsReverseZones"
    for REVERSE_ZONE in $(awk -F'"' '/^zone/ {print $2}' /etc/named/[[:digit:]][[:digit:]][[:digit:]][[:digit:]]\.reverse.zones | sort | uniq); do
        egrep -q '^zone "'$REVERSE_ZONE /etc/named/master.zones
        if [ $? -ne 0 ]; then
            JSONCreator "add-to-list" "CheckClientsReverseZones" "ZONE_SHOULD_BE_IN_MASTER_ZONES REVERSE_ZONE:$REVERSE_ZONE"
            EXIT_CODE=1
        fi
    done
}


CheckClientsZones(){
    JSONCreator "create-empty-list" "CheckClientsZones"
    DATA_FILES=$(find /var/named/data)
    for ZONE_FILE in $(awk -F'"' '/^\s+file/ {print $2}' /etc/named/[[:digit:]][[:digit:]][[:digit:]][[:digit:]].{forward,master,reverse}.zones | sort | uniq); do
        echo $DATA_FILES | egrep -q $ZONE_FILE
        if [ $? -ne 0 ]; then
            JSONCreator "add-to-list" "CheckClientsZones" "ZONE_SHOULD_BE_IN_DATA ZONE_FILE:$ZONE_FILE"
            EXIT_CODE=1
        fi
    done
}


Main(){
    EXIT_CODE=0

    if [ "$1" == "internal" ]; then
        # Declare vars
        declare -A DNS_SERVERS=( ["sv-2000lvp272"]="10.3.2.21" ["sv-2000lvp273"]="10.3.2.22" )

	    # Check for warnings
        CheckForNamedConfConfigurationWarning

        # Tests to verify configuration validity (exit 1 if failed, skip the rest of the execution)
        CheckForGlobalConfigurationErrors
	    CheckForNamedConfConfigurationErrors
        CheckForZoneConfigurationErrors

        # Additional tests that indicate content to decomm
        ZonesQueryForwardersErrors

        # These tests will return a script failure on error
        CheckForSlavesInNamed
        CheckClientsZonesAreInView
        CheckClientsZonesAreIncludedInAllClients
        CheckClientsZonesIsntIncludedInView
        CheckForUnusedACLs
        CheckForACLNetworkRoute
        CheckClientsReverseZones
        CheckClientsZones
    elif [ "$1" == "public" ]; then
        # Declare vars
        declare -A DNS_SERVERS=( ["sv-2000lvp274"]="176.65.72.101" ["sv-2000lvp275"]="176.65.72.105" )
	
	    # Check for warnings
	    CheckForNamedConfConfigurationWarning

        # Tests to verify configuration validity (exit 1 if failed, skip the rest of the execution)
        CheckForGlobalConfigurationErrors
	    CheckForNamedConfConfigurationErrors

        # These tests will return a script failure on error
        CheckForSlavesInNamed
        CheckForZonesNotInNamed
    fi

    # Output result
    echo "$JSON"

    # Clean exit
    exit $EXIT_CODE
}


Main $1

exit 0

