#!/usr/bin/env bash

echo "Cleaning single-drug-prediction workflow required Building Blocks... Please wait..."

CURRENT_DIR=$(pwd)
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ../../../BuildingBlocks

cd Carnival_feature_merger
./clean.sh
cd ..

cd Carnival_gex_preprocess
./clean.sh
cd ..

cd CarnivalPy
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

cd tf_enrichment
./clean.sh
cd ..

# cd Carnival
# ./clean.sh
# cd ..

# cd CellNOpt
# ./clean.sh
# cd ..

# cd export_solver_hdf5
# ./clean.sh
# cd ..

cd ${CURRENT_DIR}
