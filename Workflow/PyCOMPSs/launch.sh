#!/usr/bin/env bash

export COMPSS_PYTHON_VERSION=3
module load COMPSs/3.0
module load singularity/3.5.2
module use /apps/modules/modulefiles/tools/COMPSs/libraries
module load permedcoe  # generic permedcoe package

unset PYTHONSTARTUP
unset PYTHONHOME

# Override the following for using different images, assets or data
export PERMEDCOE_IMAGES=${PERMEDCOE_IMAGES}  # Currently using the "permedcoe" deployed
data=$(pwd)/../../Resources/data/
results=$(pwd)/results/
results_csvs=$(pwd)/results_csvs/

# Set the tool internal parallelism and constraint
export COMPUTING_UNITS=1

if [ -d "$results" ]; then
    rm -rf $results;
fi
if [ -d "$results_csvs" ]; then
    rm -rf $results_csvs
fi
mkdir $results_csvs

enqueue_compss \
    --num_nodes=2 \
    --exec_time=30 \
    --worker_working_dir=$(pwd) \
    --log_level=off \
    --graph \
    --tracing \
    --python_interpreter=python3 \
    $(pwd)/src/sdp.py \
        --cell_list ${data}/cell_list_example.txt \
        --gene_expression ${data}/Cell_line_RMA_proc_basalExp.txt \
        --gex ${data}/gex.csv \
        --gex_n ${data}/gex_n.csv \
        --progeny ${data}/progeny.csv \
        --network ${data}/network.csv \
        --genelist ${results_csvs}/genelist.csv \
        --jax_input ${data}/IC50 \
        --results_folder ${results} \
        --results_csvs_folder ${results_csvs}


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch.sh
#
# Example:
#       ./launch.sh
######################################################
