## 1.4.0

### **!! Breaking change !!**

Database version was upgraded to 1.4.

This requires a new installation of the databases. The MIDORI databases were upgraded to GB267 (from GB259).
The other databases were not modified, and can therefore be symlinked instead of a complete reinstallation (especially core_nt).

### Methods

Added following methods (experimental - validation pending):

- 16S metabarcoding of insects (Hillinger et al. 2023)
- 16S metabarcoding of fish (Dobrovolny et al. 2019; using ASU L 00.00-184 )
- COI metabarcoding of fish (Guenther et al.)
- COI metabarcoding of insects (Park et al. 2001)
- CYTB metabarcoding of fish (German ASU L 10.00-12)

Each of these primer system has a method for Illumina, IonTorrent, and Oxford Nanopore. Check the doc to learn more.

### Features

- Improved BLAST module performance by switching to serial mode.
- Reworked how the BLAST search is configured and processed for non-ovelapping data: (1) halving the value of the required query coverage for the BLAST search, (2) matching groups of BLAST hits that are on the same strand and within the span of the amplicon size (as defined by the parameters above), (3) recalculating BLAST metrics (score, bitscore, evalue, etc...) on the merged HSPs and (4) producing a consolidated BLAST report. Note that this comes with some caveats and you should consider such experimental design very carefully.
- Sequences from the MIDORI Database now retain their Genbank accession number as `GENBANKACC_COUNTER` (starting with database version 1.4)

### Bugs

- Skip SSL verification for hard-coded databses downloads as some certificates are regularly outdated.
- Proxy options can be passed on from the user's config for file staging using `HTTPS_PROXY`.
- BLAST search now correctly takes the minimal query coverage argument `--blast_qcov` into account.
- Fixed a crash occuring when trying to analyze non-overlapping data with DADA2.
- Fixed a crash occuring when trying to skip chimera detection with DADA2.
- It is now possible to use the `genbank` and `ncbi_its` databases, as well as any database without fasta file available.

## 1.3.0

### Features

- Add experimental support for ONT and IonTorrent data (not fully documented yet, check the `--help`)
- Improved error handling in the DADA2 workflow to prevent pipeline crash when few reads are available for error estimation.
- Added metadata to primer sets to simplify search
- Add nf-schema and nf-validation support: including a new improved `--help` and argument summary.
- Added new primer set profiles, these are mostly untested for now. Validation will follow in future releases.

### Reporting

- Now collecting QC filtering stats in the DADA worflow (max EE and max Ns).
- Now writting estimated error rates, obeerved transisitons, and various sequence tables in the DADA2 workflowto the results directory.
- .RDS files are not written to the results directory anymore.
- Settings used for the analysis are now part of the HTML report.
- Sample sheet is now stored in the results folder for documentation purposes

### Documentation

- Improved description of `--non_overlapping` to correctly reflect that it always tries to merge reads before joining.
- Improved output description.

### Bugs

- Fixed an error with dada2 filtering not seeing the correct trimming parameters
- Fixed an error with dada2 processing not all writing to the correct output folder
- Fixed several errors with processes not requesting the correct system resources

## 1.2.0

### Features

- The initial FASTP step (prior to primer trimming) now only perfoms adapter detection and metrics output. A new FASTP step was added after primer trimming which can be used to perform additonal trimming and filtering operations using the `--fastp_options` argument. The default value of this argument performs sliding window 3' quality trimming and filters reads absed on size (see usage documentation).
- The `--non_overlapping` option will now always try to merge reads first. Reads that cannot be merged with the provided rules (overlap size and number of mismatches for example) will be concatenated with an `N` stretch separating the forward and reverse sequences.
- Conda users will now see a message warning against conda usage in production.


### Reporting

- Improved reporting in the Excel table to help user identify potentially problematic assignements:

  - Added reporting of the cluster sequence IDs making up a taxonomic call to the Excel report
  - Added a worksheet to the Excel report detailling taxonmic call support for each cluster sequence

- Improved QC reporting of the trimming and filtering steps:

  - Added a tabset to the insert size histogram to show fragment size after primer trimming.
  - The summary table, read quality plots, and filtering barchart now show the results of the newly added FASTP step.

- Reports files should be more systematically sorted.

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
