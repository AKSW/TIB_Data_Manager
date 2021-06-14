#!/bin/bash

next=""
counter=0

while true
do
    counter=$(($counter+1));
    echo "Now downloading $counter th time the next ttl:"
    curl "https://nomad-lab.eu/prod/rae/beta/dcat/catalog/?format=turtle&after=$next" -H "accept: text/turtle" > $counter.ttl;
    lines=`cat $counter.ttl | wc -l`;
    echo "new ttl has $lines lines"
    
    if [ $lines -lt 3 ];
    then
        echo "Abort"
        rm -f $counter.ttl
        break;
    fi
    
    java -jar /rdf-processing-toolkit.jar integrate --jq ./$counter.ttl '?o { ?s a hydra:collection. ?s hydra:next ?o }' | jq '.[].o.id' > url.txt;
    echo "extracted url: $(cat url.txt)"
    next=`cat url.txt | awk -F'after=' '{print $2}' | sed 's/.$//'`;
    echo "new next: $next"
    
    lines=`cat url.txt | wc -l`;
    lines=$(($lines + 1));
    if [ $lines -lt 2 ];
    then
        break;
    fi
done;

echo "up to $counter ttl files are stored:"
ls -hal
