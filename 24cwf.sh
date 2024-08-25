#!/bin/bash
 
#####################
#   WEBM FACTORY    #
# BY ANON FOR ANONS #
#####################
 
## HOW TO RUN ##
# paste it in a .sh file, then chmod -x file.sh
# then you can run the script in any bash enabled terminal you might use
 
## DEPENDENCY ##
# You need to have ffmpeg installed, maybe in the same dir, idk i dont use windows
 
## USAGE ##
# bash script.sh
# - convert the whole directory to webm-s
# - with the default max size specified below
# - excluding too long videos specidied below
# - with the maximum % of audio bitrate specified below
# bash script.sh [max_size]
# - same but changes the size to the specified
# bash script.sh [filename]
# - with the default size, but only one file
# bash script.sh [filename] [max_size]
# - only one file, but to the specified max size
 
## BEHAVIOR ##
# puts the videos to a directory called done
# if the script skips a file, becouse of its lenght, it logs it in a file called skipped.txt with the reason
 
## CONFIGURATION ##
# Default size in MB if not specified (with this value I could post all the vids on /gif/, except 1/110 where I lovered to 4.1)
DEFAULT_SIZE=4.15
# Set the maximum duration here, longer videos will become unwatchable (in seconds)
MAX_DURATION=180
# How mutch of the final bitrate can be audio
MAX_AUDIO_PERCENTAGE=0.10
 
