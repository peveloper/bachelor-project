#!/bin/bash

VREP_PATH=~/Downloads/V-REP_PRO_EDU_V3_3_0_Mac/vrep.app/Contents/MacOS/ # MODIFY WITH YOUR VREP PATH
LINUX=0 # SET TO 1 IF RUNNING ON LINUX

while getopts "n:s:d:v:o:h:q:" opt; do
  case $opt in
    n)
      # number of simulations
      TIMES="$OPTARG" ;;
    s)
        # scene to open (NOTE PROBLEM WITH SPACES IN THE PATH)
      SCENE="$(echo $OPTARG | sed 's/ /\\ /g')" ;;
    d)
      # distance between the robot and the goal
      DIST="$OPTARG";;
    v)
      # robot's velocity
      VEL="$OPTARG" ;;
    o)
      # output file to save results of the simulations
      OUT="$OPTARG" ;;
    \?)
      echo "Usage ./simulate [-n <n_simulations>] -s <scene_file.ttt> [-d <goal_distance>] [-v <robot_velocity>] -o <output_file>" ;;
  esac
done

if [ -z "$SCENE" ];
  then
      echo "Missing argument -s <scene_file.ttt>";
      exit 1;
fi

if [ -z "$OUT" ];
  then
      echo "Missing argument -o <output_file>";
      exit 1
fi

if [ -z $DIST ];
  then
      DIST=3;
fi

# if [ -z $VEL ];
#   then
#       VEL=5;
# fi

if [ $LINUX -ne 0 ];
  then
      VREP=./vrep.sh;
  else
      VREP=./vrep;
fi

RUN="$VREP -g$DIST ${SCENE}"
echo $RUN

if [ -f $OUT ]
  then
      while true; do
        read -p "$OUT already exists. Do you want to overwrite it? " yn
        case $yn in
            [Yy]* ) cd $VREP_PATH && $RUN ; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
      done
  else
    echo "TRAVERSED, ELAPSED_TIME, GOAL, R_I, R_F" > $OUT;
    cd $VREP_PATH && $RUN ;
fi

# TODO add -s parameter when launching VREP, also to handle in main.lua
# TODO add support for paths with spaces
# TODO uncomment velocity and try to see if VREP launches correctly
