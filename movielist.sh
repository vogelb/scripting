#!/bin/bash
# medialist
#
# Cygwin bash scripts to manage movie collections
# Creates movie catalog

# Path to mediainfo
declare -r MEDIAINFO=/c/Tools/mediainfo/mediainfo

# Movie extensions to scan for
declare -r extesions=avi\|mp4\|mkv\|mpeg\|mpg

###########################################################
# Build a catalog of movie files in the current directory.
# Includes file name and movie dimensions
function catalog() {
	find . -iregex '.*\($EXTENSIONS\)' -printf '%p\n'| while read FILE
	do
		if [ -f "$FILE" ] # Ignore directories
		then
			if [ "$MEDIAINFO" != "" ]
			then
				FILENAME="$(cygpath -w "$FILE")"
				$MEDIAINFO "$FILENAME" > catalog.tmp
				WIDTH=$(grep "Width" catalog.tmp | sed "s/[^0-9]//g")
				HEIGHT=$(grep "Height" catalog.tmp | sed "s/[^0-9]//g")
				echo "$FILE: $WIDTH x $HEIGHT"
			else
				echo "$FILE: ? x ?"
			fi
		fi
	done
	rm catalog.tmp
}

###########################################################
# Command to create a catalog in the current directory.
# The catalog is written to the file <date>-movielist.txt.
function cmd_create_catalog() {
	DATE=$(date +%Y%m%d)
	FILENAME=$DATE-movielist.txt
	./catalog.sh | tee $FILENAME
	echo
	echo "Found `wc -l $FILENAME | cut -f1 -d\ ` movies."
	read
}

###########################################################
# Command to create a combined catalog off all catalogs 
# in the current directory.
# The catalog is written to the file <date>-movie-catalog.txt.
function cmd_create_full_catalog() {
	DATE=$(date +%Y%m%d)
	FILENAME=$DATE-movie-catalog.txt

	ls *-movielist-* | grep -v full | xargs cat | sed "s/.*\/\(.*\)\:\(.*\)/\1 - \2/" | sort -t \: -k1 -u > $FILENAME
}

###########################################################
# Search for movies in available catalogs.
# $1: The search term
# $2: Sort options
function find_movie() {
	TERM=$1
	SORT_OPT=$2
	echo
	echo "Searching for $TERM [$SORT_OPT]..."
	echo
	grep -iE ".*$TERM.*\:.*" *-movielist-* | sort -t \: -k2 $SORT_OPT | sed "s/.*-.*-\(.*\)\.txt.*\/\(.*\)\:\(.*\)/\1 - \2 -\3/"
	if [ "${PIPESTATUS[0]}" != "0" ]
	then
		echo "Nothing found."
	fi
	echo
}

###########################################################
# Command to search for movies in available catalogs.
# If no search term is given, the script will run in interactive mode.
# $1: The search term (optional)
function cmd_find_movie() {
	TERM=$1
	if [ "$TERM" != "" ]
	then
		if [ "${!#}" == "/a" ]
		then
			SORT_OPT=
		else 
			SORT_OPT=-u
		fi
			
		find_movie "$TERM" $SORT_OPT
		exit2
	fi

	while true
	do
		echo -n "Please enter search term, 'quit' to quit > "
		read COMMAND
		if [ "$COMMAND" != "" ]
		then
			case $COMMAND in 
				quit)
					exit 0
					;;
				dupes)
					./find_duplicates.sh
					TERM=
					;;
				*\ \/a)
					SORT_OPT=
					TERM=${COMMAND/\ \/a/}
					;;
				*)
					SORT_OPT=-u
					TERM=$COMMAND
					;;
			esac
			
			if [ "$TERM" != "" ]
			then
				find_movie "$TERM" $SORT_OPT
			fi
		fi	
	done
}

###########################################################
# Command to print help
function cmd_help() {
	echo
	echo "Available commands"
	echo "help        - Print this help"
	echo "create      - Create a movie catalog of the current directory"
	echo "list        - List catalogs"
	echo "create_full - Combine all catalogs in the current directory"
	echo "find        - Find movies"
}

COMMAND=$1
shift
if [ "$COMMAND" == "" ] || [ "$COMMAND" == "help" ]
then
	cmd_help
	exit
fi

case $COMMAND in
	help)
		cmd_help
		;;
	create)
		cmd_create_catalog
		;;
	list)
		if [ "$1" == "" ]
		then
		   ls -w 1 *-movielist*.txt
		else
		   less $1
		fi
		;;
	create_full)
		cmd_create_full_catalog
		;;
	find)
		cmd_find_movie $*
		;;
	*)
		cmd_help
		;;
esac

