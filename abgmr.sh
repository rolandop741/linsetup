#!/bin/bash

# Define your input video and song file paths
inputvideo="$1"
inputsong="$2"
volume="$3"


counter=1
while [ -f "result${counter}.mp4" ]; do
    counter=$((counter + 1))
done
outputfile="result${counter}.mp4"

# Get the length of the input video and song
video_length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$inputvideo")
song_length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$inputsong")

# Calculate the maximum start time and generate a random start time
max_start_time=$(echo "$song_length - $video_length" | bc)
if (( $(echo "$max_start_time > 0" | bc -l) )); then
    start_time=$(echo "scale=0; $RANDOM % $max_start_time" | bc) 
else
    start_time=0
fi

# Extract a segment from the input song
temp_song="temp_song.m4a"
ffmpeg -v error -i "$inputsong" -ss "$start_time" -t "$video_length" -c copy "$temp_song"

# Mix the extracted song with the video
ffmpeg -i "$inputvideo" -i "$temp_song" -filter_complex "[1:a]volume=$volume[a1];[0:a][a1]amix=inputs=2:duration=first:dropout_transition=2" -c:v copy -c:a aac -strict experimental "$outputfile"
#ffmpeg -v error -i "$inputvideo" -i "$temp_song" -map 0:v -map 1:a -c:v copy -c:a copy -shortest -y "$outputfile"
# Clean up
rm "$temp_song"
open $outputfile