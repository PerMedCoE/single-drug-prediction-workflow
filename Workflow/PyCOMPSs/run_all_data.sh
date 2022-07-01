#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export PERMEDCOE_IMAGES=$(realpath ${SCRIPT_DIR}/../../../BuildingBlocks/Resources/images/)/

data=$(realpath ${SCRIPT_DIR}/../../Resources/data/)/
results=${SCRIPT_DIR}/results/
results_csvs=${SCRIPT_DIR}/results_csvs/

if [ -d "$results" ]; then
    rm -rf $results
fi
if [ -d "$results_csvs" ]; then
    rm -rf $results_csvs
fi
touch dummy.x


runcompss -g -t \
    --python_interpreter=python3 \
    ${SCRIPT_DIR}/src/sdp.py \
        --cell_list ${data}/cell_list_example.txt \
        --gene_expression ${data}/Cell_line_RMA_proc_basalExp.txt \
        --gex ${results_csvs}/gex.csv \
        --gex_n ${results_csvs}/gex_n.csv \
        --progeny ${results_csvs}/progeny.csv \
        --network ${results_csvs}/network.csv \
        --genelist ${results_csvs}/genelist.csv \
        --jax_input dummy.x \
        --results_folder ${results} \
        --results_csvs_folder ${results_csvs}
