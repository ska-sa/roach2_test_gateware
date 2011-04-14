#!/bin/bash
cat *.V | grep U1- \
        | grep -v inout \
        | grep -v PowerSignal \
        | grep -v PinSignal \
        | grep -v -e SM_ -e TCK -e TDO -e TMS -e TDI -e THERM -e PROGN -e HSWAPEN \
        | sed -e 's/^  *\.//' \
        | sed -e 's/(NamedSignal_/,/' \
        | sed -e 's/XL_/PPC_/' \
        | sed -e 's/).*//' > /tmp/stripped

for i in `cat /tmp/stripped`; do
  PIN=`echo $i | sed -e 's/,.*//'`
  NAME=`echo $i | sed -e 's/^.*,//'| tr '[][:upper:]' '<>[:lower:]'`
  echo NET "\"$NAME\"               LOC = $PIN;"
done
