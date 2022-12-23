#!/usr/bin/env bash

echo "Installing single-drug-prediction required Building Blocks... Please wait..."

python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=Carnival_feature_merger'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=Carnival_gex_preprocess'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=CarnivalPy'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=ml_jax_drug_prediction'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=omnipath'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=progeny'
python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=tf_enrichment'
# python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=Carnival'
# python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=CellNOpt'
# python3 -m pip install 'git+https://github.com/PerMedCoE/BuildingBlocks.git@main#subdirectory=export_solver_hdf5'

echo "single-drug-prediction required Building Blocks installed"
