# -----------------------------------------------------------------------------
# Guided Policy Search
# -----------------------------------------------------------------------------
# docker build -t gps .
# xhost +si:localuser:root
# nvidia-docker run -ti --rm \
#   -e DISPLAY -e QT_X11_NO_MITSHM=1 \
#   -v /tmp/.X11-unix:/tmp/.X11-unix \
#   -v $(pwd)/experiments:/catkin_ws/src/gps/experiments \
#   gps
# xhost -si:localuser:root
#
# Examples:
#   python python/gps/gps_main.py box2d_pointmass_example
#
#   roslaunch gps_agent_pkg pr2_gazebo.launch &
#   AND
#   python python/gps/gps_main.py pr2_example
#   OR
#   python python/gps/gps_main.py pr2_badmm_example
#
# NOTE: things that might still need fixing
#   pip==9.0.1

FROM nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04 as glvnd
FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

# -----------------------------------------------------------------------------
# glvnd
# -----------------------------------------------------------------------------

# setup glvnd for openGL
COPY --from=glvnd /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu
COPY --from=glvnd /usr/local/lib/i386-linux-gnu /usr/local/lib/i386-linux-gnu
COPY --from=glvnd /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display

# -----------------------------------------------------------------------------
# Caffe
# -----------------------------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-setuptools \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

ENV CAFFE_ROOT=/opt/caffe
WORKDIR /caffe

# FIXME: use ARG instead of ENV once DockerHub supports this
# https://github.com/docker/hub-feedback/issues/460
ENV CLONE_TAG=1.0

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    git clone https://github.com/NVIDIA/nccl.git && cd nccl && make -j install && cd .. && rm -rf nccl && \
    mkdir build && cd build && \
    cmake -DUSE_CUDNN=1 -DUSE_NCCL=1 -DCMAKE_INSTALL_PREFIX=$CAFFE_ROOT .. && \
    make -j"$(nproc)" && make install && \
    cd ../.. && rm -rf caffe

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/bin:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# -----------------------------------------------------------------------------
# Box2D
# -----------------------------------------------------------------------------

WORKDIR /pybox2d

# setup Box2D
RUN apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        python-dev \
        swig \
        python-pygame \
        git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pybox2d/pybox2d . && \
    python setup.py build  && \
    python setup.py install && \
    cd .. && rm -rf pybox2d

# -----------------------------------------------------------------------------
# ROS
# -----------------------------------------------------------------------------

# install packages
RUN apt-get update && apt-get install --no-install-recommends -y \
        dirmngr \
        gnupg2 \
        lsb-release && \
    rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
        python-rosdep \
        python-rosinstall \
        python-vcstools && \
    rm -rf /var/lib/apt/lists/*

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# bootstrap rosdep
RUN rosdep init && \
    rosdep update

# install ros packages
ENV ROS_DISTRO kinetic
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-$ROS_DISTRO-desktop-full && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# GPS
# -----------------------------------------------------------------------------

WORKDIR /catkin_ws/src/gps
COPY . /catkin_ws/src/gps

# setup dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
        libprotobuf-dev \
        protobuf-compiler \
        libboost-all-dev \
        python-pip && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -r requirements.txt

# setup GPS
RUN ./compile_proto.sh

# -----------------------------------------------------------------------------
# gps_agent_pkg
# -----------------------------------------------------------------------------

WORKDIR /catkin_ws

RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    apt-get update && apt-get install --no-install-recommends -y \
        python-qt4 \
        ros-$ROS_DISTRO-pr2-gazebo && \
    rosdep install --from-paths -r -y src/gps/gps_agent_pkg && \
    catkin_make -DUSE_CAFFE=1 -DUSE_CAFFE_GPU=1 -DCaffe_DIR=$CAFFE_ROOT/share/Caffe && \
    rm -rf /var/lib/apt/lists/*

# setup entrypoint
WORKDIR /catkin_ws/src/gps
ENTRYPOINT ["/catkin_ws/src/gps/docker_entrypoint.sh"]
CMD ["bash"]
