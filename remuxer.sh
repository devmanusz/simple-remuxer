#!/bin/bash

# checking for the lock file to prevent multiple running instances
LOCKFILE=~/remuxer.lock
if [ -f "$LOCKFILE" ]; then
    # lockfile does exists, we skip this run
    echo "$LOCKFILE exists."
    #exiting script
    exit 0
else 
    # lockfile not found so we can run the script
    echo "$LOCKFILE does not exist. Starting remuxer."
    # creating lockfile
    touch $LOCKFILE
fi

# setting the recordings main folder path 
#RECORDINGS=/mnt/nas/recordings/Recordings
RECORDINGS=/mnt/c/Users/gutib/Documents/!scripts
# getting all the folders as an array from the recordings main folder, we will iterate through all the folders and look for the "originals"
# folder and it's contents.
# all sub folders need to have the "originals" folder and the "remuxed" folder
# e.g.: main_folder
#                 |- sub_folder1
#                             |- originals
#                             |- remuxed
#                 |- sub_folder2
#                             |- originals
#                             |- remuxed
FOLDERS=($(ls $RECORDINGS))

# iterate through on each folder 
for FOLDER in "${FOLDERS[@]}"
do
    #ORIG_D_NAMES=()

    # make remuxed folder is missing
    mkdir -p $RECORDINGS/$FOLDER/remuxed/

    # set the originals folder path as a constant
    ORIGD=$RECORDINGS/$FOLDER/originals/
    # set the remuxed folder path as a constant
    REMUXD=$RECORDINGS/$FOLDER/remuxed/

    ORIG_D_NAMES=($(ls -1 $ORIGD | sed -e 's/\.mkv$//'))
    REMUX_D_NAMES=($(ls -1 $REMUXD | sed -e 's/\.mp4$//'))
    #echo ${ORIG_D_NAMES[@]} ${REMUX_D_NAMES[@]} | tr ' ' '\n' | sort | uniq -u)
    #FILES=$(printf '%s\n' "${ORIG_D_NAMES[@]}" "${REMUX_D_NAMES[@]}" | sort | uniq -u)
    FILE_DIFF=()
    for i in "${ORIG_D_NAMES[@]}"; do
        skip=
        for j in "${REMUX_D_NAMES[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
        done
        [[ -n $skip ]] || FILE_DIFF+=("$i")
    done


    # get the difference between the 2 folders
    # grep the files which are present in the originals folder but not in the remuxed
    # awk print the filename. probably the $5 is not needed but I forgot to remove.
    #=($(diff -qr $ORIGD $REMUXD | grep -inr --include \*.mkv --include \*.mp4 originals/ | awk '{name=$4" "$5; print name}'))
    echo "FILE_DIFF: ${FILE_DIFF[@]}"
    if ((${#FILE_DIFF[@]})); then
        for (( i=0; i<${#FILE_DIFF[@]}; i++ ))
        do
            # set the original file path as a constant
            ORIGF="$ORIGD${FILE_DIFF[$i]}.mkv"
            echo $ORIGF
            # set the original file path as a constant switch the .mkv extension to .mp4
            REMUXF="$REMUXD${FILE_DIFF[$i]}.mp4"
            # user ffmpeg to remux the mkv file to mp4
            ffmpeg -i $ORIGF -c:v copy -c:a copy $REMUXF
        done
    else
        echo "No new file found"
    fi
done

# remove lock file so the script can run next time
rm $LOCKFILE
