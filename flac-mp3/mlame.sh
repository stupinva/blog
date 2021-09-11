#!/bin/sh

for flac in *.flac;
do
    mpeg=`echo $flac | cut -f1 -d.`.mp3
    cat "$flac" | flac -d -c - | lame --cbr -b 192 - - | cat - > "$mpeg"
done

