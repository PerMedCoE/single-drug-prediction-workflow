#!/usr/bin/env bash

echo "Uninstalling single-drug-prediction required Building Blocks... Please wait..."

python3 -m pip uninstall -y Carnival_feature_merger-BB
python3 -m pip uninstall -y Carnival_gex_preprocess-BB
python3 -m pip uninstall -y CarnivalPy-BB
python3 -m pip uninstall -y ml_jax_drug_prediction-BB
python3 -m pip uninstall -y omnipath-BB
python3 -m pip uninstall -y progeny-BB
python3 -m pip uninstall -y tf_enrichment-BB
# python3 -m pip uninstall -y Carnival-BB
# python3 -m pip uninstall -y CellNOpt-BB
# python3 -m pip uninstall -y export_solver_hdf5-BB

echo "Uninstall finished"
