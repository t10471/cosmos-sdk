#!/bin/bash

seeds=(1 2 4 7 9 20 32 123 124 582 1893 2989 3012 4728 37827 981928 87821 891823782 989182 89182391)
blocks=$1

echo "Running multi-seed simulation with seeds ${seeds[@]}"
echo "Running $blocks blocks per seed"
echo "Edit scripts/multisim.sh to add new seeds. Keeping parameters in the file makes failures easy to reproduce."
echo "This script will kill all sub-simulations on SIGINT/SIGTERM (i.e. Ctrl-C)."

trap 'kill $(jobs -pr)' SIGINT SIGTERM

tmpdir=$(mktemp -d)
echo "Using temporary log directory: $tmpdir"

sim() {
  seed=$1
	echo "Running full Gaia simulation with seed $seed. This may take awhile!"
  file="$tmpdir/gaia-simulation-seed-$seed-date-$(date -Iseconds -u).stdout"
  echo "Writing stdout to $file..."
	go test ./cmd/gaia/app -run TestFullGaiaSimulation -SimulationEnabled=true -SimulationNumBlocks=$blocks \
    -SimulationVerbose=true -SimulationCommit=true -SimulationSeed=$seed -v -timeout 24h > $file
}

i=0
pids=()
for seed in ${seeds[@]}; do
  sim $seed &
  pids[${i}]=$!
  i=$(($i+1))
  sleep 10 # start in order, nicer logs
done

echo "Simulation processes spawned, waiting for completion..."

code=0

i=0
for pid in ${pids[*]}; do
  wait $pid
  last=$?
  seed=${seeds[${i}]}
  if [ $last -ne 0 ]
  then
    echo "Simulation with seed $seed failed!"
    code=1
  else
    echo "Simulation with seed $seed OK"
  fi
  i=$(($i+1))
done

exit $code
