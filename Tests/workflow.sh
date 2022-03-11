#!/bin/bash

# Workflow example for building a predictive model of IC50 from cell features
# using CARNIVAL

tmpdir="data/tmp"

if [ ! -d ${tmpdir} ]; then   
    mkdir $tmpdir
fi

# Read the list of cells to process
readarray -t cells < data/cell_list_example.txt
echo "A total of ${#cells[@]} cells will be processed"

# Download gene expression data from GDSC. Remove the DATA. prefix from the columns
if [ ! -f ${tmpdir}/gex.csv ]; then
    singularity run --app preprocess toolset/toolset.sif --tsv TRUE https://www.cancerrxgene.org/gdsc1000/GDSC1000_WebResources/Data/preprocessed/Cell_line_RMA_proc_basalExp.txt.zip --remove DATA. ${tmpdir}/gex.csv
fi

# Do the same but this time scale also genes across cell lines
if [ ! -f ${tmpdir}/gex_n.csv ]; then
    singularity run --app preprocess toolset/toolset.sif --tsv FALSE --scale TRUE ${tmpdir}/gex.csv ${tmpdir}/gex_n.csv
fi

# Use the gene expression data to run Progeny and estimate pathway activities
if [ ! -f ${tmpdir}/progeny.csv ]; then
    singularity run --app progeny toolset/toolset.sif --ntop 100 --perms 1 --zscore FALSE --verbose TRUE ${tmpdir}/gex.csv ${tmpdir}/progeny.csv
fi

# Get SIF from omnipath
if [ ! -f ${tmpdir}/network.csv ]; then
    singularity run --app omnipath toolset/toolset.sif ${tmpdir}/network.csv
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
        singularity run --app tfenrichment toolset/toolset.sif --export_carnival TRUE --id_col GENE_SYMBOLS --weight_col $cell ${tmpdir}/gex_n.csv ${tmpdir}/${cell}/measurements.csv
        # Run CarnivalPy on the sample using locally installed gurobi in the current conda environment from which this script is executed. The environment is mounted
        # in the contaner and the LD_LIBRARY_PATH is changed accordingly so the lib can find the gurobi files. Note that Gurobi needs a valid license for this.        
        # CarnivalPy params are: <dir with CSVs> <solver name> <penalty> <mip tolerance> <maxtime> <R out file> <CSV out file>
        singularity run -B $CONDA_PREFIX:/opt/env --env "LD_LIBRARY_PATH=/opt/env/" carnivalpy/carnivalpy.sif ${tmpdir}/${cell} gurobi_mip 0 0.1 300 ${tmpdir}/${cell}/out.rds ${tmpdir}/${cell}/carnival.csv
        rm ${tmpdir}/${cell}/network.csv
        rm ${tmpdir}/${cell}/out.rds
    fi
done

# Merge the features into a single CSV, focus only on some specific genes
singularity run --app feature_merger carnivalpy/carnivalpy.sif --merge_csv_file ${tmpdir}/progeny.csv --feature_file data/genelist.txt ${tmpdir} cell_features.csv

# Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
singularity run --app ml tf-jax/tf-jax.sif --drug_features .none --cell_features cell_features.csv --test_cells 0.1 --reg 0.01 .x model.npz





