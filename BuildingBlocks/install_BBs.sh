#!/usr/bin/env bash

echo "Installing covid-19-workflow required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../BuildingBlocks

cd carnival_feature_merger
./install.sh
cd ..

cd carnival_gex_preprocess
./install.sh
cd ..

cd carnivalpy
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

cd tfenrichment
./install.sh
cd ..

# cd carnival
# ./install.sh
# cd ..

# cd cellnopt
# ./install.sh
# cd ..

# cd export_solver_hdf5
# ./install.sh
# cd ..

cd ${CURRENT_DIR}
