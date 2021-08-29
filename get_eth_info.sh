#!/bin/bash
#
# Given the name of an ethernet device connected to a USB dongle,
# return the Vendor ID, the product ID, the bus number, port number,
# and device number.

usage()
{
    echo Usage:
    echo "  get_eth_info.sh [-h] ethernet-name"
    echo ""
    echo "-h  Shows this help"
    echo ""
    echo Given a USB ethernet dongle name, returns idVendor:idProduct
    echo and device number.
}

while getopts ":h" opt; do
  case ${opt} in
    h )
        usage
        exit 0;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      exit 1;;
  esac
done

shift $((OPTIND -1))

eth=${1?Need the name of an ethernet device}

echo ID=$(cat /sys/class/net/$eth/device/../idVendor):$(cat /sys/class/net/$eth/device/../idProduct)
echo Device Number=$(cat /sys/class/net/$eth/device/../devnum)
