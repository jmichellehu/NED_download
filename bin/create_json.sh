#! /bin/bash

# Script to create jsons using gdalinfo

# Usage:
# ./create_json.sh img.tif output.json

set -e
img=$1
out_name=$2

# Check for correct number of inputs
if [ "$#" -lt 1 ] ; then
  echo "Usage is \`$(basename $0) img.tif output.json\`"
  exit 1
fi

if [ -e ${out_name} ] ; then
    out_name=${img%.*}.json
fi

gdalinfo -json ${img} > ${out_name}
