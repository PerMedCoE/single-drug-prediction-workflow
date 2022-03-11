#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export PERMEDCOE_IMAGES=$(realpath ${SCRIPT_DIR}/../../../BuildingBlocks/Resources/images/)/
if [ -z "${CONTAINER}" ] && [ "${CONTAINER}" == "True" ]
then
  export PERMEDCOE_ASSETS=$(realpath ${SCRIPT_DIR}/../../../BuildingBlocks/Resources/assets/)/
else
  export PERMEDCOE_ASSETS=/root/assets/
fi

data=$(realpath ${SCRIPT_DIR}/../../Resources/data/)/
results=${SCRIPT_DIR}/results/

if [ -d "$results" ]; then
    rm -rf $results;
fi

runcompss -d \
    --python_interpreter=python3 \
    ${SCRIPT_DIR}/src/sdp.py \
        --cell_list ${data}/cell_list_example.txt \
        --gene_expression ${data}/Cell_line_RMA_proc_basalExp.txt \
        --gex ${data}/gex.csv \
        --gex_n ${data}/gex_n.csv \
        --progeny ${data}/progeny.csv \
        --network ${data}/network.csv \
        --genelist ${data}/genelist.csv \
        --results_folder ${results}
