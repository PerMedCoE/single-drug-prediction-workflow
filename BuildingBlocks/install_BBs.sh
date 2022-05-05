#!/usr/bin/env bash

echo "Installing covid-19-workflow required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../BuildingBlocks

cd Carnival_feature_merger
./install.sh
cd ..

cd Carnival_gex_preprocess
./install.sh
cd ..

cd CarnivalPy
./install.sh
cd ..

cd ml_jax_drug_prediction
./install.sh
cd ..

cd omnipath
./install.sh
cd ..

cd progeny
./install.sh
cd ..

cd tf_enrichment
./install.sh
cd ..

# cd Carnival
# ./install.sh
# cd ..

# cd CellNOpt
# ./install.sh
# cd ..

# cd export_solver_hdf5
# ./install.sh
# cd ..

cd ${CURRENT_DIR}
