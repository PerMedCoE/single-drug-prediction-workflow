#!/bin/bash

# Workflow but using Building Blocks
export PERMEDCOE_IMAGES="../../BuildingBlocks/Resources/images/"

# Disable PyCOMPSs if installed
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_DIR}/aux.sh
disable_pycompss

tmpdir="./tmp_BB"

if [ ! -d ${tmpdir} ]; then
    mkdir $tmpdir
fi

# Read the list of cells to process
readarray -t cells < ../Resources/data/cell_list_example.txt
echo "A total of ${#cells[@]} cells will be processed"

# Download gene expression data from GDSC. Remove the DATA. prefix from the columns
if [ ! -f ${tmpdir}/gex.csv ]; then
    wget -O ${tmpdir}/gdsc_gex.zip https://www.cancerrxgene.org/gdsc1000/GDSC1000_WebResources/Data/preprocessed/Cell_line_RMA_proc_basalExp.txt.zip
    unzip ${tmpdir}/gdsc_gex.zip -d ${tmpdir}/
    Carnival_gex_preprocess_BB -i ${tmpdir}/Cell_line_RMA_proc_basalExp.txt GENE_SYMBOLS FALSE GENE_title TRUE DATA. TRUE -o ${tmpdir}/gex.csv
fi

# Do the same but this time scale also genes across cell lines
if [ ! -f ${tmpdir}/gex_n.csv ]; then
    Carnival_gex_preprocess_BB -i ${tmpdir}/Cell_line_RMA_proc_basalExp.txt GENE_SYMBOLS FALSE GENE_title TRUE DATA. TRUE -o ${tmpdir}/gex_n.csv
fi

rm ${tmpdir}/Cell_line_RMA_proc_basalExp.txt

# Use the gene expression data to run Progeny and estimate pathway activities
if [ ! -f ${tmpdir}/progeny.csv ]; then
    # e.g progeny -i gex.csv Human 60 GENE_SYMBOLS TRUE GENE_title FALSE 3000 TRUE TRUE -o progeny11.csv
    # -i 'input_file', 'organism', 'ntop', 'col_genes', 'scale', 'exclude_cols', 'tsv', 'perms', 'zscore', 'verbose' -o ...
    progeny_BB -i ${tmpdir}/gex.csv Human 100 GENE_SYMBOLS TRUE GENE_title FALSE 1 FALSE TRUE -o ${tmpdir}/progeny.csv
fi

# Get SIF from omnipath
if [ ! -f ${tmpdir}/network.csv ]; then
    omnipath_BB -i false -o ${tmpdir}/network.csv  # Downloads the file
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
        tf_enrichment_BB -i ${tmpdir}/gex_n.csv $cell tf GENE_SYMBOLS FALSE 10 'A,B,C' TRUE -o ${tmpdir}/${cell}/measurements.csv
        # Run CarnivalPy on the sample using locally installed gurobi in the current conda environment from which this script is executed. The environment is mounted
        # in the contaner and the LD_LIBRARY_PATH is changed accordingly so the lib can find the gurobi files. Note that Gurobi needs a valid license for this.
        # CarnivalPy params are: <dir with CSVs> <solver name> <penalty> <mip tolerance> <maxtime> <R out file> <CSV out file>
        #singularity run -B $CONDA_PREFIX:/opt/env --env "LD_LIBRARY_PATH=/opt/env/" ${IMAGES_FOLDER}/carnivalpy.sif ${tmpdir}/${cell} gurobi_mip 0 0.1 300 ${tmpdir}/${cell}/out.rds ${tmpdir}/${cell}/carnival.csv
        CarnivalPy_BB -i ${tmpdir}/${cell} 0 cbc 0.1 500 -o ${tmpdir}/${cell}/carnival.csv
        rm ${tmpdir}/${cell}/network.csv
    fi
done

# Merge the features into a single CSV, focus only on some specific genes
Carnival_feature_merger_BB -i ${tmpdir} ${tmpdir}/progeny.csv ../Resources/data/genelist.txt sample F_ -o cell_features.csv

# Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
# singularity run --app ml tf-jax/tf-jax.sif --drug_features .none --cell_features cell_features.csv --test_cells 0.1 --reg 0.01 .x model.npz
ml_jax_drug_prediction_BB -i .x .none cell_features.csv 200 0.1 0.001 10 0.1 0.1 -o model.npz

enable_pycompss
