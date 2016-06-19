#!/bin/bash

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

VREP_PATH=~/Downloads/V-REP_PRO_EDU_V3_3_0_Mac/vrep.app/Contents/MacOS/ # MODIFY WITH YOUR VREP PATH
LINUX=0 # SET TO 1 IF RUNNING ON LINUX
USAGE="Usage ./run_simulations [-n <n_simulations>] -s <scene_filename> [-t <max_sim_time_in_ms] [-d <goal_distance>] [-v <robot_velocity>] -o <csv_filename>"
SCENE_PATH="$(get_abs_filename "../scenes/")/"
echo $SCENE_PATH

OUT_PATH=$(get_abs_filename "../data/")
if [ ! -d "$OUT_PATH" ]; then
    mkdir "$OUT_PATH"
fi
OUT_PATH="$OUT_PATH/csv/"
echo $OUT_PATH


while getopts "hn:s:t:d:v:o:" opt; do
  case $opt in
    h)
      # help
      echo $USAGE ;
      exit 1 ;;
    n)
      # number of simulations
      TIMES="$OPTARG" ;;
    s)
      # scene to open (NOTE PROBLEM WITH SPACES IN THE PATH)
      SCENE="$OPTARG" ;;
    t)
      # max simulation time (s)
      MAX_T="$OPTARG" ;;
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
      echo $USAGE ;;
  esac
done

if [ -z "$TIMES" ];
  then
      TIMES=1;
fi

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

if [ -z "$MAX_T" ];
  then
      MAX_T=10;
fi

if [ -z $DIST ];
  then
      DIST=3;
fi

if [ -z $VEL ];
  then
      VEL=1;
fi

if [ $LINUX -ne 0 ];
  then
      VREP=./vrep.sh;
  else
      VREP=./vrep;
fi


if [ ! -d "$OUT_PATH" ]; then
    mkdir "$OUT_PATH"
fi

SCENE="$SCENE_PATH$SCENE"
OUT="$OUT_PATH$OUT"

RUN="$VREP -q  -s -g$DIST -g$VEL -g$MAX_T -g$OUT $SCENE"

COMMAND="cd $VREP_PATH"



if [ -f $OUT ]
  then
      while true; do
        read -p "$OUT already exists. Do you want to overwrite it? " yn
        case $yn in
            [Yy]* ) rm -rf $OUT; echo "TRAVERSED, ELAPSED_TIME, GOAL, R_I, R_F" > $OUT; $COMMAND;
                DIV=$(($TIMES/100));
                REM=$(($TIMES-$DIV * 100));
                while [ $DIV -gt 0 ]; do
                    for i in `seq 1 100`; 
                        do
                           $RUN &
                        done
                    wait ;
                    DIV=$(($DIV-1));
                done
                for i in `seq 1 $REM`; 
                        do
                           $RUN &
                        done
                    wait ;
                break ;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
      done
  else
    echo "TRAVERSED, ELAPSED_TIME, GOAL, R_I, R_F" > $OUT;
    $COMMAND
    DIV=$(($TIMES/100));
    REM=$(($TIMES-$DIV * 100));
    while [ $DIV -gt 0 ]; do
        for i in `seq 1 100`; 
            do
               $RUN &
            done
        wait ;
        DIV=$(($DIV-1));
    done
    for i in `seq 1 $REM`; 
        do
           $RUN &
        done
    wait ;
fi

