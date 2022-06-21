#!/usr/bin/env bash

# releases.sh
# Written by Marc Carlson
# Check current release of OpenBSD. Download latest release in ISO or IMG format. Also, download signature and check download integrity.

function usage {
echo "   Usage: ./releases.sh [-cadsirh] [options]"
echo "  -c  check current version release"
echo "  -a  architecture - i.e i386, amd64"
echo "  -i  installation image - iso for CD, img for USB"
echo "  -s  signature"
echo "  -d  download - use with a and -i (or) -s -a and -i"
echo "  -r  resume download"
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts "dv:sa:i:rhcm" arg; do
   case $arg in
   d) download=1;;
   s) sig=1;;
   a) arch="$OPTARG";;
   i) image="$OPTARG" ;;
   r) resume=1;;
   c) current=1;;
   h) usage && exit ;;
   esac
   done
}

version=$(curl -s https://www.openbsd.org/ | grep release | grep OpenBSD | sed 's/ //1' | cut -d \> -f 2 | cut -d \< -f 1 | awk '{ print $2}')

check_current() {
release=$(curl -s https://www.openbsd.org/ | grep release | grep OpenBSD | sed 's/ //1' | cut -d \> -f 2 | cut -d \< -f 1)
if [[ $current == 1 ]]; then
printf "The current release is: " ; echo $release
exit
fi
}

function check_flags {
   if [ -z "$arch" ]; then echo use the -a flag and architecture
   exit; fi
if [ -z $image ]; then echo use the -i flag and image format. iso or img
   exit; fi
}

function download {   
format=$(printf install$version | sed 's/\.//g'; printf .$image)
   if [[ $resume == 1 ]] ;then
   wget -q -c --show-progress https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/$format; fi
   if [[ $download ]] && [[ -z $resume ]]; then
   wget  -q  --show-progress https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/$format; fi

  exit

}

function signature {
   format=$(printf install$version | sed 's/\.//g'; printf .$image)
   filename=$(echo $format | sed 's/install//' | cut -d . -f 1)
   if [[ $download ]] && [[ $sig == 1 ]]; then
   printf "Downloading signature: "
   wget  -q https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/SHA256.sig
   printf "done\n"
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format
   exit
   fi
}

get_args $@
check_current
check_flags
signature
download
