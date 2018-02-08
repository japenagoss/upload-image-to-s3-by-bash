#!/bin/bash
while IFS= read -r file
do
    # Get user name
    user=$(echo "$file" | cut -d "/" -f3)

    # If the file exists it have to continue
    if [ -f  $file ]
    then
        # Get date data
        date=$(identify -verbose $file | grep "exif:DateTimeOriginal")
        origDate="exif:DateTimeOriginal"
        if [ "${date/$origDate}" = "$date" ]
        then
            echo "no tiene fecha"
        else
            year=$(echo "$date" | cut -d ":" -f3)
            year=$(echo "${year/ /}")
            month=$(echo "$date" | cut -d ":" -f4)
            dayHour=$(echo "$date" | cut -d ":" -f5)
            day=$(echo "$dayHour" | cut -d " " -f1)
            hour=$(echo "$dayHour" | cut -d " " -f2)
            minute=$(echo "$date" | cut -d ":" -f6)
            second=$(echo "$date" | cut -d ":" -f7)

            # Final file name
            extension="${file##*.}"
            timestamp=$(date "+%s" -d "$month/$day/$year $hour:$minute:$second")
            lastFileName="$timestamp.$extension"

            # Create dir to save the new file
            if [ ! -d "/photomanager" ]
            then
                cd /home
                mkdir photomanager
            fi

            if [ ! -d "/photomanager/$user" ]
            then
                cd /photomanager
                mkdir $user
            fi

            if [ ! -d "/photomanager/$user/optimized" ]
            then
                cd /photomanager/$user
                mkdir optimized
            fi

            if [ ! -d "/photomanager/$user/optimized/$year" ]
            then
                cd /photomanager/$user/optimized
                mkdir $year
            fi

            if [ ! -d "/photomanager/$user/optimized/$year/$month" ]
            then
                cd /photomanager/$user/optimized/$year
                mkdir $month
            fi

           if [ ! -d "/photomanager/$user/optimized/$year/$month/$day" ]
           then
                cd /photomanager/$user/optimized/$year/$month
                mkdir $day
           fi

            if [ ! -d "/photomanager/$user/optimized/$year/$month/$day/$hour" ]
            then
                cd /photomanager/$user/optimized/$year/$month/$day
                mkdir $hour
            fi

            if [ -d "/photomanager/$user/optimized/$year/$month/$day/$hour" ]
            then
                # copye image to new dir
                cp $file /photomanager/$user/optimized/$year/$month/$day/$hour/$lastFileName
            fi

            if [ -f "/photomanager/$user/optimized/$year/$month/$day/$hour/$lastFileName" ]
            then
                # Optimize final image
                cd /photomanager/$user/optimized/$year/$month/$day/$hour/
                sudo convert $lastFileName -quality 50 -resize 1400 -strip -set comment "photomanager" $lastFileName

                # Know if the file was optimized
                comment=$(identify -verbose $lastFileName | grep 'comment: photomanager')
                comment=$(echo "$comment" | cut -d ":" -f2)
                comment=$(echo "${comment/ /}")

                # upload file to Amazon S3
                if [ "$comment" == "photomanager" ]; then
                    updload=$(/home/ubuntu/bin/aws s3 cp /photomanager/$user/optimized/$year/$month/$day/$hour/$lastFileName s3://fotomanager-bucket/$user/$year/$month/$day/$hour/$lastFileName --only-show-errors 2>&1)

                    if [ -z "${updload// }" ]; then
                        file=$(echo $file | rev | cut -d "/" -f1 | rev)
                        sed -i "/$file/d" /photomanager/photomanager.log

                        if [ ! -d "/photomanager/originals/$user" ]; then
                            cd /photomanager/originals
                            mkdir $user
                            sudo mv /home/$user/$file /photomanager/originals/$user/$file
                        else
                            sudo mv /home/$user/$file /photomanager/originals/$user/$file
                        fi
                    fi
                fi
            fi
        fi
    fi

done < "/photomanager/photomanager.log"
