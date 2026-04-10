# Running the pipeline offline

It is possible to run FooDMe2 offline on secured HPC or or disconnected systems.
This will require preparing all required components in advance on a connected system before trasnfering them  on the offline system.

See the [nf-core documentation for offline systems](https://nf-co.re/docs/usage/getting_started/offline).

Note that using FooDMe2 offline is only possible with a local configuration! It is highly recommended to use a container based dependency management system for offline use (Apptainer/Singularity, docker).

The easiest way to setup an offline system is:

## Transfer Nextflow offline

Follow this section from the nf-core documentation

## Transfer the pipleine code

1- Download a .tar.gz archive from a github release
2- Transfer to the offline system and extract
3- Transfer the cached containers from the online system in the offline system

## Transfer the reference databases

1- Build the reference databases on the online system
2- Transfer to the offline system

## Running the pipeline offline

1- Create a local configuration file and provide the path to the cached containers
2- Add `export NXF_OFFLINE='true'` to your `~/.bashrc` file or type in in the commnad line before running the pipeline
3- Run the pipeline by pointing nextflow to the `main.nf` file of the code and providing the path to the local config and reference base folder:

```sh
/path/to/nextflow run /path/to/FooDMe2/main.nf \
  -c /path/to/config.local \
  --reference_base /path/to/ref_base \
  --run_name name \
  --input path/to/samples.tsv \
  --primer_set 16S_ILM_ASU184_meat
```