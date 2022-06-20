#!/usr/bin/env bash

# releases.sh
# Written by Marc Carlson
# Check current release of OpenBSD. Download latest and past releases in ISO or IMG format. Also, download signature and check download integrity.

function usage {
echo "   Usage: ./releases.sh [-cvadsirh] [options]"
echo "  -c  check current version"
echo "  -v  version"
echo "  -a  architecture - i.e i386, amd64"
echo "  -i  installation image - iso for CD, img for USB"
echo "  -s  signature"
echo "  -d  download - use with -v, a and -i (or) -sv, -a and -i"
echo "  -r  resume download"
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts "dv:sa:i:rhc" arg; do
   case $arg in
   d) download=1;;
   s) sig=1;;
   v) version="$OPTARG" ;;
   a) arch="$OPTARG";;
   i) image="$OPTARG" ;;
   r) resume=1;;
   c) current=1;;
   h) usage && exit ;;
   esac
   done
}

check_current() {
if [[ $current == 1 ]]; then
printf "The current release is: " ; curl -s https://www.openbsd.org/ | grep release | grep OpenBSD | sed 's/ //1' | cut -d \> -f 2 | cut -d \< -f 1
exit
fi
}

function check_flags {
   if [ -z "$arch" ]; then echo use the -a flag and architecture
   exit; fi
if [ -z $image ]; then echo use the -i flag and image format. iso or img
   exit; fi
}

function check_version {
   if [[ $version ]] && [ -z $download ]; then
   printf "Checking release $version: "
   sleep 1; 
   response=$(curl -s -o /dev/null -w "%{http_code}\n" https://cdn.openbsd.org/pub/OpenBSD/$version/)
   if [[ $response == 200 ]];
   then printf "available\n"; exit
   else printf "unavailable\n"; exit
   exit;
   fi; fi
}

function download {   
format=$(printf install$version | sed 's/\.//g'; printf .$image)
   if [[ $resume == 1 ]] ;then
   wget -q -c --show-progress https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/$format; fi
   if [[ $download ]] && [[ $version ]] ; then
   wget  -q  --show-progress https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/$format; fi

  exit
}

function signature {
   format=$(printf install$version | sed 's/\.//g'; printf .$image)
   filename=$(echo $format | sed 's/install//' | cut -d . -f 1)
   if [[ $download == 1 && $sig == 1 ]]; then
   printf "Downloading signature: "
   wget  -q https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/SHA256.sig
   printf "done\n"
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format
   exit
   fi
}

get_args $@
check_current
check_version
check_flags
signature
download
