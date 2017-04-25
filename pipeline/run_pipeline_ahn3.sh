#!/bin/bash
date
exec > >(tee output.log)
exec 2>&1
MAPNR=$1
declare -i COUNT
COUNT=$( ls -l /data/ahn3/*.LAZ | wc -l )
i=0
echo $COUNT
for file in /data/ahn3/*.LAZ
do
  echo 'Next file: '
  echo $file
  pdal pipeline --debug /pipeline/pdal-connection_ahn3.json --readers.las.filename=$file --writers.pgpointcloud.table=patches_ahn3
  let  "COUNT -= 1"
  let "i += 1"
  echo '##### ' $i ' bestanden gedaan, nog' $COUNT 'te gaan.... #####'
  date
done
date