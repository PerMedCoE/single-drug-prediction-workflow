#!/usr/bin/env bash

echo "Cleaning single drug prediction workflow required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../BuildingBlocks

cd carnival_feature_merger
./clean.sh
cd ..

cd carnival_gex_preprocess
./clean.sh
cd ..

cd carnivalpy
./clean.sh
cd ..

cd ml_jax_drug_prediction
./clean.sh
cd ..

cd omnipath
./clean.sh
cd ..

cd progeny
./clean.sh
cd ..

cd tfenrichment
./clean.sh
cd ..

# cd carnival
# ./clean.sh
# cd ..

# cd cellnopt
# ./clean.sh
# cd ..

# cd export_solver_hdf5
# ./clean.sh
# cd ..

cd ${CURRENT_DIR}
