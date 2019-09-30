#!/bin/sh

for i in sounds/*.wav; do
    bn=$(basename "$i") 
    ffmpeg -i "$i" -ar 16000 -f g722 -acodec g722 "../../data_handset_v1/${bn%.wav}.g722";
done
