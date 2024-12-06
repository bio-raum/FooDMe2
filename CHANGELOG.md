## dev

### Features

- New argument `--reads` is mutually exclusive with `--input` and takes a glob path as argument. File names are parsed with the glob pattern and paired. This allows bypassing the need for a sample-sheet. It is not recommended way to provide input data but can be helpful in many cases.

  ```
  nextflow run bio-raum/FooDMe2 -profile singularity --reads '/path/to/reads/*_R{1,2}_001.fastq.gz'
  ```

- Add the parameter `--non_overlapping` to simply concatenate R1 and R2 reads instead of merging with an overlapping sequence. This is useful in case the amplicon or seuqnce length produce reads with no overlaps.

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

## 1.0.0

First release.

Re-implements FooDMe1 functions in a Nextflow pipeline. We designed FooDMe 2 to be more flexible and take away some of the complexity encountered in FooDMe 1. This not only concerns the installation procedure, which is vastly streamlined now, but also the process of configuring and starting individual analysis runs. The new implementation also maes it easier to deploy, maintain, and to add additonal functionalities in the future.
Check the [migration doc](https://bio-raum.github.io/FooDMe2/dev/help/migration/) for more info.

## 1.0.0.alpha.x

Pre-release for public test. Currently implements only 16S Illumina sequencing of Birds and Mammals prepared according to the Dobrovolny method.

Check the documentation for installation and usage.

This release is for test purposes, things will probably break and the documentation is lacking in many parts.
Should you encounter any problem or have questions, please raise an issue directly on the repository or contact the developpers directly.
