#!/bin/bash
# make executable
# Usage: ./make_executable.sh <filename>

# Check if a filename is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

#
mkb $1
#

# Make the specified file executable
chmod +x "$1"

name=$(basename "$1" .sh) 

mv "$1" ~/rbin/$name

source ~/.bashrc
