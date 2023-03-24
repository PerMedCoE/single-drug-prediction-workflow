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

# Prepare working directories
CARNIVAL_GEX_PREPROCESS_WD="$(pwd)/carnival_gex_preprocess_wd"
mkdir ${CARNIVAL_GEX_PREPROCESS_WD}
PROGENY_WD="$(pwd)/progeny_wd"
mkdir ${PROGENY_WD}
OMNIPATH_WD="$(pwd)/omnipath_wd"
mkdir ${OMNIPATH_WD}
TF_ENRICHMENT_WD="$(pwd)/tf_enrichment_wd"
mkdir ${TF_ENRICHMENT_WD}
CARNIVALPY_WD="$(pwd)/carnivalpy_wd"
mkdir ${CARNIVALPY_WD}
CARNIVAL_FEATURE_MERGER_WD="$(pwd)/carnival_feature_merger_wd"
mkdir ${CARNIVAL_FEATURE_MERGER_WD}
ML_JAX_DRUG_PREDICTION_WD="$(pwd)/ml_jax_drug_prediction_wd"
mkdir ${ML_JAX_DRUG_PREDICTION_WD}

# Read the list of cells to process
readarray -t cells < ../Resources/data/cell_list_example.txt
echo "A total of ${#cells[@]} cells will be processed"

# Download gene expression data from GDSC. Remove the DATA. prefix from the columns
if [ ! -f ${tmpdir}/gex.csv ]; then
    wget -O ${tmpdir}/gdsc_gex.zip https://www.cancerrxgene.org/gdsc1000/GDSC1000_WebResources/Data/preprocessed/Cell_line_RMA_proc_basalExp.txt.zip
    unzip ${tmpdir}/gdsc_gex.zip -d ${tmpdir}/
    Carnival_gex_preprocess_BB \
        --mount_point ${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets:${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets \
        --tmpdir ${CARNIVAL_GEX_PREPROCESS_WD} \
        --input_file ${tmpdir}/Cell_line_RMA_proc_basalExp.txt \
        --col_genes GENE_SYMBOLS \
        --scale FALSE \
        --exclude_cols GENE_title \
        --tsv TRUE \
        --remove DATA. \
        --verbose TRUE \
        --output_file ${tmpdir}/gex.csv
fi

# Do the same but this time scale also genes across cell lines
if [ ! -f ${tmpdir}/gex_n.csv ]; then
    Carnival_gex_preprocess_BB \
        --mount_point ${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets:${CARNIVAL_GEX_PREPROCESS_ASSETS}/assets \
        --tmpdir ${CARNIVAL_GEX_PREPROCESS_WD} \
        --input_file ${tmpdir}/gex.csv \
        --col_genes GENE_SYMBOLS \
        --scale TRUE \
        --exclude_cols GENE_title \
        --tsv FALSE \
        --remove DATA. \
        --verbose TRUE \
        --output_file ${tmpdir}/gex_n.csv
fi

rm ${tmpdir}/Cell_line_RMA_proc_basalExp.txt

# Use the gene expression data to run Progeny and estimate pathway activities
if [ ! -f ${tmpdir}/progeny.csv ]; then
    # e.g progeny -i gex.csv Human 60 GENE_SYMBOLS TRUE GENE_title FALSE 3000 TRUE TRUE -o progeny11.csv
    # -i 'input_file', 'organism', 'ntop', 'col_genes', 'scale', 'exclude_cols', 'tsv', 'perms', 'zscore', 'verbose' -o ...
    progeny_BB \
        --mount_point ${PROGENY_ASSETS}/assets:${PROGENY_ASSETS}/assets \
        --tmpdir ${PROGENY_WD} \
        --input_file ${tmpdir}/gex.csv \
        --organism Human \
        --ntop 100 \
        --col_genes GENE_SYMBOLS \
        --scale TRUE \
        --exclude_cols GENE_title \
        --tsv FALSE \
        --perms 1 \
        --zscore FALSE \
        --verbose TRUE \
        --output_file ${tmpdir}/progeny.csv
fi

# Get SIF from omnipath
if [ ! -f ${tmpdir}/network.csv ]; then
    # Downloads the file
    omnipath_BB \
        --mount_point ${OMNIPATH_ASSETS}/assets:${OMNIPATH_ASSETS}/assets \
        --tmpdir ${OMNIPATH_WD} \
        --verbose false \
        --output_file ${tmpdir}/network.csv
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
            --mount_point ${TF_ENRICHMENT_ASSETS}/assets:${TF_ENRICHMENT_ASSETS}/assets \
            --tmpdir ${TF_ENRICHMENT_WD} \
            --input_file ${tmpdir}/gex_n.csv \
            --tsv FALSE \
            --weight_col $cell \
            --id_col GENE_SYMBOLS \
            --minsize 10 \
            --source tf \
            --confidence 'A,B,C' \
            --verbose TRUE \
            --pval_threshold 0.1 \
            --export_carnival TRUE \
            --output_file ${tmpdir}/${cell}/measurements.csv
        # Run CarnivalPy on the sample using locally installed gurobi in the current conda environment from which this script is executed. The environment is mounted
        # in the contaner and the LD_LIBRARY_PATH is changed accordingly so the lib can find the gurobi files. Note that Gurobi needs a valid license for this.
        CarnivalPy_BB \
            --mount_point ${CARNIVALPY_ASSETS}/assets:${CARNIVALPY_ASSETS}/assets \
            --tmpdir ${CARNIVALPY_WD} \
            --path ${tmpdir}/${cell}/ \
            --penalty 0 \
            --solver cbc \
            --tol 0.1 \
            --maxtime 500 \
            --export ${tmpdir}/${cell}/carnival.csv
        rm ${tmpdir}/${cell}/network.csv
    fi
done

# Merge the features into a single CSV, focus only on some specific genes
Carnival_feature_merger_BB \
    --mount_point ${CARNIVAL_FEATURE_MERGER_ASSETS}/assets:${CARNIVAL_FEATURE_MERGER_ASSETS}/assets \
    --tmpdir ${CARNIVAL_FEATURE_MERGER_WD} \
    --input_dir ${tmpdir} \
    --feature_file $(pwd)/../Resources/data/genelist.txt \
    --merge_csv_file ${tmpdir}/progeny.csv \
    --merge_csv_index sample \
    --merge_csv_prefix F_ \
    --output_file $(pwd)/cell_features.csv

# Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
ml_jax_drug_prediction_BB \
    --mount_point ${ML_JAX_DRUG_PREDICTION_ASSETS}/assets:${ML_JAX_DRUG_PREDICTION_ASSETS}/assets \
    --tmpdir ${ML_JAX_DRUG_PREDICTION_WD} \
    --input_file .x \
    --drug_features .none \
    --cell_features $(pwd)/cell_features.csv \
    --epochs 200 \
    --adam_lr 0.1 \
    --reg 0.001 \
    --latent_size 10 \
    --test_drugs 0.1 \
    --test_cells 0.1 \
    --output_file $(pwd)/model.npz

enable_pycompss
