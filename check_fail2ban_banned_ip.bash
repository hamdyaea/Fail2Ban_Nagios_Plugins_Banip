#!/bin/bash
########################################################################################
# Nagios plugins is developed by : Hamdy Abou El Anein hamdy.aea@protonmail.com        #
# It check if fail2ban have an active ip banned and if yes it show the ip              #
# In the script I use warning state only critical                                      #
# Version 1.1                                                                          #
########################################################################################
#
# Variables declaration
result=$(fail2ban-client status sshd | grep "Currently banned:" | cut -d : -f 2)
bannedip=$(fail2ban-client status sshd | grep "Banned IP list:" | cut -d : -f 2)
# Function OK
function f_ok {
    echo "OK: "${1}
    exit 0
}
# Function critical
function f_cri {
    echo "CRITICAL: "${1}
    exit 2
}
 # Function warning                                                                                                                  
function f_war {                                                                                                                     
     echo "WARNING:"${1}                                                                                                            
     exit 1         
}     
# Function unknown
function f_unk {
    echo "UNKNOWN: "${1}
    exit 3
}
# Function fail2banipbanned
function fail2banipbanned {
# Check if an ip adress is banned or no.
    if [ ${result} = 1 ]; then
        f_cri "The ip $bannedip is banned"
    fi
    if [ ${result} -gt 1 ]; then
        f_cri "The ip $bannedip are banned"
    fi
    if [[ ${result} =~ ^-?[0-9]+$ ]] ; then
        f_unk "The list of banned ip is unknown"
    else
        f_ok "No ip adress is banned"
    fi
}
fail2banipbanned
