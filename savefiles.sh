#!/bin/bash
inotifywait -m -r -e create /home | while read line;
do
    if ! echo "$line" | grep -q 'ISDIR'; then
        # line = /home/user/dir CREATE file.ext

        # Get file name
        dire=$(echo "$line" | cut -d " " -f1)
        file=$(echo "$line" | cut -d " " -f3)
        file=$dire$file
        ext="${file##*.}"

        if [ "$ext" == "JPG" ] || [ "$ext" == "PNG" ] || [ "$ext" == "jpg" ] || [ "$ext" == "png" ] || [ "$ext" == "JPEG" ] || [ "$ext" == "jpeg" ]
        then
            echo $file >> /photomanager/photomanager.log
        fi
    fi
done
