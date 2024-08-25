#!/bin/bash

file=$1

hash="280506ef77f32208aa8b2fbb4"

curl -F "reqtype=fileupload" -F "userhash=$hash" -F "fileToUpload=@$file" https://catbox.moe/user/api.php > r.txt
cat r.txt
