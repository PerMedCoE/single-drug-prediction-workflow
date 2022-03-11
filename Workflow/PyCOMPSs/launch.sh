#!/usr/bin/env bash

export COMPSS_PYTHON_VERSION=3
module load COMPSs/Trunk # 2.10
module load singularity/3.5.2
module use /apps/modules/modulefiles/tools/COMPSs/libraries
module load permedcoe  # generic permedcoe package

unset PYTHONSTARTUP
unset PYTHONHOME

# Override the following for using different images, assets or data
export PERMEDCOE_IMAGES=${PERMEDCOE_IMAGES}  # Currently using the "permedcoe" deployed
export PERMEDCOE_ASSETS=${PERMEDCOE_ASSETS}  # Currently using the "permedcoe" deployed
data=$(pwd)/../../Resources/data/
results=$(pwd)/results/

# Set the tool internal parallelism and constraint
export COMPUTING_UNITS=1

if [ -d "$results" ]; then
    rm -rf $results;
fi
mkdir -p $results

enqueue_compss \
    --num_nodes=2 \
    --exec_time=20 \
    --worker_working_dir=$(pwd) \
    --log_level=off \
    --graph \
    --tracing \
    --python_interpreter=python3 \
    $(pwd)/src/uc2.py \
    ${data}/Sub_genes.csv \
    ${data}/rnaseq_fpkm_20191101.csv \
    ${data}/mutations_20191101.csv \
    ${data}/cnv_gistic_20191101.csv \
    ${data}/genes_druggable.csv \
    ${data}/genes_target.csv \
    ${results}


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch.sh
#
# Example:
#       ./launch.sh
######################################################
