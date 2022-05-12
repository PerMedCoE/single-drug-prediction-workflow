import os
import argparse

##########################################
############ INPUT PARAMETERS ############
##########################################

def create_parser():
    """
    Create argument parser
    """
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("--cell_list", type=str,
                        help="Input list of cells (.txt)",
                        required=True)
    parser.add_argument("--gene_expression", type=str,
                        help="Gene expresion data from GDSC if not --gex and --gex_ne are provided (.txt)",
                        required=False)
    parser.add_argument("--gex", type=str,
                        help="Gene expression data (.csv).",
                        required=False)
    parser.add_argument("--gex_n", type=str,
                        help="Gene expresion data scale (.csv)",
                        required=False)
    parser.add_argument("--progeny", type=str,
                        help="Gene expression data for progeny (.csv)",
                        required=False)
    parser.add_argument("--network", type=str,
                        help="Network file (.csv)",
                        required=False)
    parser.add_argument("--genelist", type=str,
                        help="Gene list (.csv)",
                        required=True)
    parser.add_argument("--jax_input", type=str,
                        help="Jax input file",
                        required=True)
    parser.add_argument("--results_folder", type=str,
                        help="Results folder",
                        required=True)
    parser.add_argument("--results_csvs_folder", type=str,
                        help="Results CSVS folder",
                        required=True)
    return parser


def parse_input_parameters(show=True):
    """
    Parse input parameters
    """
    parser = create_parser()
    args = parser.parse_args()
    args.cell_list = os.path.realpath(args.cell_list)
    if args.gene_expression:
        args.gene_expression = os.path.realpath(args.gene_expression)
    if args.gex:
        args.gex = os.path.realpath(args.gex)
    if args.gex_n:
        args.gex_n = os.path.realpath(args.gex_n)
    args.progeny = os.path.realpath(args.progeny)
    args.network = os.path.realpath(args.network)
    args.results_folder = os.path.realpath(args.results_folder)
    args.results_csvs_folder = os.path.realpath(args.results_csvs_folder)
    if show:
        print()
        print(">>> WELCOME TO THE SINGLE DRUG PREDICTION WORKFLOW")
        print("> Parameters:")
        print("\t- List of cells: %s" % args.cell_list)
        if args.gene_expression:
            print("\t- Gene expression data from GDSC: %s" % args.gene_expression)
        if args.gex:
            print("\t- Gene expression data: %s" % args.gex)
        if args.gex_n:
            print("\t- Gene expression data scale: %s" % args.gex_n)
        print("\t- Gene expression data for progeny: %s" % args.progeny)
        print("\t- Network file: %s" % args.network)
        print("\t- Jax input file: %s" % args.jax_input)
        print("\t- Results folder: %s" % args.results_folder)
        print("\t- Results CSVs folder: %s" % args.results_csvs_folder)
        print("\n")
    return args


################################################
############ CHECK INPUT PARAMETERS ############
################################################

def check_input_parameters(args):
    """
    Check input parameters
    """
    if os.path.exists(args.results_folder):
        print("WARNING: the output folder already exists")
    else:
        os.makedirs(args.results_folder)
