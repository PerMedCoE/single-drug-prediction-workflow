# Single drug prediction Workflow
## Table of Contents

- [Single drug prediction Workflow](#single-drug-prediction-workflow)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Contents](#contents)
    - [Building Blocks](#building-blocks)
    - [Workflows](#workflows)
    - [Resources](#resources)
    - [Tests](#tests)
  - [Instructions](#instructions)
    - [Local machine](#local-machine)
      - [Requirements](#requirements)
      - [Usage steps](#usage-steps)
    - [MareNostrum 4](#marenostrum-4)
      - [Requirements in MN4](#requirements-in-mn4)
      - [Usage steps in MN4](#usage-steps-in-mn4)
  - [License](#license)
  - [Contact](#contact)

## Description

Complementarily, the workflow supports single drug response predictions to provide a baseline prediction in cases where drug response information for a given drug and cell line is not available. As an input, the workflow needs basal gene expression data for a cell, the drug targets (they need to be known for untested drugs) and optionally CARNIVAL features (sub-network activity predicted with CARNIVAL building block) and predicts log(IC50) values. This workflow uses a custom matrix factorization approach built with Google JAX and trained with gradient descent. The workflow can be used both for training a model, and for predicting new drug responses.

The workflow uses the following building blocks in order of execution (for training a model):

1. Carnival_gex_preprocess
    - Preprocessed the basal gene expression data from GDSC. The input is a matrix of Gene x Sample expression data.
2. Progeny
    - Using the preprocessed data, it estimates pathway activities for each column in the data (for each sample). It returns a matrix of Pathways x Samples with activity values for 11 pathways.
3. Omnipath
    - It downloads latest Prior Knowledge Network of signalling. This building block can be ommited if there exists already a csv file with the network.
4. TF Enrichment
    - For each sample, transcription factor activities are estimated using Dorothea.
5. CarnivalPy
    - Using the TF activities estimated before, it runs Carnival to obtain a sub-network consistent with the TF activities (for each sample).
6. Carnival_feature_merger
    - Preselect a set of genes by the user (if specified) and merge the features with the basal gene expression data.
7. ML Jax Drug Prediction
    - Trains a model using the combined features to predict IC50 values from GDSC.

For details on individual workflow steps, please check the scripts that use each individual building block in the workflow [`GitHub repository`](<https://github.com/PerMedCoE/single_drug_prediction>)

## Contents

### Building Blocks

The ``BuildingBlocks`` folder contains the script to install the
Building Blocks used in the Single Drug Prediction Workflow.

### Workflows

The ``Workflow`` folder contains the workflows implementations.

Currently contains the implementation using PyCOMPSs.

### Resources

The ``Resources`` folder contains a small dataset for testing purposes.

### Tests

The ``Tests`` folder contains the scripts that run each Building Block
used in the workflow for a small dataset.
They can be executed individually *without PyCOMPSs installed* for testing
purposes.

## Instructions

### Local machine

This section explains the requirements and usage for the Single Drug Prediction Workflow in a laptop or desktop computer.

#### Requirements

- [`permedcoe`](https://github.com/PerMedCoE/permedcoe) package
- [PyCOMPSs](https://pycompss.readthedocs.io/en/stable/Sections/00_Quickstart.html)
- [Singularity](https://sylabs.io/guides/3.0/user-guide/installation.html)

#### Usage steps

1. Clone the `BuildingBlocks` repository

   ```bash
   git clone https://github.com/PerMedCoE/BuildingBlocks.git
   ```

2. Build the required Building Block images

   ```bash
   cd BuildingBlocks/Resources/images
   ## Download new BB singularity files
   wget https://github.com/saezlab/permedcoe/archive/refs/heads/master.zip
   unzip master.zip
   cd permedcoe-master/containers
   ## Build containers
   cd toolset
   sudo /usr/local/bin/singularity build toolset.sif toolset.singularity
   mv toolset.sif ../../../
   cd ..
   cd carnivalpy
   sudo /usr/local/bin/singularity build carnivalpy.sif carnivalpy.singularity
   mv carnivalpy.sif ../../../
   cd ..
   cd ml-jax
   sudo /usr/local/bin/singularity build ml-jax.sif ml-jax.singularity
   mv ml-jax.sif ../../../tf-jax.sif
   cd ..
   cd ../..
   ## Cleanup
   rm -rf permedcoe-master
   rm master.zip
   cd ../../..
   ```

   > :warning: **TIP**: The singularity containers **can to be downloaded** from: https://cloud.sylabs.io/library/pablormier


3. Clone this repository

   ```bash
   git clone https://github.com/PerMedCoE/single-drug-prediction.git
   ```

4. Install the `BuildingBlocks` package

   ```bash
   cd BuildingBlocks && ./install.sh && cd ..
   ```

5. Go to `Workflow/PyCOMPSs` folder

   ```bash
   cd Workflows/PyCOMPSs
   ```

6. Execute `./run.sh`

The execution is prepared to use the singularity images that **MUST** be placed into `BuildingBlocks/Resources/images` folder. If they are located in any other folder, please update the `run.sh` script setting the `PERMEDCOE_IMAGES` to the images folder.

> **TIP**: If you want to run the workflow with a different dataset, please update the `run.sh` script setting the `dataset` variable to the new dataset folder and their file names.

### MareNostrum 4

This section explains the requirements and usage for the Single Drug Prediction Workflow in the MareNostrum 4 supercomputer.

#### Requirements in MN4

- Access to MN4

All Building Blocks are already installed in MN4, and the Single Drug Prediction Workflow available.

#### Usage steps in MN4

1. Load the `COMPSs`, `Singularity` and `permedcoe` modules

   ```bash
   export COMPSS_PYTHON_VERSION=3
   module load COMPSs/3.1
   module load singularity/3.5.2
   module use /apps/modules/modulefiles/tools/COMPSs/libraries
   module load permedcoe
   ```

   > **TIP**: Include the loading into your `${HOME}/.bashrc` file to load it automatically on the session start.

   This commands will load COMPSs and the permedcoe package which provides all necessary dependencies, as well as the path to the singularity container images (`PERMEDCOE_IMAGES` environment variable) and testing dataset (`SINGLE_DRUG_PREDICTION_WORKFLOW_DATASET` environment variable).

2. Get a copy of the pilot workflow into your desired folder

   ```bash
   mkdir desired_folder
   cd desired_folder
   get_single_drug_prediction_workflow
   ```

3. Go to `Workflow/PyCOMPSs` folder

   ```bash
   cd Workflow/PyCOMPSs
   ```

4. Execute `./launch.sh`

This command will launch a job into the job queuing system (SLURM) requesting 2 nodes (one node acting half master and half worker, and other full worker node) for 20 minutes, and is prepared to use the singularity images that are already deployed in MN4 (located into the `PERMEDCOE_IMAGES` environment variable). It uses the dataset located into `../../Resources/data` folder.

> :warning: **TIP**: If you want to run the workflow with a different dataset, please edit the `launch.sh` script and define the appropriate dataset path.

After the execution, a `results` folder will be available with with Single Drug Prediction Workflow results.

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0)

## Contact

<https://permedcoe.eu/contact/>
