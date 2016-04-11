if [ -f ../data/results.csv ]
  then
    echo "results.csv already exists."
  else
      echo "TRAVERSED, ELAPSED_TIME, P0, P1, P2\n" > ../data/results.csv
fi

cd /Users/stefanopeverelli/Downloads/V-REP_PRO_EDU_V3_3_0_Mac
./vrep.app/Contents/MacOS/vrep -s -g3 ~/Documents/usi/6ths/Bachelor\ Project/scenes/10x10x1.25_terrain.ttt
