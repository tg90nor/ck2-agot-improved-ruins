#!/bin/sh

if [ $# -lt 2 ]; then
  echo "Usage: $0 province_id start_date [end_date]"
  echo "Example: $0 445 6564.1.1 7886.1.1"
  exit
fi

scriptdir=$(dirname "$(readlink -f $0)")
export PATH=$PATH:$scriptdir
histdir="$scriptdir/../history"
infile=$(find "$histdir/provinces/" -name "$1 - *.txt")

provid=$(head -1 "$infile" | awk '{print $2;}')
if [ "$provid" != "$1" ]; then
  echo "Wrong province id in header of $infile"
  exit
fi

title=$(egrep '^title' "$infile" | rev | awk '{print $1;}' | rev | sed 's/\r//')

echo $title
export CHARID="3140${provid}0"
export TITLENAME=$title
export STARTDATE=$2
export ENDDATE=$3
export END=""

if [ "$ENDDATE" != "" ]; then
  export END=$(printf "$ENDDATE = {\n\tholder = 0\n}\n")
fi
envsubst < "$scriptdir/generate-ruin-history/county_template.txt" >> $histdir/titles/$TITLENAME.txt
if [ "$ENDDATE" != "" ]; then
  export END=$(printf "\t$ENDDATE = {\n\t\tdeath = yes\n\t}\n")
fi
envsubst < "$scriptdir/generate-ruin-history/character_template.txt" >> $histdir/characters/unoccupied.txt

baronies=$(egrep '^b_' "$infile" | sed 's/ = .*//' | sed -n '1!p' | tr '\n' ' ')
set -- $baronies
counter=1

while [ "$1" != "" ]; do
  echo $1
  export CHARID="3140${provid}${counter}"
  counter=$((counter + 1))
  export TITLENAME=$1

  if [ "$ENDDATE" != "" ]; then
    export END=$(printf "$ENDDATE = {\n\tholder = 0\n}\n")
  fi
  envsubst < "$scriptdir/generate-ruin-history/barony_template.txt" >> $histdir/titles/$TITLENAME.txt
  if [ "$ENDDATE" != "" ]; then
    export END=$(printf "\t$ENDDATE = {\n\t\tdeath = yes\n\t}\n")
  fi
  envsubst < "$scriptdir/generate-ruin-history/character_template.txt" >> $histdir/characters/unoccupied.txt

  shift
done

exit

cat character_template.txt | sed "s/CHARID/3140${provid}0/" | sed "s/TITLENAME/$title/" >> $histdir/characters/unoccupied.txt
cat county_template.txt | sed "s/CHARID/3140${provid}0/" | sed "s/TITLENAME/$title/" | sed "s/DATE/$2/" >> $histdir/titles/$title.txt

if [ "$barony1" != "" ]; then
  cat character_template.txt | sed "s/CHARID/3140${provid}1/" | sed "s/TITLENAME/$barony1/" >> $histdir/characters/unoccupied.txt
  cat barony_template.txt | sed "s/CHARID/3140${provid}1/" | sed "s/TITLENAME/$barony1/" | sed "s/DATE/$2/" >> $histdir/titles/$barony1.txt
fi

if [ "$barony2" != "" ]; then
  cat character_template.txt | sed "s/CHARID/3140${provid}2/" | sed "s/TITLENAME/$barony2/" >> $histdir/characters/unoccupied.txt
  cat barony_template.txt | sed "s/CHARID/3140${provid}2/" | sed "s/TITLENAME/$barony2/" | sed "s/DATE/$2/" >> $histdir/titles/$barony2.txt
fi

echo