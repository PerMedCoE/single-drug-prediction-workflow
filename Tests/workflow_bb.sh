#!/bin/bash

# Workflow but using Building Blocks
export PERMEDCOE_IMAGES="../../BuildingBlocks/Resources/images/"

# Disable PyCOMPSs if installed
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_DIR}/aux.sh
disable_pycompss

tmpdir="${SCRIPT_DIR}/tmp_BB/"

if [ ! -d ${tmpdir} ]; then
    mkdir $tmpdir
fi

# Prepare assets mount points
CARNIVAL_GEX_PREPROCESS_ASSETS=$(python3 -c "import Carnival_gex_preprocess_BB; import os; print(os.path.dirname(Carnival_gex_preprocess_BB.__file__))")
PROGENY_ASSETS=$(python3 -c "import progeny_BB; import os; print(os.path.dirname(progeny_BB.__file__))")
OMNIPATH_ASSETS=$(python3 -c "import omnipath_BB; import os; print(os.path.dirname(omnipath_BB.__file__))")
TF_ENRICHMENT_ASSETS=$(python3 -c "import tf_enrichment_BB; import os; print(os.path.dirname(tf_enrichment_BB.__file__))")
CARNIVALPY_ASSETS=$(python3 -c "import CarnivalPy_BB; import os; print(os.path.dirname(CarnivalPy_BB.__file__))")
CARNIVAL_FEATURE_MERGER_ASSETS=$(python3 -c "import Carnival_feature_merger_BB; import os; print(os.path.dirname(Carnival_feature_merger_BB.__file__))")
ML_JAX_DRUG_PREDICTION_ASSETS=$(python3 -c "import ml_jax_drug_prediction_BB; import os; print(os.path.dirname(ml_jax_drug_prediction_BB.__file__))")

# Read the list of cells to process
readarray -t cells < ../Resources/data/cell_list_example.txt
echo "A total of ${#cells[@]} cells will be processed"

# Download gene expression data from GDSC. Remove the DATA. prefix from the columns
if [ ! -f ${tmpdir}/gex.csv ]; then
    wget -O ${tmpdir}/gdsc_gex.zip https://www.cancerrxgene.org/gdsc1000/GDSC1000_WebResources/Data/preprocessed/Cell_line_RMA_proc_basalExp.txt.zip
    unzip ${tmpdir}/gdsc_gex.zip -d ${tmpdir}/
    Carnival_gex_preprocess_BB \
        -i ${tmpdir}/Cell_line_RMA_proc_basalExp.txt GENE_SYMBOLS FALSE GENE_title TRUE DATA. TRUE \
        -o ${tmpdir}/gex.csv \
        --mount_point ${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets:${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets
fi

# Do the same but this time scale also genes across cell lines
if [ ! -f ${tmpdir}/gex_n.csv ]; then
    Carnival_gex_preprocess_BB \
        -i ${tmpdir}/gex.csv GENE_SYMBOLS TRUE GENE_title FALSE DATA. TRUE \
        -o ${tmpdir}/gex_n.csv \
        --mount_point ${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets:${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets
fi

rm ${tmpdir}/Cell_line_RMA_proc_basalExp.txt

# Use the gene expression data to run Progeny and estimate pathway activities
if [ ! -f ${tmpdir}/progeny.csv ]; then
    # e.g progeny -i gex.csv Human 60 GENE_SYMBOLS TRUE GENE_title FALSE 3000 TRUE TRUE -o progeny11.csv
    # -i 'input_file', 'organism', 'ntop', 'col_genes', 'scale', 'exclude_cols', 'tsv', 'perms', 'zscore', 'verbose' -o ...
    progeny_BB \
        -i ${tmpdir}/gex.csv Human 100 GENE_SYMBOLS TRUE GENE_title FALSE 1 FALSE TRUE \
        -o ${tmpdir}/progeny.csv \
        --mount_point ${PROGENY_ASSETS}/assets:${PROGENY_ASSETS}/assets
fi

# Get SIF from omnipath
if [ ! -f ${tmpdir}/network.csv ]; then
    omnipath_BB \
        -i false \
        -o ${tmpdir}/network.csv \
        --mount_point ${OMNIPATH_ASSETS}/assets:${OMNIPATH_ASSETS}/assets  # Downloads the file
fi

for cell in "${cells[@]}"
do
    echo "Processing $cell"
    if [ \( -d ${tmpdir}/${cell} \) -a \( -f ${tmpdir}/${cell}/carnival.csv \) ]; then
        echo "Solution for this sample already exists, skipping..."
    else
        if [ ! -d ${tmpdir}/${cell} ]; then
            mkdir ${tmpdir}/${cell}
        fi
        # Run CARNIVAL on the sample and extract the features
        cp ${tmpdir}/network.csv ${tmpdir}/${cell}/
        tf_enrichment_BB \
            -i ${tmpdir}/gex_n.csv FALSE $cell GENE_SYMBOLS 10 tf 'A,B,C' TRUE 0.1 TRUE \
            -o ${tmpdir}/${cell}/measurements.csv \
            --mount_point ${TF_ENRICHMENT_ASSETS}/assets:${TF_ENRICHMENT_ASSETS}/assets
        # Run CarnivalPy on the sample using locally installed gurobi in the current conda environment from which this script is executed. The environment is mounted
        # in the contaner and the LD_LIBRARY_PATH is changed accordingly so the lib can find the gurobi files. Note that Gurobi needs a valid license for this.
        CarnivalPy_BB \
            -i ${tmpdir}/${cell}/ 0 cbc 0.1 500 \
            -o ${tmpdir}/${cell}/carnival.csv \
            --mount_point ${CARNIVALPY_ASSETS}/assets:${CARNIVALPY_ASSETS}/assets
        rm ${tmpdir}/${cell}/network.csv
    fi
done

# Merge the features into a single CSV, focus only on some specific genes
Carnival_feature_merger_BB \
    -i ${tmpdir} $(pwd)/../Resources/data/genelist.txt ${tmpdir}/progeny.csv sample F_ \
    -o $(pwd)/cell_features.csv \
    --mount_point ${CARNIVAL_FEATURE_MERGER_ASSETS}/assets:${CARNIVAL_FEATURE_MERGER_ASSETS}/assets

# Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
ml_jax_drug_prediction_BB \
    -i .x .none $(pwd)/cell_features.csv 200 0.1 0.001 10 0.1 0.1 \
    -o $(pwd)/model.npz \
    --mount_point ${ML_JAX_DRUG_PREDICTION_ASSETS}/assets:${ML_JAX_DRUG_PREDICTION_ASSETS}/assets

enable_pycompss
