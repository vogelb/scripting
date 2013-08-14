#!/bin/bash
#
# Bash Shell script to create a table of contents (index.html) file, e.g. from a TFS Project Office.
#
# The index.html needs to be checked out to update it.
#
declare -r TARGET=index.html

# Recursively process a folder, files first then subfolders
function handle_folder { # $1: the folder to process
	FOLDER="$1"
	
	find "$FOLDER" -maxdepth 1 -type f \
       -and -not -name index.html \
	   -and -not -name create_index.sh \
	   | sed "s/^\.\(.*\/\)\(.*\)/    \2\<\/br\>/"
	   
	find "$FOLDER" -maxdepth 1 -type d \
	   -not -name . \
	   -and -not -path "$FOLDER" | while read LINE
	do
		echo "$LINE" \
		| sed "s/^\.\/\(.*\)/    \<div class=\"category\"\>\1\<\/div\>/g"
		handle_folder "$LINE"
	done
}

# Create TOC header
echo "Creating header..."
cat <<-END_HEADER >$TARGET 
<html>
  <head>
    <meta HTTP-EQUIV="Content-Type" content="text/html; charset=utf-8" />
    <title>Table of contents</title>
    <style type="text/css">
      div.category { 
        font-size: larger;
        font-weight: bold;
        margin-top: 12pt;
      }
	  
      body { 
        background-color:#E0E0E0;
        font-family: Verdana;
        font-size: larger
      }
    </style>
  </head>
  <body>
    <h1>Project Office</h1>
    <h2>Table of Contents</h2>
END_HEADER

echo -n "Created " >> $TARGET
date +"%d.%m.%Y %T" >> $TARGET

echo "<br/>" >> $TARGET
echo "<br/>" >> $TARGET

echo "Processing folders..."
handle_folder . >>$TARGET

# Create TOC footer
echo "Processing footer..."
cat <<-END_FOOTER >>$TARGET 
  </body>
</html>
END_FOOTER

echo "All done."