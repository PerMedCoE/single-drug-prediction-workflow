#!/usr/bin/env bash

echo "Downloading single-drug-prediction-workflow required containers... Please wait..."

CURRENT_DIR=$(pwd)
CONTAINER_FOLDER=$(pwd)/single-drug-prediction-workflow-containers
mkdir -p ${CONTAINER_FOLDER}
cd ${CONTAINER_FOLDER}

apptainer pull toolset.sif docker://ghcr.io/permedcoe/toolset:latest
apptainer pull ml_jax.sif docker://ghcr.io/permedcoe/ml_jax:latest
apptainer pull carnivalpy.sif docker://ghcr.io/permedcoe/carnivalpy:latest

cd ${CURRENT_DIR}

echo "single-drug-prediction-workflow required containers downloaded"
echo ""
echo "Containers stored in: ${CONTAINER_FOLDER}"
echo ""
echo "Please, don't forget to run:"
echo "    export PERMEDCOE_IMAGES=${CONTAINER_FOLDER}"
echo "Before running the workflow."
echo ""
