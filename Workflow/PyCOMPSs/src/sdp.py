#!/usr/bin/python3

import os
import shutil

# To set building block debug mode
from permedcoe import set_debug
# Import building block tasks
from Carnival_gex_preprocess_BB import preprocess as carnival_gex_preprocess
from progeny_BB import progeny
from omnipath_BB import omnipath
from tf_enrichment_BB import tf_enrichment
from CarnivalPy_BB import carnivalpy
from Carnival_feature_merger_BB import feature_merger as carnival_feature_merger
from ml_jax_drug_prediction_BB import ml as ml_jax_drug_prediction
# TODO: carnival_BB not used
# TODO: cellnopt_BB not used
# TODO: export_solver_hdf5 not used

# Import utils
from utils import parse_input_parameters

# PyCOMPSs imports
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

    # CHECK RESULTS FOLDERS
    if not os.path.exists(args.results_folder):
        os.makedirs(args.results_folder, exist_ok=True)
    else:
        # Do not continue if results folder exists
        print("ERROR: Results folder exists: %s" % args.results_folder)
        return
    if not os.path.exists(args.results_csvs_folder):
        os.makedirs(args.results_csvs_folder, exist_ok=True)
    else:
        # Do not continue if results csvs folder exists
        print("ERROR: Results CSVs folder exists: %s" % args.results_csvs_folder)
        return

    # Initial STEP: Read the list of cells to process
    with open(args.cell_list, 'r') as cell_list_fd:
        cells_raw = cell_list_fd.readlines()
        cells = [cell.strip() for cell in cells_raw]

    if args.gex:
        # 1st STEP: Remove the DATA. prefix from the columns
        gex_csv = args.gex
        if not os.path.exists(args.gex):
            carnival_gex_preprocess(input_file=args.gene_expression,
                                    output_file=gex_csv,
                                    col_genes="GENE_SYMBOLS",
                                    scale="FALSE",
                                    exclude_cols="GENE_title",
                                    tsv="TRUE",
                                    remove="DATA.",
                                    verbose="TRUE"
            )
    else:
        print("ERROR: Please provide --gene_expression or --gex")
        return

    if args.gex_n:
        # 2nd STEP: Do the same but this time scale also genes across cell lines
        gex_n_csv = args.gex_n
        if not os.path.exists(args.gex_n):
            carnival_gex_preprocess(input_file=gex_csv,
                                    output_file=gex_n_csv,
                                    col_genes="GENE_SYMBOLS",
                                    scale="TRUE",
                                    exclude_cols="GENE_title",
                                    tsv="FALSE",
                                    remove="DATA.",
                                    verbose="TRUE"
            )
    else:
        print("ERROR: Please provide --gene_expression or --gex_n")
        return

    if args.progeny:
        # 3rd STEP: Use the gene expression data to run Progeny and estimate pathway activities
        progeny_csv = args.progeny
        if not os.path.exists(args.progeny):
            progeny(input_file=gex_csv,
                    output_file=progeny_csv,
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
    else:
        print("WARNING: Found existing progeny: " + str(args.progeny))

    if args.network:
        # 4th STEP: Get SIF from omnipath
        network_csv = args.network
        if not os.path.exists(args.network):
            omnipath(debug=False,
                     output_file=network_csv
            )
    else:
        print("WARNING: Found existing network: " + str(args.network))

    for cell in cells:
        print("Processing %s" % cell)
        cell_result_folder = os.path.join(args.results_folder, cell)
        os.makedirs(cell_result_folder, exist_ok=True)

        # 5th STEP: Run CARNIVAL on the sample and extract the features
        cell_measurement_csv = os.path.join(cell_result_folder, "measurements.csv")
        tf_enrichment(input_file=gex_n_csv,
                      output_file=cell_measurement_csv,
                      tsv="FALSE",
                      weight_col=cell,
                      id_col="GENE_SYMBOLS",
                      minsize=10,
                      source="tf",
                      confidence="A,B,C",
                      verbose="TRUE",
                      pval_threshold=0.1,
                      export_carnival="TRUE"
        )

    compss_wait_on_file(network_csv)
    for cell in cells:
        cell_result_folder = os.path.join(args.results_folder, cell)
        cell_measurement_csv = os.path.join(cell_result_folder, "measurements.csv")
        shutil.copyfile(network_csv, cell_result_folder + "/network.csv")
        compss_wait_on_file(cell_measurement_csv)

    for cell in cells:
        # 6th STEP: Run CarnivalPy on the sample using cbc
        cell_result_folder = os.path.join(args.results_folder, cell)
        carnival_csv = os.path.join(cell_result_folder, "carnival.csv")
        carnivalpy(path=cell_result_folder,
                   penalty=0,
                   solver="cbc",
                   tol=0.1,
                   maxtime=500,
                   export=carnival_csv,
        )

    compss_wait_on_file(progeny_csv)
    for cell in cells:
        cell_result_folder = os.path.join(args.results_folder, cell)
        carnival_csv = os.path.join(cell_result_folder, "carnival.csv")
        compss_wait_on_file(carnival_csv)

    # 7th STEP: Merge the features into a single CSV, focus only on some specific genes
    cell_features_csv = os.path.join(args.results_csvs_folder, "cell_features.csv")
    carnival_feature_merger(input_dir=args.results_folder,
                            output_file=cell_features_csv,
                            feature_file=args.genelist,
                            merge_csv_file=progeny_csv,
                            merge_csv_index="sample",
                            merge_csv_prefix="F_"
    )

    # 8th STEP: Train a model to predict IC50 values for unknown cells (using the progeny+carnival features) and known drugs
    model_npz = os.path.join(args.results_csvs_folder, "model.npz")
    ml_jax_drug_prediction(input_file=args.jax_input,
                           output_file=model_npz,
                           drug_features=".none",
                           cell_features=cell_features_csv,
                           epochs="200",
                           adam_lr="0.1",
                           reg="0.001",
                           latent_size="10",
                           test_drugs="0.1",
                           test_cells="0.1"
    )
    compss_wait_on_file(model_npz)


if __name__ == "__main__":
    main()
