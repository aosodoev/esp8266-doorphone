#!/bin/sh

# ffmpeg -re -i stream.mp3 -ar 16000 -ac 1 -acodec g722 -f g722 udp://gatescontrol.local:48550

# ffmpeg -f avfoundation -i ":0" -ar 16000 -ac 1 -acodec g722 -f g722 udp://127.0.0.1:48550

ffplay -f g722 -probesize 32 -vn -nodisp -sync ext  udp://127.0.0.1:45990