process_video() {
    local FILE=$1
    local SIZE=$2
    local T_FILE="./done/${FILE%.*}-${SIZE}MB_CAPPED.webm" # filename output
 
    # If a file exists with the same name, skip it
    if [ -f "$T_FILE" ]; then
        echo "$T_FILE already exists, skipping..."
        # Uncomment if you want to log existing file skips
        # echo "$T_FILE already exists" >> skipped.txt
        return 1
    fi
 
    echo "Processing $FILE into a file of maximum size $SIZE MB"
 
    # Original duration in seconds
    O_DUR=$(\
        ffprobe \
        -v error \
        -show_entries format=duration \
        -of csv=p=0 "$FILE")
 
    if [ "${O_DUR%.*}" -gt $MAX_DURATION ]; then
        echo "Duration: $O_DUR exceeds $MAX_DURATION seconds, skipping: $FILE"
        echo "$FILE too long" >> skipped.txt
        return 1 # Skip processing this file
    fi
 
    # Original audio rate
    O_ARATE=$(\
        ffprobe \
        -v error \
        -select_streams a:0 \
        -show_entries stream=bit_rate \
        -of csv=p=0 "$FILE")
 
    # Original audio rate in KiB/s
    O_ARATE=$(\
        awk \
        -v arate="$O_ARATE" \
        'BEGIN { printf "%.0f", (arate / 1024) }')
 
    # Calculate the target maximum audio bitrate in kilobits per second based on % of file size
    MAX_AUDIO_BITRATE=$(\
        awk -v size="$SIZE" \
        -v duration="$O_DUR" \
        -v perc="$MAX_AUDIO_PERCENTAGE" \
        'BEGIN { print (( size * 8192.0 ) / ( 1.048576 * duration )) * perc }')
 
    echo "Calculated maximum audio bitrate: $MAX_AUDIO_BITRATE"
    echo "Original audio bitrate: $O_ARATE"
 
    # Check if original audio bitrate is too high
    if [ "$O_ARATE" -gt "${MAX_AUDIO_BITRATE%.*}" ]; then
        echo "Lovering original audio bitrate to $MAX_AUDIO_BITRATE"
        O_ARATE="$MAX_AUDIO_BITRATE"
    fi
 
    # Target size is required to be less than the size of the audio stream
    T_MINSIZE=$(\
        awk \
        -v arate="$O_ARATE" \
        -v duration="$O_DUR" \
        'BEGIN { printf "%.2f", ( (arate * duration) / 8192 ) }')
 
    # Equals 1 if target size is ok, 0 otherwise
    IS_MINSIZE=$(\
        awk \
        -v size="$SIZE" \
        -v minsize="$T_MINSIZE" \
        'BEGIN { print (minsize < size) }')
 
    # Give useful information if size is too small
    if [[ $IS_MINSIZE -eq 0 ]]; then
        printf "%s\n" "Target size ${SIZE}MB is too small!" >&2
        printf "%s %s\n" "Try values larger than" "${T_MINSIZE}MB" >&2
        echo "$FILE audio too big for target size" >> skipped.txt
        return 1
    fi
 
    # Set target audio bitrate
    T_ARATE=$O_ARATE
 
    # Original video rate
    O_VRATE=$(\
        ffprobe -v error \
        -select_streams v:0 \
        -show_entries stream=bit_rate \
        -of default=noprint_wrappers=1:nokey=1 "$FILE")
 
    # Original video rate in KiB/s (x1.5 for correct mp4 to webm quality)
    O_VRATE=$(\
        awk \
        -v vrate="$O_VRATE" \
        'BEGIN { printf "%.0f", (vrate / 1024) }')
 
    # Calculate target video rate - MB -> KiB/s
    MAX_VIDEO_BITRATE=$(\
        awk \
        -v size="$SIZE" \
        -v duration="$O_DUR" \
        -v audio_rate="$O_ARATE" \
        'BEGIN { print  ( ( size * 8192.0 ) / ( 1.048576 * duration ) - audio_rate) }')
 
    echo "Calculated maximum video bitrate: $MAX_VIDEO_BITRATE"
    echo "Original video bitrate, slightly raised: $O_VRATE"
 
    # Check if original video bitrate is too high
    if [ "$O_VRATE" -gt "${MAX_VIDEO_BITRATE%.*}" ]; then
        echo "Lovering original video bitrate to $MAX_VIDEO_BITRATE"
        O_VRATE="$MAX_VIDEO_BITRATE"
    fi
 
    # Set target video bitrate
    T_VRATE=$O_VRATE
 
    # Perform the conversion - first pass
    # Perform the conversion - first pass
    ffmpeg -loglevel info \
        -threads 0 \
        -y \
        -i "$1" \
        -c:v libvpx-vp9 \
        -b:v "$T_VRATE"k \
        -pass 1 \
        -an \
        -f webm \
        /dev/null \
    && \
# Second pass with audio
    ffmpeg -loglevel info \
        -threads 0 \
        -i "$1" \
        -c:v libvpx-vp9 \
        -b:v "$T_VRATE"k \
        -pass 2 \
        -c:a libopus \
        -b:a "$T_ARATE"k \
        -f webm \
        "$T_FILE"
    rm -f ffmpeg2pass-0.log

}
 
# Determines how to call process_video based on input
process_files() {
    local size=$1
    shift  # Adjust parameters so $@ contains only the filenames or is empty
 
    if [ "$#" -eq 0 ]; then
        shopt -s nullglob
        for file in *.{mp4,mkv,avi,mov}; do
            if [ -f "$file" ]; then
                process_video "$file" "$size"
            fi
        done
    else
        for file in "$@"; do
            if [ -f "$file" ]; then
                process_video "$file" "$size"
            else
                echo "File not found: $file"
            fi
        done
    fi
}
if [ ! -d "done" ]; then
    mkdir done
fi
# Parsing command line arguments to determine how to process files
case "$#" in
    (0)
        process_files $DEFAULT_SIZE
        ;;
    (1)
        if [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            process_files $1
        else
            process_files $DEFAULT_SIZE "$1"
        fi
        ;;
    (2)
        if [[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            process_files "$2" "$1"
        else
            echo "Invalid argument. Second argument must be numeric (size in MB)."
            exit 1
        fi
        ;;
    (*)
        echo "Usage: $0 [filename] [size]"
        echo "       $0 [size]"
        echo "       $0 filename"
        echo "       $0"
        exit 1
        ;;
esac
