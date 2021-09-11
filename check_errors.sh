#!/bin/sh

BASE=/srv/stupin.su/blog/

find $BASE -type f -name index.html -mindepth 2 -maxdepth 2 | \
	while read filename
	do
		errors=`tidy -xml -utf8 -qe "$filename" 2>&1`
		if [ -n "$errors" ]
		then
			slug=`echo "$filename" | sed 's/\/index\.html$// ; s/^.*\///'`
			echo "---------- $slug ----------"
			echo "$errors"
			break
		fi
	done | \
	head -n2
