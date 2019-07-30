cmake_minimum_required(VERSION 2.8.12)
project(gps_agent_pkg)

OPTION(ENABLE_CXX11 "Enable C++11 support" ON)
OPTION(USE_CAFFE "Enable Caffe support" OFF)
OPTION(USE_CAFFE_GPU "Enable Caffe GPU support" OFF)

find_package(catkin REQUIRED COMPONENTS
  #control_toolbox
  #geometry_msgs
  pluginlib
  pr2_controller_interface
  #pr2_controller_manager
  #pr2_controllers_msgs
  pr2_mechanism_model
  #genmsg
  message_generation
  realtime_tools
  roscpp
  roslib
  rospy
  sensor_msgs
  std_msgs
  #tf
)

## System dependencies are found with CMake's conventions
find_package(Boost REQUIRED COMPONENTS system)
find_package(Eigen3 REQUIRED)
find_package(orocos_kdl REQUIRED)

## Generate messages in the 'msg' folder
add_message_files(
  FILES
  CaffeParams.msg
  ControllerParams.msg
  DataRequest.msg
  DataType.msg
  LinGaussParams.msg
  PositionCommand.msg
  RelaxCommand.msg
  SampleResult.msg
  TfActionCommand.msg
  TfObsData.msg
  TfParams.msg
  TrialCommand.msg
)

## Generate added messages and services with any dependencies listed here
generate_messages(
  DEPENDENCIES
  # geometry_msgs
  # pr2_controllers_msgs
  # sensor_msgs
  std_msgs
)

## DEPENDS: system dependencies of this project that dependent projects also need
catkin_package(
  INCLUDE_DIRS include ${EIGEN3_INCLUDE_DIR}
#  LIBRARIES gps_agent_pkg
  CATKIN_DEPENDS message_runtime std_msgs #control_toolbox geometry_msgs #orocos_kdl pluginlib pr2_controller_interface pr2_controller_manager pr2_controllers_msgs message_runtime pr2_mechanism_model realtime_tools roscpp roslib rospy sensor_msgs std_msgs tf
#  DEPENDS eigen3
)

###########
## Build ##
###########
include_directories(
  include
  ${catkin_INCLUDE_DIRS}
  ${Boost_INCLUDE_DIRS}
  ${Eigen3_INCLUDE_DIRS}
  ${orocos_kdl_INCLUDE_DIRS}
  ${protobuf_INCLUDE_DIRS}
  $ENV{GPS_ROOT_DIR}/build/gps
)

set(DDP_FILES src/robotplugin.cpp
              src/pr2plugin.cpp
              src/sample.cpp
              src/sensor.cpp
              src/neuralnetwork.cpp
              src/tfcontroller.cpp
              src/controller.cpp
              src/lingausscontroller.cpp
              src/camerasensor.cpp
              src/positioncontroller.cpp
              src/trialcontroller.cpp
              src/encodersensor.cpp
              src/encoderfilter.cpp
              src/rostopicsensor.cpp
              src/util.cpp)

# Include Caffe
if (USE_CAFFE)
  # add paths to CAFFE
  find_package(Caffe REQUIRED)
  include_directories(${Caffe_INCLUDE_DIRS})
  # add neural network to DDP controller files
  set(DDP_FILES ${DDP_FILES} src/neuralnetworkcaffe.cpp src/caffenncontroller.cpp)
  # add definitions for the C++ code
  add_definitions(-DUSE_CAFFE)
  if (USE_CAFFE_GPU)
    add_definitions(-DCAFFE_GPU)
    find_package(CUDA 5.5 REQUIRED)
    include_directories(${CUDA_INCLUDE_DIRS})
  else (USE_CAFFE_GPU)
    add_definitions(-DCPU_ONLY)
  endif (USE_CAFFE_GPU)
  # compile Caffe test
  #rosbuild_add_executable(caffe_test src/caffe_test.cpp src/neural_network_caffe.cpp)
  #target_link_libraries(caffe_test caffe protobuf)

  # compile image processor node
  #rosbuild_add_executable(caffe_img_processor src/img_processor.cpp src/neural_network_caffe.cpp)
  #target_link_libraries(caffe_img_processor caffe protobuf)
endif (USE_CAFFE)

add_library(gps_agent_lib ${DDP_FILES})

# Include Caffe in controller
if (USE_CAFFE)
  target_link_libraries(gps_agent_lib caffe protobuf)
endif (USE_CAFFE)

target_link_libraries(gps_agent_lib pthread)

add_dependencies(gps_agent_lib ${${PROJECT_NAME}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS})
