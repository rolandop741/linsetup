#!/bin/bash

# Function to generate a random 4-character prefix
generate_random_prefix() {
  random_prefix=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
  echo "$random_prefix"
}

# Function to trim the video
trim_video() {
  input_file="$1"
  start_time_input="$2"
  duration="$3"

  # Check if the input file exists
  if [ ! -f "$input_file" ]; then
    echo "Input file does not exist. Please provide a valid file path."
    exit 1
  fi

  # Convert the start time in various formats to seconds
  IFS=':' read -ra start_time_parts <<< "$start_time_input"
  case "${#start_time_parts[@]}" in
    3)
      # HH:MM:SS format
      hours="${start_time_parts[0]}"
      minutes="${start_time_parts[1]}"
      seconds="${start_time_parts[2]}"
      start_time=$((hours * 3600 + minutes * 60 + seconds))
      ;;
    2)
      # MM:SS format
      minutes="${start_time_parts[0]}"
      seconds="${start_time_parts[1]}"
      start_time=$((minutes * 60 + seconds))
      ;;
    1)
      # SS format
      start_time="${start_time_parts[0]}"
      ;;
    *)
      echo "Invalid start time format. Please enter a valid format."
      exit 1
      ;;
  esac

  # Check if the input is a valid number
  if ! [[ "$start_time" =~ ^[0-9]+$ ]] || ! [[ "$duration" =~ ^[0-9]+$ ]]; then
    echo "Invalid start time or duration. Please enter valid numbers."
    exit 1
  fi

  # Get the file extension from the input file
  input_extension="${input_file##*.}"

  # Generate a random 4-character prefix
  random_prefix="$(generate_random_prefix)"
  
  # Generate the output file name with the prefix and the same extension as the input file
  output_file="${random_prefix}_output.${input_extension}"
  echo "saving as: $output_file"

  # Run the FFmpeg command with the provided input file, start time, and duration
  ffmpeg -hide_banner -ss "$start_time" -i "$input_file" -c copy -t "$duration" "$output_file"
}

# Check if command-line arguments are provided
if [ "$#" -eq 3 ]; then
  trim_video "$1" "$2" "$3"
else
  # Prompt the user for input interactively
  read -p "Enter the input file name (e.g., input.webm): " input_file
  read -p "Enter the start time (e.g., 5 for default starting point, 5:05 for 5 minutes and 5 seconds, 1:10:05 for 1 hour, 10 minutes, and 5 seconds, or 5,10 for starting at 5 seconds and 10 seconds duration): " start_time_input
  read -p "Enter the duration (e.g., 10 for 10 seconds): " duration
  trim_video "$input_file" "$start_time_input" "$duration"
fi
