# Step-by-step Installation guide

## Forword

This document aims to be a step-by-step handy guide to your first installation, configuration, and usage of FooDMe2. It does not replace the 
workflow documentation taht can be found following the link in the left navigation panel. Following this guide alone will only bring you as far
as setting up FooDMe2 for basic analyses on your system, do read the documentation to know how to properly use the workflow!

You can copy the code from each block and paste it in your shell to follow along. Hover over the circled numbers in the
code blocks to know more. You can also check the links to jump to the relevant documentation section.

Should anything be unclear or not work as expected, we ask for your understanding, maintaining this guide along the pipeline is considerable work
and we may have forgotten something, or some information may be outdated. Please tell us about it by submitting an issue in the FooDMe2 Github repository.

## Requirements

To follow along you will need:

- A UNIX system: any Linux distribution, MacOS, or Windows Subsystem for Linux.
- An working Internet connection, depending on your local setup the proxy settings.
- For the installation of Nextflow (compulsary) and Docker or Singularity/Apptainer (optional), you may need root (`sudo`) access.

We assume basic knowledge of the UNIX shell and the examples used will rely solely on the analysis of paired-end 
illumina data of meat (mammals and birds) samples as a practical example.

!!! Note

    We provide some degree of explanations for the installation of Nextflow and dependency managers here, 
    but we provide only very limited support for these.
    If you experience problems with the installation of nextflow and/or depedency managers, you should get in touch with your system 
    administrator or IT support. 


## Installation

### Installing Nextflow

The first step is to install the workflow manager Nextflow, which is going to take care of the workflow execution planning.

First check wether nextflow is installed on your system:

```sh
nextflow info
```


FooDMe should run with nextflow >= 24.10.5. If nextflow is installed with an older version run:

```sh
nextflow self-update
```

