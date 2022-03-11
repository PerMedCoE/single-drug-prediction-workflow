#!/usr/bin/env bash

echo "Installing covid-19-workflow required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../BuildingBlocks

cd carnival
./uninstall.sh
cd ..

cd carnival_feature_merger
./uninstall.sh
cd ..

cd carnival_gex_preprocess
./uninstall.sh
cd ..

cd carnivalpy
./uninstall.sh
cd ..

cd cellnopt
./uninstall.sh
cd ..

cd export_solver_hdf5
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

cd tfenrichment
./uninstall.sh
cd ..

cd ${CURRENT_DIR}
