#!/bin/bash

# Input arguments
inputvideo=$1
inputsong=$2
volume=$3

# Counter for unique output file names
counter=1

# Find the next available unique output file name
while [ -f "result${counter}.mp4" ]; do
    counter=$((counter + 1))
done

# Generate unique output file name
outputfile="result${counter}.mp4"

# Run FFmpeg command
ffmpeg -i "$inputvideo" -i "$inputsong" -filter_complex "[1:a]volume=$volume[a1];[0:a][a1]amix=inputs=2:duration=first:dropout_transition=2" -c:v copy -c:a aac -strict experimental "$outputfile"

echo "Output video created: $outputfile"
open $outputfile
