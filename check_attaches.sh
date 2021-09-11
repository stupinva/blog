#!/bin/sh

BASE=/srv/stupin.su/blog/

find $BASE -type f -name index.html -mindepth 2 -maxdepth 2 | \
        while read filename
        do
		dir=`echo "$filename" | sed 's/\/index\.html$//'`
		imagefiles=`cat "$filename" | egrep '<source src=|<img src=|<a href=' | sed -E 's/<source sce="|<img src="|<a href="/\n\0/g; s/^.*(<source src=|<img src=|<a href=)"([^"]*)".*$/\2/g' | egrep -v "^(https?:|mailto:|..)"`
		if [ -n "$imagefiles" ]
		then
			echo "$imagefiles" | \
				while read imagefile
				do
					if [ ! -f "$dir/$imagefile" ]
					then
						echo "Missing picutre $dir/$imagefile"
					fi
				done
		fi
        done

find $BASE -type f ! -name index.html -mindepth 2 -maxdepth 2 | \
	while read filename
	do
		articlefile=`echo "$filename" | sed 's/^\(.*\/\)[^\/]*$/\1index.html/'`
		if [ -f "$articlefile" ]
		then
			attachedfile=`echo "$filename" | sed 's/^.*\/\([^\/]*\)$/\1/'`
			n=`cat "$articlefile" | egrep '<source src=|<img src=|<a href=' | sed -E 's/<source src="|<img src="|<a href="/\n\0/g; s/^.*(<source src=|<img src=|<a href=)"([^"]*)".*$/\2/g' | grep -c "$attachedfile"`
			if [ "$n" -eq 0 ]
			then
				echo "Unlinked file $filename"
			fi
		fi
	done
