#!/usr/bin/env bash

function usage {
echo "   Usage: releases [-vadscirh] [options]"
echo "  -c  check releases - use with -v"
echo "  -v  version"
echo "  -a  architecture - i.e i386, amd64"
echo "  -i  installation image - iso for CD, img for USB"
echo "  -s  signature"
echo "  -d  download - use with -v, a and -i (or) -sv, -a and -i"
echo "  -r  resume download"
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts "dv:sca:li:rh" arg; do
   case $arg in
   d) download=1;;
   s) sig=1;;
   v) version="$OPTARG" ;;
   a) arch="$OPTARG";;
   c) check=1;;
   i) image="$OPTARG" ;;
   r) resume=1;;
   h) usage && exit ;;
   esac
   done
}

function check_flags {
   if [ -z "$arch" ]; then echo use the -a flag and architecture
   exit; fi
if [ -z $image ]; then echo use the -i flag and image format. iso or img
   exit; fi
}

function check {
   if [[ $check == 1 ]]; then
   printf "Checking release $version: "
   sleep 1; 
   response=$(curl -s -o /dev/null -w "%{http_code}\n" https://cdn.openbsd.org/pub/OpenBSD/$version/)
   if [[ $response == 200 ]];
   then printf "released\n"; exit
   else printf "not yet released\n"; exit
   exit;
   fi; fi
}

function download {
   format=$(printf install$version | sed 's/\.//g'; printf .$image)
   if [[ $resume == 1 ]] ;then
   wget -q -c --show-progress https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/$format; fi
   if [[ $download == 1 ]] ; then
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
check
check_flags
signature
download
