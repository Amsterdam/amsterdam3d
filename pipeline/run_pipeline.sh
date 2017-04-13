#!/bin/bash
date
exec > >(tee output.log)
exec 2>&1
MAPNR=$1
declare -i COUNT
COUNT=$( ls -l /data/Cloud_Interp_Class/*.laz | wc -l )
i=0
echo $COUNT
for file in /data/Cloud_Interp_Class/*.laz
do
  echo 'Next file: '
  echo $file
  pdal pipeline --debug pdal-connection.json --readers.las.filename=$file --writers.pgpointcloud.table=patches
  let  "COUNT -= 1"
  let "i += 1"
  echo '##### ' $i ' bestanden gedaan, nog' $COUNT 'te gaan.... #####'
  date
done
date