#!/bin/bash 
# Author: Felipe Molina (https://twitter.com/felmoltor,https://github.com/felmoltor)
# Date: 12/2015
# License: GPLv3
# Summary:  This script tries to discover services provided in the target domain
#           by just asking politely to the open resolvers found in Internet.
#           The records being requested are SRV record types. 
#           This technique allow us to detect services running in ports without 
#           any need to even run a port scan against any server of the targeted domain
#           or domains. 
#           See more information about the SRV RR in the RFC:
#           https://www.ietf.org/rfc/rfc2782.txt 

DNSFILE="openresolvers/spain.txt"
DNSSERVERS=()
SRVFILE="services/extendedsrv.txt"
VERSION="v1.0"

###### FUNCTIONS ######


function lightblue(){ 
    echo $(tput setaf 6)$1$(tput sgr0) 
}
function cyan(){ 
    echo $(tput setaf 5)$1$(tput sgr0) 
}
function blue(){ 
    echo $(tput setaf 4)$1$(tput sgr0) 
}
function bluenl(){ 
    echo -n $(tput setaf 4)$1$(tput sgr0) 
}
function greennl(){ 
    echo -n $(tput setaf 2)$1$(tput sgr0) 
}
function rednl(){ 
    echo -n $(tput setaf 1)$1$(tput sgr0) 
}
function green(){ 
    echo $(tput setaf 2)$1$(tput sgr0) 
}
function red(){ 
    echo $(tput setaf 1)$1$(tput sgr0) 
}
function yellow(){ 
    echo $(tput setaf 3)$1$(tput sgr0) 
}

function printUsage(){
    echo "Usage: $0 <domains file | domain name> <output csv file> [<extended | small>]"
}

function showBanner(){
    lightblue "========================"
    lightblue "==  DNSProspect $VERSION  =="
    lightblue "== Author: @felmoltor =="
    lightblue "========================"
    lightblue ""
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function getRandomDNS(){
    local rnd
    local dnssize

    dnssize=${#DNSSERVERS[@]}
    rnd=$(( ( RANDOM % $dnssize ) ))
    
    echo ${DNSSERVERS[$rnd]}
}

function initializeDNSSERVERS(){
    if [[ -f $DNSFILE ]]
    then
        for dnsline in `cat $DNSFILE`
        do
            if valid_ip $dnsline
            then
                DNSSERVERS[${#DNSSERVERS[@]}]=$dnsline
            fi
        done
    fi
}

function is_valid_domain(){
    # TODO: Bug, not working well
    local domain=$1
    local stat=0
    
    if [[ $(host $domain | grep "not found: 3(NXDOMAIN)" | wc -l) -gt 0 ]]
    then
        stat=1
    fi 
    return $stat
}

function prospectDomain(){
    local domain

    domain=$1

    echo ""
    # printf "%0.s=" {1..$((${#domain} + 12))}
    cyan "===== $domain =====" 
    # printf "%0.s=" {1..$((${#domain} + 12))}
    OFS=$IFS
    IFS=$'\n'
    for srvline in `cat $SRVFILE`
    do
        service=$(echo $srvline|cut -d, -f1)
        srvrecord=$(echo $srvline|cut -d, -f2)
        proto=$(echo $srvline|cut -d, -f3)
        
        answer=$(dig @$(getRandomDNS) $srvrecord.$domain srv +short)
        servers=()
        if [[ $(echo -n "$answer" | wc -c) -gt 0 ]]
        then
            OFS=$IFS
            IFS=$'\n'
            for line in `echo "$answer"`
            do
                # If this line is a SRV answer record instead a CNAME with format: number(priority) number(weith) number(port) servername
                if [[ "$line" =~ ^[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+.+$ ]]
                then
                    # Add the server to the array of servers
                    servers[${#servers[@]}]=$(echo "$line" | awk '{print $4":"$3}')
                fi
            done
            IFS=$OFS
        fi

        nservers=${#servers[@]}
        echo ""
        echo -n " $service: "
        if [[ $nservers -gt 0 ]]
        then
            greennl "$nservers"
        else
            rednl "$nservers"
        fi
        echo " servers listening"
        if [[ $nservers -gt 0 ]]
        then
            for srvserver in ${servers[@]}
            do
                local server
                local port

                server=$(echo $srvserver | cut -d':' -f1)
                port=$(echo $srvserver | cut -d':' -f2)
                echo -n " - "
                bluenl "$server"
                echo " listening on port $port/$proto"
                # Save it to the CSV
                echo "$domain,$service,$server,$port,$proto" >> $csvoutput
            done
        else
            echo " It does not have $service servers"
        fi
    done # for service in `cat $SRVFILE`
    IFS=$OFS

}

######################## 

function main(){
    local domains=$1
    local csvoutput=$2
    local prospectmode=$3

    showBanner

    if [[ "$domains" == "" || "$csvoutput" == "" ]]
    then
        printUsage
        exit 1
    fi

    if [[ "$prospectmode" == "small" || "$prospectmode" == "SMALL" ]]
    then
        SRVFILE="services/commonsrv.txt"
    elif [[ "$prospectmode" == "extended" || "$prospectmode" == "EXTENDED" ]]
    then
        SRVFILE="services/extendedsrv.txt"
    else
        SRVFILE="services/commonsrv.txt"
    fi

    # Initialize the DNSSERVERS
    initializeDNSSERVERS

    # Empty the csvoutput file
    echo -n "" > $csvoutput

    if [[ -f $domains ]]
    then
        echo ""
        lightblue "Prospecting with the following configuration:"
        lightblue " - Domains: File $domains"
        lightblue " - SRV records to detect: File $SRVFILE"
        lightblue " - Open Resolvers used: File $DNSFILE"

        OFS=$IFS
        IFS=$'\n'
        for d in `cat $domains`
        do
            prospectDomain $d
        done
        IFS=$OFS
    elif  is_valid_domain $domains 
    then
        lightblue "Prospecting with the following configuration:"
        lightblue " - Domain: Single domain $domains"
        lightblue " - SRV records to detect: File $SRVFILE"
        lightblue " - Open Resolvers used: File $DNSFILE"

        # The domains is not a file, is a domain name
        prospectDomain $domains
    else
        echo "The file $domains does not exists and is not a valid domain name. Try again..."
    fi
}

##########
## MAIN ##
##########

main $1 $2 $3
