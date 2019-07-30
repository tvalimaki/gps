#!/bin/bash
xhost +si:localuser:root
nvidia-docker run -ti --rm \
  -e DISPLAY -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/experiments:/catkin_ws/src/gps/experiments \
  tvalimaki/gps
xhost -si:localuser:root
