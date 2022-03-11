#!/usr/bin/python3

import os
import csv

# To set building block debug mode
from permedcoe import set_debug
# Import building block tasks
from carnival_gex_preprocess_BB import preprocess as carnival_gex_preprocess
from progeny_BB import progeny
from omnipath_BB import omnipath
from tfenrichment_BB import tf_enrichment
from carnivalpy_BB import carnivalpy
from carnival_feature_merger_BB import feature_merger as carnival_feature_merger
from ml_jax_drug_prediction_BB import ml as ml_jax_drug_prediction
# TODO: carnival_BB not used
# TODO: cellnopt_BB not used
# TODO: export_solver_hdf5 not used

# Import utils
from utils import parse_input_parameters

# PyCOMPSs imports
from pycompss.api.api import compss_wait_on_directory
from pycompss.api.api import compss_wait_on_file
from pycompss.api.api import compss_barrier


def main():
    """
    MAIN CODE
    """
    set_debug(True)

    print("---------------------------------------")
    print("|   SINGLE DRUG PREDICTION Workflow   |")
    print("---------------------------------------")

    # GET INPUT PARAMETERS
    args = parse_input_parameters()

    # CHECK RESULTS FOLDER
    if not os.path.exists(args.results_folder):
        os.makedirs(args.results_folder, exist_ok=True)
    else:
        # Do not continue if results folder exists
        print("ERROR: Results folder exists: %s" % args.results_folder)
        return

    # Initial STEP: Read the list of cells to process
    with open(args.cell_list, 'r') as cell_list_fd:
        cells_raw = cell_list_fd.readlines()
        cells = [cell.strip() for cell in cells_raw]

    if (not args.gex or not os.path.exists(args.gex)) and \
        args.gene_expression:
        # 1st STEP: Remove the DATA. prefix from the columns
        if not os.path.exists(args.gex):
            gex_csv = os.path.join(args.results_folder, "gex.csv")
        else:
            gex_csv = args.gex
        carnival_gex_preprocess(input_file=args.gene_expression,
                                output_file=gex_csv,
                                col_genes="GENE_SYMBOLS",
                                scale="GENE_title",
                                exclude_cols="FALSE",
                                tsv="TRUE",
                                remove="TRUE",
                                verbose="DATA.")
    else:
        print("ERROR: Please provide --gene_expression or --gex")
        return

    if (not args.gex_n or not os.path.exists(args.gex_n)) and \
        args.gene_expression:
        # 2nd STEP: Do the same but this time scale also genes across cell lines
        if not os.path.exists(args.gex_n):
            gex_n_csv = os.path.join(args.results_folder, "gex_n.csv")
        else:
            gex_n_csv = args.gex_n
        carnival_gex_preprocess(input_file=args.gene_expression,
                                output_file=gex_n_csv,
                                col_genes="GENE_SYMBOLS",
                                scale="GENE_title",
                                exclude_cols="FALSE",
                                tsv="TRUE",
                                remove="TRUE",
                                verbose="DATA.")
    else:
        print("ERROR: Please provide --gene_expression or --gex_n")
        return

    if args.progeny and os.path.exists(args.progeny):
        # 3rd STEP: Use the gene expression data to run Progeny and estimate pathway activities
        if os.path.exists(args.progeny):
            progeny_csv = os.path.join(args.results_folder, "progeny.csv")
        else:
            progeny_csv = args.progeny
        progeny(input_file=gex_csv,
                ouptut_file=progeny_csv,
                organism="Human",
                ntop="100",
                col_genes="GENE_SYMBOLS",
                scale="TRUE",
                exclude_cols="GENE_title",
                tsv="FALSE",
                perms="1",
                zscore="FALSE",
                verbose="TRUE"
        )

    if args.network and os.path.exists(args.network):
        # 4th STEP: Get SIF from omnipath
        if os.path.exists(args.network):
            network_csv = os.path.join(args.results_folder, "network.csv")
        else:
            network_csv = args.network
        # TODO: Could omnipath accept files instead of a folder?
        input_file = "TO_BE_DEFINED"
        omnipath(input_file=input_file,  # TODO: MISSING VALUE
                 output_file=network_csv
        )

    for cell in cells:
        print("Processing %s" % cell)

        cell_result_folder = os.path.join(args.results_folder, cell)
        os.makedirs(cell_result_folder, exist_ok=True)

        # 5th STEP: Run CARNIVAL on the sample and extract the features
        cell_measurement_csv = os.path.join(cell_result_folder, "measurements.csv")
        tf_enrichment(input_file=gex_n_csv,
                      output_file=cell_measurement_csv,
                      weight_col=cell,
                      source="GENE_SYMBOLS",
                      id_col="tf",
                      tsv="FALSE",
                      minsize="10",
                      confidence="A,B,C",
                      verbose="TRUE"
        )

        # 6th STEP: Run CarnivalPy on the sample using gurobi
        # TODO: carnivalpy does not have the same parameters!
        carnivalpy(path="path",        # TODO: MISSING VALUE
                   penalty="penalty",  # TODO: MISSING VALUE
                   solver="solver"     # TODO: MISSING VALUE
        )
        """
        # Sample call using singularity directly.
        singularity run -B $CONDA_PREFIX:/opt/env
                        --env "LD_LIBRARY_PATH=/opt/env/"
                        carnivalpy/carnivalpy.sif
                        ${tmpdir}/${cell}
                        gurobi_mip
                        0
                        0.1
                        300
                        ${tmpdir}/${cell}/out.rds
                        ${tmpdir}/${cell}/carnival.csv
        """

    # 7th STEP: Merge the features into a single CSV, focus only on some specific genes
    cell_features = "cell_features.csv"
    carnival_feature_merger(input_dir=args.results_folder,
                            output_folder=cell_features,
                            feature_file=progeny_csv,
                            merge_csv_file=args.genelist,
                            merge_csv_index="",  # TODO: MISSING VALUE
                            merge_csv_prefix=""  # TODO: MISSING VALUE
    )

    # 8th STEP: Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
    ml_jax_drug_prediction(input_file=".x",  # TODO: MISSING VALUE
                           output_file="model.npz",
                           drug_features=".none",
                           cell_features=cell_features,
                           epochs="200",
                           adam_lr="0.1",
                           reg="0.001",
                           latent_size="10",
                           test_drugs="0.1",
                           test_cells="0.1"
    )
    compss_barrier()



if __name__ == "__main__":
    main()
