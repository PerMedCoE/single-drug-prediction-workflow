#!/usr/bin/env bash

echo "Uninstalling single-drug-prediction required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../../BuildingBlocks

cd Carnival_feature_merger
./uninstall.sh
cd ..

cd Carnival_gex_preprocess
./uninstall.sh
cd ..

cd CarnivalPy
./uninstall.sh
cd ..

cd ml_jax_drug_prediction
./uninstall.sh
cd ..

cd omnipath
./uninstall.sh
cd ..

cd progeny
./uninstall.sh
cd ..

cd tf_enrichment
./uninstall.sh
cd ..

# cd Carnival
# ./uninstall.sh
# cd ..

# cd CellNOpt
# ./uninstall.sh
# cd ..

# cd export_solver_hdf5
# ./uninstall.sh
# cd ..

cd ${CURRENT_DIR}
