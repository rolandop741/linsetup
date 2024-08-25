#!/bin/bash

#was cam3.sh 08162024

# Function to print usage
usage() {
    echo "Usage: $0 [-v] [-l log_file] [-n segments] [-d duration] [-c] [-p prefix] [-i input_url]"
    echo "  -v             Enable verbose mode"
    echo "  -l log_file    Log output to the specified file"
    echo "  -n segments    Number of segments to download (default is 10)"
    echo "  -d duration    Duration of segments (default is 60)"
    echo "  -c             Use clipboard content as input URL"
    echo "  -p prefix      Set prefix"
    echo "  -i input_url   Specify input URL directly"
    exit 1
}

# Default values
verbose=0
log_file=""
segments=10
duration=60
use_clipboard=0
prefix=""
input_url=""

# Parse options
while getopts "vl:n:d:cp:i:" opt; do
    case ${opt} in
        v )
            verbose=1
            ;;
        l )
            log_file=$OPTARG
            ;;
        n )
            segments=$OPTARG
            ;;
        d )
            duration=$OPTARG
            ;;
        c )
            use_clipboard=1
            ;;
        p )
            prefix=$OPTARG
            ;;
        i )
            input_url=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Function to log messages
log() {
    if [ $verbose -eq 1 ]; then
        echo "$1"
    fi
    if [ -n "$log_file" ]; then
        echo "$1" >> "$log_file"
    fi
}

# Determine input URL
if [ -n "$input_url" ]; then
    if [ -f "$input_url" ]; then
        # Read the URL from the file if input_url is a file
        input=$(<"$input_url")
    else
        # Otherwise, treat input_url as the actual URL
        input=$input_url
    fi
elif [ $use_clipboard -eq 1 ]; then
    input=$(pbpaste)
else
    # Prompt for the input URL if neither -i nor -c is used
    read -p "Enter the input URL: " input
fi


# Prompt for the prefix if not set
if [ -z "$prefix" ]; then
    read -p "Enter the file prefix: " prefix
fi

# Confirm user inputs
echo "Input URL: $input"
echo "File prefix: $prefix"
echo "Duration: $duration seconds"
echo "Number of segments: $segments"

# Function to generate a unique filename
generate_unique_filename() {
    local prefix="$1$(date +%m%d)"
    local counter=1
    while [ -e "${prefix}-${counter}.mp4" ]; do
        counter=$((counter + 1))
    done
    echo "${prefix}-${counter}.mp4"
}

# Initialize iteration counter
iteration=0

# Loop to download and save video segments
while [ $iteration -lt $segments ]; do
    output=$(generate_unique_filename "$prefix")

    echo "saving as $output..."

    if ffmpeg -v error -i "$input" -c copy -t "$duration" "$output"; then
        # Inform the user about the current segment being saved
        log "Saving segment $((iteration + 1))/$segments as $output"
        echo "Saved $output"
        
        # Increment the iteration counter
        ((iteration++))
    else
        log "Error occurred during the download of segment $((iteration + 1))"
        break
    fi
done

if [ $iteration -eq $segments ]; then
    log "All segments have been saved."
else
    log "Download stopped prematurely."
fi