If nextflow is not installed, you will need to follow the [step-by-step instructions from the Nextflow documentation](https://www.nextflow.io/docs/latest/install.html#requirements). Note that you might need `sudo` rights!

### Dependency managers

Nexflow relies on dependency managers for the deployement of software dependencies in self contained environments or containers.
We always recommend that you run FooDMe2 with a container engine, such as **[Apptainer](https://apptainer.org/)**,
[Singularity](https://docs.sylabs.io/guides/latest/user-guide/index.html), or [Docker](https://www.docker.com/). 
Containers are faster to install and a more reliable way to ensure pipeline reproducibility over time. If containers
are not an option in your settings or you are experiencing troubles getting them to work, you can also use the Conda/Mamba package manager.

!!! Warning

    Conda environments, though usually easy to deploy are not guaranteed to reproducibly install all dependencies in the same versions.
    For this reason we recommend that FooDMe2 be run with a container-based manager such as Apptainer/Singularity or Docker.

    For a discussion on conda reproducibility, see [PMID29953862](https://pubmed.ncbi.nlm.nih.gov/29953862/).


=== "Apptainer"

    Check if installed:

    ```sh
    apptainer version
    ```

    If it is not installed, check the [official installation guide](https://apptainer.org/docs/admin/latest/installation.html#install-from-pre-built-packages), or choose another dependency manager.

=== "Singularity"

    Check if installed:

    ```sh
    singularity version
    ```

    If it is not installed, check the [official installation guide](https://docs.sylabs.io/guides/latest/user-guide/quick_start.html#download-singularityce-from-a-release), or choose another dependency manager.

=== "Docker"

    Check if installed:

    ```sh
    docker version
    ```

    Ensure that your user is part of the Docker group ('docker'), or that Docker is otherwise configured to allow you to execute it.

    If it is not installed, check the [official installation guide](https://docs.docker.com/engine/install/), or choose another manager.

=== "Conda"

    Check if installed:

    ```sh
    conda info
    ```

    If it is, great! Make sure it is configured properly to find and install the required packages. The `conda-forge` channel should be on top of 
    the channel list, followed by `bioconda` and channel priority should be set to `strict`.
    If it is not the case you can run:

    ```sh
    conda config --add channels bioconda
    conda config --add channels conda-forge
    conda config --set channel_priority strict
    ```

    If it is not installed, we recommend you to install the miniforge distribution following the [official guide](https://github.com/conda-forge/miniforge?tab=readme-ov-file#unix-like-platforms-macos-linux--wsl).
    When you are done, configure the channels as above. You will need to close you shell and reopen it after the installation for the `conda` command to be available.

### Nextflow configuration

In order to set some of the execution options for nextflow, like ressource allocation, dependency manager, or where to look for the locally installed databases, it is possible to configure Nextflow using one of these options:

- remote configuration (recommended) on the central `bio-raum/nf-configs` [github repository](https://github.com/bio-raum/nf-configs/tree/main), allows to fully pre-configure FooDMe2 in a way that is specific to your setting with a single `switch`.
- alternatively, one can use a local configuration file, although this limits the scope of possible configurations.
- no configuration (not recommended) is also possible, but you will have to manually provide parameters at each execution.

!!! Note

    Setting up a remote profile can take a little bit of time. If possible, plan ahead or use an alternative method in the meantime.

A few examples are given below; these can be extended as described in the [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html#configuration-file).

!!! Warning Distributed compute infrastructures

    All examples below assume that you run FooDMe2 on a local system (`executor = local`). 
    If you are planning to use this pipeline on a distributed compute system ("cluster"), or the cloud, 
    please refer to the [Nextflow documentation](https://www.nextflow.io/docs/latest/executor.html) to learn about alternative execution profiles. 
    An example for a Slurm cluster can be found [here](https://github.com/bio-raum/nf-configs/blob/main/conf/lsh.config).


=== "Remote"

    To upload your own configuration to the central `bio-raum/nf-configs` repository, [open an issue](https://github.com/bio-raum/nf-configs/issues/new) 
    with your planned configuration or directly send a pull-request. Alternatively, you can use on of the existing configuration if it fits your needs.

    !!! Warning

        Before using the examples below, make sure you set the resource limits of your compute environment (for example: 8 CPU cores, 30 Gb of Ram), 
        and adjust the paths that will be used to store the databases and dependencies on your system (`reference_base` and `cacheDir`).

        If you run on a local system with a single user, you may install the references into your home directory 
        (`$HOME`, `/home/youruser`). In a shared setting, particularly on distributed compute infrastructures, the references should be installed
        to a shared directory where all users can access them. 

    === "Apptainer"

        ```js title="remote.config"
        params {

            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        apptainer {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Singularity"

        ```js title="remote.config"
        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        singularity {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Docker"

        ```js title="remote.config"
        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        docker {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Conda"

        ```js title="remote.config"
        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        conda {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
            useMamba = true
        }
        ```

=== "Local"

    For the following it will be assumed that the configuration file is saved under `$HOME/nextflow` as `local.config`.

    !!! Warning {.callout-warning}
    Before using the examples below, make sure you modify the ressources (`max_cpus` and `max_memory`) so that they fit your system, 
    and adjust the paths that will be used to store the dependencies on your system (`cacheDir`).

    If you run on a local system with a single user, you may install the references into your home directory 
    (`$HOME`, `/home/youruser`). In a shared setting, particularly on distributed compute infrastructures, the references should be installed
    to a shared directory where all users can access them. 

    === "Apptainer"

        ```js title="local.config"

        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        apptainer {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Singularity"

        ```js title="local.config"

        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        singularity {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Docker"

        ```js title="local.config"
        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]

        }

        executor {
            queueSize=5
        }

        docker {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
        }
        ```

    === "Conda"

        ```js title="local.config"
        params {
            reference_base = "$HOME/nextflow/refs"
        }

        process {
            executor = 'local'
            resourceLimits = [ cpus: 8, memory: 30.GB, time: 72.h ]
        }

        executor {
            queueSize=5
        }

        conda {
            enabled = true
            cacheDir = "$HOME/nextflow/envs"
            useMamba = true
        }
        ```

### Installing the databases

Now that everything is installed and Nextflow is configured, we can install the databases that will be used for the analysis.
Several different databases for different sources such as [NCBI](https://ftp.ncbi.nlm.nih.gov/refseq/), [MIDORI](https://www.reference-midori.info/),
or [UNITE](https://unite.ut.ee/) can be installed automatically and used in a standardized way by FooDMe2. You can also provide your own dataases.

!!! Note

    You will see several parameters used in the commands below that are not immediatly important.
    These will be explained further in tis document or you can check them up in the online documentation.

=== "Remote"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile remote \                         # (1)
    -r 1.4.0 \
    --build_references \
    --run_name build \
    --skip_genbank                            # (2)
    ```
    1. `remote` is the name of your file in the `bio-raum/nf-configs` repository, without the `.config` extension.
    2. The Genbank core database can be installed by omitting this line, note that this will take up several hundred Gb and may require a substantial   amount of RAM to use. 


=== "Local"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -c $HOME/nextflow/local.config \          # (1)
    -r 1.4.0 \
    --build_references \
    --reference_base $HOME/nextflow/refs \    # (2)
    --run_name build \
    --skip_genbank                            # (3)
    ```
    1. This should be the path to your local configuration file
    2. This is the path to the folder to which the databases will be downloaded.
    3. The Genbank core database can be installed by omitting this line, note that this will take up several hundred Gb and may require a substantial amount of RAM to use.


After the command above ran, the `$HOME/nextflow/refs` folder should contain a folder called `foodme2` that itself contains several versioned databases.

### Testing the installation

When the database installation is finished, it is time for the last installation step before we dive in the analysis: testing the workflow.
Using the `test` profile as below will download a couple of sequencing data from ENA and run a standard analysis workflow on them.

=== "Remote"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile remote,test \                    # (1)
    -r 1.4.0 \
    --run_name test
    ```
    1. `remote` is the name of your file in the `bio-raum/nf-configs` repository, without the `.config` extension.

=== "Local"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile test
    -c $HOME/nextflow/local.config \          # (1)
    -r 1.4.0 \
    --reference_base $HOME/nextflow/refs \    # (2)
    --run_name test
    ```
    1. This should be the path to your local configuration file
    2. This is the path to the folder to which the databases were downloaded.

Nextflow should keep you informed of what is happening and after the workflow completed, you can check the `results` folder of
the current working directory to have a look at the results.

!!! tip

    Congrats! We are done with the installation, and hopefully everything looks good.
    Be sure to check the `results/reports` folder in particular contains the analysis result and useful QC metrics to evaluate your samples.
    If you encountered an Error, check if you scuccesfully performed all the steps above.
    Feel free to get in [touch for help troobleshooting](https://github.com/bio-raum/FooDMe2/issues/new?template=QUESTION.yml) 
    or to [report a problem](https://github.com/bio-raum/FooDMe2/issues/new?template=BUG-REPORT.yml).


## Workflow management

The next steps will push further into real-life usage. But first let's talk about a few important features of Nextflow.
In addition to running the workflow, Nextflow provides several utilities that are worth knowing (and using!).

### Clean temporary data

Each step of the workflow is executed in a folder generated and managed by Nextflow under the `work` folder in the current directory.
Nescessary files are **copied** to the `results` folder after workflow completion.
Although Nextflow relies a lot on symlinks, the `work` folder can quickly grow full of old and unesscessary data.

It is generally a <b>good practice</b> to keep separate folders for your various analyses so that you don't have to deal
with a balooning work directory. Still, at times you may want to clean up your pipeline runs:

- It is possible to simply delete the `work` folder manually using standard Unix commands.

  ```sh
  rm -rf ./work
  ```

- Nextflow also provides a [`clean`](https://www.nextflow.io/docs/latest/reference/cli.html#clean) utility that removes (most) temporary data, 
which you can incorporate in your workflow (see examples at the end of this document).

  ```sh
  nextflow clean
  ```

### Update workflows

Nextflow natively handles workflow versionning, to get the last version of the workflow from the online repository, run:

```sh
nextflow pull bio-raum/FooDMe2
```

### Versioning

FooDMe2 is semantically versioned, using a **MAJOR.MINOR.PATCH** model where:

- **MAJOR** is a major version, possibly introducing breaking changes
- **MINOR** is a minor version, introducing changes in workflows that are backwards compatible
- **PATCH** is mainly used for bugfixes and documentation

Each new **MAJOR** or **MINOR** release requires a re-verification of the analytics. **MAJOR** changes can potentially require a re-validation.

Nextflow enables you you decide which version of the pipeline you use by providing a release tag to the `-r` argument:

```sh
nextflow run bio-raum/FooDMe2 \
  -r 1.4.0
```

To use the latest release use `-r main`, and to use the lastest development version use `-r dev`.

!!! tip

    In order to ensure reproducibility, you **should** pin the workflow version for routine analysis.


!!! bug
    
    While we do our best to release bug-free versions, the `dev` branch is under active development and may contain bugs or incomplete features. 
    Use it at your own risk and report any issues you may encounter.

## Running an analysis

In order to run the workflow on your own data we will have to modify the above example by providing 
your data as input and an analysis method instead of the `test` profile.
All options are listed in the [online documentation](../user_doc/usage.md#command-line-option).

There are two ways to provide data, assuming that the read files are saved under `/home/user/metabarcoding/rawdata/` (replace `user` with your user name):

- Provide a sample-sheet linking sample names to the files as a tab-separated table (recommended):

  ```text title="samples.tsv"
  sample	fq1	fq2
  S1	~/home/user/metabarcoding/rawdata/S1_R1.fastq.gz	~/home/user/metabarcoding/rawdata/S1_R2.fastq.gz
  ```

!!! tip

    The `bio-raum` github page contains a workflow that can automatically generate a sample-sheet for you!
    See the example in the [next section](#creating-the-sample-sheet).

- Provide a path wildcard linking both read files. Note that you cannot provide sample names and FooDMe2 will not be able to deal with multi-lane libraries this way.

  ```sh
  '/home/user/metabarcoding/rawdata/*_R{1,2}.fastq.gz'
  ```

  Where the `*` represent the variable part of the paths (usually the sample name, Illumina sample and Lane numbers) and `{1,2}` the numbering of the read pairs.
  Variables will not be expanded in the wildcards so you have to provide a **full path** and use **single quotes**.

For example:

=== "Remote"

    === "Sample-sheet"

        ```sh
        nextflow run bio-raum/FooDMe2 \
        -profile remote \                                       # (1)
        -r 1.4.0 \                                              # (2)
        --run_name first_run \                                  # (3)
        --input $HOME/metabarcoding/rawdata/samples.tsv \       # (4)
        --primer_set 16S_ILM_ASU184_meat                        # (5)
        ```
        1. `remote` is the name of your file in the `bio-raum/nf-configs` repository, without the `.config` extension.
        2. Specifies the version of the FooDMe2 workflow to use.
        3. Sets the name of the run to "first_run". This name will be used to label the output files.
        4. Specifies the path to the sample-sheet containing the sample information.
        5. Specifies the standard method to use for the analysis. List the available methods with `--list_primers`.

    === "Wildcard"

        ```sh
        nextflow run bio-raum/FooDMe2 \
        -profile remote \                                               # (1)
        -r 1.4.0 \                                                      # (2)
        --run_name first_run \                                          # (3)
        --reads '/home/user/metabarcoding/rawdata/*_R{1,2}.fastq.gz' \  # (4)
        --primer_set 16S_ILM_ASU184_meat                                # (5)
        ```
        1. `remote` is the name of your file in the `bio-raum/nf-configs` repository, without the `.config` extension.
        2. Specifies the version of the FooDMe2 workflow to use.
        3. Sets the name of the run to "first_run". This name will be used to label the output files.
        4. Specifies the path to the paired read-files using a wildcard. Note the use of full path and single quotes!
        5. Specifies the standard method to use for the analysis. List the available methods with `--list_primers`

=== "Local"

    === "Sample-sheet"

        ```sh
        nextflow run bio-raum/FooDMe2 \
        -c $HOME/nextflow/local.config \                        # (1)
        -r 1.4.0 \                                              # (2)
        --run_name first_run \                                  # (3)
        --input $HOME/metabarcoding/rawdata/samples.tsv \       # (4)
        --primer_set 16S_ILM_ASU184_meat \                      # (5)
        --reference_base $HOME/nextflow/refs                    # (6)
        ```
        1. Path to your local configuration file.
        2. Specifies the version of the FooDMe2 workflow to use.
        3. Sets the name of the run to "first_run". This name will be used to label the output files.
        4. Specifies the path to the paired read-files using a wildcard. Note the use of single quotes!
        5. Specifies the standard method to use for the analysis. List the available methods with `--list_primers`
        6. Path to the folder you used to install the references.

    === "Wildcard"

        ```sh
        nextflow run bio-raum/FooDMe2 \
        -c $HOME/nextflow/local.config \                                # (1)
        -r 1.4.0 \                                                      # (2)
        --run_name first_run \                                          # (3)
        --reads '/home/user/metabarcoding/rawdata/*_R{1,2}.fastq.gz' \  # (4)
        --primer_set 16S_ILM_ASU184_meat \                              # (5)
        --reference_base $HOME/nextflow/refs                            # (6)
        ```
        1. Path to your local configuration file.
        2. Specifies the version of the FooDMe2 workflow to use.
        3. Sets the name of the run to "first_run". This name will be used to label the output files.
        4. Specifies the path to the paired read-files using a wildcard. Note the use of full path and single quotes!
        5. Specifies the standard method to use for the analysis. List the available methods with `--list_primers`
        6. Path to the folder you used to install the references.


!!! tip

    You can additionaly use the `--output` parameter to specify a path for the results folder. 
    For example adding the following parameter to the above command will write the results to 
    `$HOME/metabarcoding/results/first_run` instead of the `results` folder in the current directory.

    ```sh
    --output $HOME/metabarcoding/results/first_run
    ```

## Going further

### Automating things

In a diagnostic laboratory setting, it is usefull automate things as much as possible to improve reproducibility and save time.
It particular, it is possible to automate workflow execution using simple scripts.

In the following paragraphs we will set up a small script that allows to run the workflow on data present locally in a folder.
Bear in mind that this is just a simple example that can be modified and expanded as will.

#### Folder structure

We already established an folder structure throughout this document. We will add a `scripts` folder in which we will save scripts, and an `archive` folder
to store rawdata after analysis.

It should look like this:

=== "Remote"

    ```sh
    $HOME
    ./nextflow
        ./refs                  # (1)
        ./envs                  # (2)
    ./metabarcoding
        ./rawdata
        ./results
        ./scripts
        ./archive
    ```
    1. Should contain the `foodme2` folder in which the databases are saved
    2. Should already contain plenty of environments, images or containers

=== "Local"

    ```sh
    $HOME
    ./nextflow
        ./refs                  # (1)
        ./envs                  # (2)
        ./local.config
    ./metabarcoding
        ./rawdata
        ./results
        ./scripts
        ./archive
    ```
    1. Should contain the `foodme2` folder in which the databases are saved
    2. Should already contain plenty of environments, images or containers

The idea here is that:

-  users can copy their sequencing files into the `rawdata` folder
-  running the script will ensure the data is analysed and output into the `results` folder in meanigfully named subfolder
-  raw data files are moved in the `archive` folder
-  the `rawdata` folder is cleaned up and ready for new data 

#### Creating the sample-sheet

For this example we will use the `samplesheet` workflow from the `bio-raum` [Github collection](https://github.com/bio-raum/samplesheet).

The good news is that it is a standardized bio-raum workflow that works very similarly to FooDMe2. Assuming you adopted the folder structure above,
you can create the sample sheet in the raw data folder with:

=== "Remote"

    ```sh
    nextflow run bio-raum/samplesheet \
    -r 0.1 \
    -profile remote \
    --input $HOME/metabarcoding/rawdata \
    --outdir $HOME/metabarcoding/rawdata
    ```

    !!! Warning
        As before, make sure to use your own profile name!

=== "Local"

    ```sh
    nextflow run bio-raum/samplesheet \
    -r 0.1 \
    -c $HOME/nextflow/local.config \
    --input $HOME/metabarcoding/rawdata \
    --outdir $HOME/metabarcoding/rawdata
    ```

#### Output and run naming

We can automate run naming by using the execution date and a name for the run:

```sh
run_name="ilovefoodme"
run_id=$(date --iso-8601)                                    # (1)
mkdir -p $HOME/metabarcoding/results/${run_id}_${run_name}   # (2)
mkdir -p $HOME/metabarcoding/archive/${run_id}_${run_name}   # (2)
```
1. Generate today's date as ISO8601 format 'YYYY-MM-DD'
2. Create output folders with the date as filenames. The `-p` options allows reuse of existing folders.

!!! tip

    When writting a script, we can also use command line arguments to create the folder (and run) name:

    ```sh
    run_name="${1:-foodme2}"
    run_id=$(date --iso-8601)
    mkdir -p $HOME/metabarcoding/results/${run_id}_${run_name}
    mkdir -p $HOME/metabarcoding/archive/${run_id}_${run_name}
    ```

    The snippet above will take any variable given after the script call and use it as run name, reverting to `foodme2` as default.
    See it used in the next section.

#### Putting it together

We can now put everything together in a neat little script:

=== "Remote"

    ```sh title="run_foodme2.sh"
    #!/usr/bin/env bash  # (1)
    set -Eeuo pipefail  # (1)

    VERSION=1.4.0  # (2)

    # create samplesheet
    nextflow run bio-raum/samplesheet \
    -r 0.1 \
    -profile remote \  # (3)
    --input $HOME/metabarcoding/rawdata \
    --outdir $HOME/metabarcoding/rawdata \
    && nextflow clean

    # create output dirs
    run_name="${1:-foodme2}"
    run_id=$(date --iso-8601)
    mkdir -p $HOME/metabarcoding/results/${run_id}_${run_name}
    mkdir -p $HOME/metabarcoding/archive/${run_id}_${run_name}

    # run workflow
    nextflow run bio-raum/FooDMe2 \
    -profile remote \  # (3)
    -r $VERSION \
    --run_name ${run_id}_${run_name} \
    --input $HOME/metabarcoding/rawdata/samples.tsv \
    --primer_set 16S_ILM_ASU184_meat \
    --outdir $HOME/metabarcoding/results/${run_id}_${run_name} \
    && mv $HOME/metabarcoding/rawdata/* $HOME/metabarcoding/archive/${run_id}_${run_name} \  # (4)
    && nextflow clean  # (5)
    ```
    1. The first two lines are simply there to ensure that the correct shell is used and eventual errors are correctly reported.
    2. Putting the version at the top of the file so it is easy to trace.
    3. This should be the name of your remote configuration, without the `.config` extension.
    4. If nextflow finished succesfully, move all the content of the `rawdata` folder to a dated folder under `archive`.
    5. If nextflow finished succesfully, clean the work folder and cache.

=== "Local"

    ```sh title="run_foodme2.sh"
    #!/usr/bin/env bash  # (1)
    set -Eeuo pipefail  # (1)

    VERSION='1.4.0'  # (2)

    # create samplesheet
    nextflow run bio-raum/samplesheet \
    -r 0.1 \
    -c $HOME/nextflow/local.config \
    --input $HOME/metabarcoding/rawdata \
    --outdir $HOME/metabarcoding/rawdata \
    && nextflow clean

    # create output dirs
    run_name="${1:-foodme2}"
    run_id=$(date --iso-8601)
    mkdir -p $HOME/metabarcoding/results/${run_id}_${run_name}
    mkdir -p $HOME/metabarcoding/archive/${run_id}_${run_name}

    # run workflow
    nextflow run bio-raum/FooDMe2 \
    -c $HOME/nextflow/local.config \
    -r $VERSION \
    --run_name ${run_id}_${run_name} \
    --input $HOME/metabarcoding/rawdata/samples.tsv \
    --primer_set 16S_ILM_ASU184_meat \
    --reference_base $HOME/nextflow/refs \
    --outdir $HOME/metabarcoding/results/${run_id}_${run_name} \
    && mv $HOME/metabarcoding/rawdata/* $HOME/metabarcoding/archive/${run_id}_${run_name} \  # (3)
    && nextflow clean  # (4)
    ```
    1. The first two lines are simply there to ensure that the correct shell is used and eventual errors are correctly reported.
    2. Putting the version at the top of the file so it is easy to trace.
    3. If nextflow finished succesfully, move all the content of the `rawdata` folder to a dated folder under `archive`.
    4. If nextflow finished succesfully, clean the work folder and cache.


Now make sure that the script is executable and run it:

```sh
chmod +x $HOME/metabarcoding/scripts/run_foodme2.sh   # (1)
bash $HOME/metabarcoding/scripts/run_foodme2.sh run_name  # (2)
```
1. This ensures that the script is executable and is only required once.
2. `run_name` is optional here, but allows you to specify a custom name for your run.

### Validation

Like we saw for the test, FooDMe2 packs a profile for quick validation of the mammals and birds methods.
Details of the execution and results can be found in the [online documentation](../methods/amniotes_dobrovolny.md).

The validation can be executed with:

=== "Remote"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile remote,dobrovolny_benchmark \
    -r 1.4.0 \
    --run_name validation \
    --outdir $HOME/metabarcoding/results/validation
    ```

=== "Local"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile dobrovolny_benchmark \
    -c $HOME/nextflow/local.config \
    -r 1.4.0 \
    --run_name validation \
    --reference_base $HOME/nextflow/refs \
    --outdir $HOME/metabarcoding/results/validation
    ```

This will trigger the download of the dataset from the ENA and run FooDMe2 with the `16S_ILM_ASU184_meat` primer sets configuration.
In addtion to normal runs, a confusion matrix will be produced, allowing to calculate metrics on precision and accuracy for the analysis.

It is possible that the connection with ENA breaks down, blocking the execution of the workflow. If restarting the command doesnÄt work, try to download the dataset
manually from ENA under project number [PRJEB57117](https://www.ebi.ac.uk/ena/browser/view/PRJEB57117).

You can then start the validation manually by providing the read files to the workflow as explained above, and additionally providing the ground truth table
supplied with the workflow. You can see the table [here](https://raw.githubusercontent.com/bio-raum/FooDMe2/main/assets/validation/dobrovolny_benchmark_groundtruth.csv).
Either save the content to a new file or use:

```sh
wget -O $HOME/metabarcoding/dobrovolny_benchmark_groundtruth.csv https://raw.githubusercontent.com/bio-raum/FooDMe2/main/assets/validation/dobrovolny_benchmark_groundtruth.csv
```

You can then provide the ground-truth table to the workflow with:

=== "Remote"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -profile remote \  # (3)
    -r 1.4.0 \
    --run_name validation \
    --input $HOME/metabarcoding/rawdata/samples.tsv \
    --primer_set 16S_ILM_ASU184_meat \
    --outdir $HOME/metabarcoding/results/validation \
    --ground_truth $HOME/metabarcoding/dobrovolny_benchmark_groundtruth.csv
    ```

=== "Local"

    ```sh
    nextflow run bio-raum/FooDMe2 \
    -c $HOME/nextflow/local.config \
    -r 1.4.0 \
    --run_name validation \
    --input $HOME/metabarcoding/rawdata/samples.tsv \
    --primer_set 16S_ILM_ASU184_meat \
    --reference_base $HOME/nextflow/refs \
    --outdir $HOME/metabarcoding/results/validation \
    --ground_truth $HOME/metabarcoding/dobrovolny_benchmark_groundtruth.csv
    ```

You can also provide you own truth table to perform validation using your own samples. To know how check the "Benchmarking" part of the [Usage documentation](../user_doc/usage.md#benchmarking).

### Other methods

FooDMe2 is of course not limited to the birds and mammals method. 
Several other methods are currently being worked on and will be listed in the [documentation](../methods/methods.md) when available.

You can analyze any kind of metabarcoding data without a standard method, this will require that you modify
several analysis parameters. Which parameters can be accessed and what they do is described in the
[documentation](../user_doc/usage.md#advanced-options).

!!! tip
    If you followed until here, congratulations! You are all set to start using FooDMe2.
    In case of doubts, remember to read the documentation!
