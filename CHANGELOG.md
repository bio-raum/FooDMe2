## dev

### Features

- The initial FASTP step (prior to primer trimming) now only perfoms adapter detection and metrics output. A new FASTP step was added after primer trimming which can be used to perform additonal trimming and filtering operations using the `--fastp_options` argument. The default value of this argument performs sliding window 3' quality trimming and filters reads absed on size (see usage documentation).
- The `--non_overlapping` option will now always try to merge reads first. Reads that cannot be merged with the provided rules (overlap size and number of mismatches for example) will be concatenated with an `N` stretch separating the forward and reverse sequences.

### Reporting

Improved reporting in the Excel table to help user identify potentially problematic assignements:
- Added reporting of the cluster sequence IDs making up a taxonomic call to the Excel report
- Added a worksheet to the Excel report detailling taxonmic call support for each cluster sequence

Improved QC reporting of the trimming and filtering steps:
- Added a tabset to the insert size histogram to show fragment size after primer trimming.
- The summary table, read quality plots, and filtering barchart now show the results of the newly added FASTP step.

### Bugs

- Fix a ZeroDivisionError in the report creation when attempting to analyse a sample with no reads.

## 1.1.0

### Features

- New argument `--reads` is mutually exclusive with `--input` and takes a glob path as argument. File names are parsed with the glob pattern and paired. This allows bypassing the need for a sample-sheet. It is not recommended way to provide input data but can be helpful in many cases.

  ```
  nextflow run bio-raum/FooDMe2 -profile singularity --reads '/path/to/reads/*_R{1,2}_001.fastq.gz'
  ```

- Add the parameter `--non_overlapping` to simply concatenate R1 and R2 reads instead of merging with an overlapping sequence. This is useful in case the amplicon or seuqnce length produce reads with no overlaps.
- Add the argument `--cutadapt_trim_flex` to attempt trimming on both 5' and 3' of reads but also keep reads where only a 5' trimming was performed.

### Reporting

- Complete rework of the HTML report: now uses a fully customized markdown template.
- Disabled hard filtering of samples based on read number after the primer trimming step. Samples will now soft fail in subsequent steps (e.g. clustering) or keep going to the end.
- All samples (including) failed samples now appear in the end report. Samples where no primmer trimming or clustering could be performed are marked as fail.
- Added read counts to the excel report

### Documentation

- Added ressource usage arguments to usage documentation
- Added some information on the `--reference_base` argument in the troobleshooting section
- Added information on the new `--reads` argument
- Added information on the use of a local configuration file
- Added information on BLAST, and clustering-specific arguments

### Bugs

- Fix conda environment definition path for module DADA2:RMCHIMERA that could lead to a failure to genreate the environment for conda user depending on the channel settings.
- Actually implements chimera removal skipping behaviour for `--remove_chimera false`
- Enforce similar filtering procedure for both VSEARCH and DADA2 workflows:
  - Filtering of sequences based on expected amplicon size (`amplicon_min_size` and `amplicon_max_size`) now correctly happens **after** read merging instead on being applied to the read length.
  - Filtering based on maxEE and maxNs now happens at the read level, prior to merging for VSEARCH
  - For both Workflows, read pairs are filtered baed on MaxEE and MaxNs, then merged, then merged pairs are filtered for expected size

## 1.0.0

First release.

Re-implements FooDMe1 functions in a Nextflow pipeline. We designed FooDMe 2 to be more flexible and take away some of the complexity encountered in FooDMe 1. This not only concerns the installation procedure, which is vastly streamlined now, but also the process of configuring and starting individual analysis runs. The new implementation also maes it easier to deploy, maintain, and to add additonal functionalities in the future.
Check the [migration doc](https://bio-raum.github.io/FooDMe2/dev/help/migration/) for more info.

## 1.0.0.alpha.x

Pre-release for public test. Currently implements only 16S Illumina sequencing of Birds and Mammals prepared according to the Dobrovolny method.

Check the documentation for installation and usage.

This release is for test purposes, things will probably break and the documentation is lacking in many parts.
Should you encounter any problem or have questions, please raise an issue directly on the repository or contact the developpers directly.
