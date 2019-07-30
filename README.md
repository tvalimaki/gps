GPS
======

This code is a reimplementation of the guided policy search algorithm and LQG-based trajectory optimization, meant to help others understand, reuse, and build upon existing work.

For full documentation, see [rll.berkeley.edu/gps](http://rll.berkeley.edu/gps).

The code base is **a work in progress**. See the [FAQ](http://rll.berkeley.edu/gps/faq.html) for information on planned future additions to the code.

Docker
------

New Docker image at [tvalimaki/gps](https://hub.docker.com/r/tvalimaki/gps/)

Usage
------

Running docker on a local machine

```bash
./launch_docker_local.sh
```

Running docker on a server over ssh

```bash
./launch_docker_remote.sh
```
