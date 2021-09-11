#!/bin/sh

BASE=/srv/stupin.su/blog/

find "$BASE" -type f -name index.html -mindepth 2 -maxdepth 2 | \
	while read filename
	do
		slug=`echo "$filename" | sed 's/\/index\.html$// ; s/^.*\///'`
		date=`egrep '<!-- [0-9]{4}-[0-9]{2}-[0-9]{2} -->' "$filename" | sed -E 's/^.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*$/\1/'`
		title=`egrep '<title>.*</title>' "$filename" | sed -E 's/^.*\<title\>(.*)\<\/title\>.*$/\1/'`

		index_line=`fgrep "\"$slug/" index.html`
		if [ -z "$index_line" ]
		then 
			echo "$slug not found in index!"
		else
			index_date=`echo "$index_line" | sed -E 's/^.*\<li\>([0-9]{4}-[0-9]{2}-[0-9]{2}) - \<a.*$/\1/'`
			index_title=`echo "$index_line" | sed -E 's/^.*\>([^<>]*)\<\/a>.*$/\1/'`

			if [ "$date" != "$index_date" ]
			then
				echo "$slug: $index_date != $date"
			fi

			if [ "$title" != "$index_title" ]
			then
				echo "$slug: $index_title != $title"
			fi
		fi
	done

cat "$BASE/index.html" | \
	while read line
	do
		slug=`echo "$line" | fgrep '<a href=' | sed -E 's/^.*\<a href="([^"/]*)\/"\>.*$/\1/'`
		if [ -z "$slug" ]
		then
			continue
		fi

		if [ ! -f "$BASE/$slug/index.html" ]
		then
			echo "$slug isn not exist!"
		fi
	done

exit

