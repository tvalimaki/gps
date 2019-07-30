#!/bin/bash
# Run X application in a Docker container on a server
# Based on https://stackoverflow.com/a/48235281
XAUTH=/tmp/.docker.xauth
MAGIC_COOKIE=`xauth list $DISPLAY | awk '{print $3}'`
X11PORT=`echo $DISPLAY | sed 's/^[^:]*:\([^\.]\+\).*/\1/'`
DOCKER_IP=`ifconfig docker0 | sed -n '/inet addr/s/.*inet addr: *\([^[:space:]]\+\).*/\1/p'`
DISPLAY=`echo $DISPLAY | sed "s/^[^:]*\(.*\)/$DOCKER_IP\1/"`

xauth -f $XAUTH add $DOCKER_IP:$X11PORT . $MAGIC_COOKIE

nvidia-docker run -ti --rm \
   -e DISPLAY=$DISPLAY \
   -v $XAUTH:$XAUTH \
   -e XAUTHORITY=$XAUTH \
   -v $(pwd)/experiments:/catkin_ws/src/gps/experiments \
   tvalimaki/gps
