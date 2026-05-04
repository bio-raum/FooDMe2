# Standardized methods

FooDMe2 aims at offering **validated** pre-configured standard methods that can be chosen with a single parameter.
This is implemented with the `--primer_set` argument.

If you would like to see your methods incorporated in FooDMe2 standard set, please get in touch with us!
Likewise, if you find one of the method underperforming on your datasets, please contact us.

Please note that these preconfigured methods may make big assumptions on the sequencing raw data.

**You should always verify these methods with your own laboratory workflows before using them in a diagnostic setting!**

!!! Warning Illumina methods

    Please note that Illumina standard methods were developed with a specific sequencing length in mind, usually the optimal one for this specific barcode.
    Using different sequencing length (e.g. 2x150bp instead of 2x250bp) may require to reexamin some of the parameters, especialy those related to primer timming, read-overlap, amplicon length or BLAST filtering. See corresponding section below for an example of such method adaptation.


## Implemented methods

### :cow: :turkey: Mammals and birds

* 16S metabarcoding of mammals and birds (German ASU L 00.00-184)

### :cockroach: Insects

* 16S metabarcoding of insects (Hillinger et al. 2023)
* COI metabarcoding of insects (Park et al. 2001)

### :fish: Fishes

* 16S metabarcoding of fish (Dobrovolny et al. 2019; using ASU L 00.00-184 )
* COI metabarcoding of fish (Guenther et al. 2017)
* CYTB metabarcoding of fish (German ASU L 10.00-12)

### :seedling: Plants

* rbcL mmetabarcoding of plants (Little 2013)
* trnL metabarcoding of plants (Taberlet et al. 1991)
* ITS2 metabarcoding of plants (unpublished)

## How are standard methods developed?

As far as validation datasets (published or ringtrial data) are available to us, the methods are validated according to the guidelines of the german Bundesamt für Verbraucherschutz und Lebensmittelsicherheit (Federal Office for Consummer Protection and Food Safety), available [here](https://www.bvl.bund.de/SharedDocs/Downloads/07_Untersuchungen/Sequenzdatenanalyse-Tierartendifferenzierung-DNAmetabarcoding.html?nn=11009496).
After succesful validation, a summary of the performance metrics will be published alongside the method on the pages linked above.

When no proper validation dataset is available to us, we test the methods as far as possible on avialiable datasets that were generated in various laboratories and kindly provided to us.

Some of the parameters are set in standardized manner, you may want to adapt them to your specific worklfows:

* `max_expected_errors` is set to 2.5% of the maximum amplicon length for Illumina. However since Illumina sequencing ofter uses 2x150bp sequencing, this parameter is capped to `6` for long amplicons. For IonTorrent and Oxford Nanopore methods, this parameter is set to 5% of the maximum amplicon size, to account for higher error rate with these technologies.
* `min_amplicon_size` and `max_amplicon_size` are set based on *in silico* predicted amplicon size distribution calculated by our companion workflow [BarBeQuE](https://github.com/bio-raum/BarBeQuE). To set this range, we start with the Mean +/- 2 std.dev of the amplicon size. This range is in most cases then enlarged to account for phylogentic variability and avoid exclusion of entire groups of species.

## Modifying standard methods

### Using the command line

Generally, any parameter set in the standard method can be changed by setting the paramameter through the command line. 
For example to use the standard 16 Illumina mehtod with a stricter BLAST consensus one could use:

```sh
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \
  --input samples.tsv \
  --primer_set 16S_ILM_ASU184_meat
  --blast_min_consensus 0.8  # (1)!
```

1. This will set the `blast_min_consensus` parameter to 0.8 instead of the 0.51 from the standard method configuration.

### Using a configuration file

Using a JSON or YAML file is also possible. Copy the standard method configuration in a JSON file and modify it according to the [custom primer documentation section](../user_doc/custom_primers.md/#from-a-parameter-file)

### Adapting an Illumina method for another sequencing length

Adapting an Illumina standard method for another seuqencing length might require to modify several parameters and should be thoroughly validated before used in routine work. 

Here is a practical example for adapting the [COI insects method](https://github.com/bio-raum/FooDMe2/blob/main/conf/primers/COI_ILM_park_insects.config) (developed for 2x250bp) to sequencing with 2x150bp sequencing.

This method was developed with 2x250bp in mind, because the amplicons have a quite stable read length of 395bp to 405bp throughout the insects taxonomy.
This allows merging R1 and R2 sequences relatively easily and working on full sequences for the BLAST search. If for any readon one decides to work with paired 150bp sequences,
this has the dramatic effect of not allowing an overlap-based read merging, which in turns has several effects on downstream parameters choices.

- First thing to check in such a case in wether primers should be cut on the 3' end of the reads. For this method it was not the case with 2x250bp it it won't be either with shorter sequences, meaning we can igner the `cutadapt_trim_3p` and `cutadpat_trim_flex` parameters.

- With 150bp sequences for ~400bp amplicons we do not expect read to overlap anymore, so we need to pass the `non_overlapping` argument. This leads to R1 aand R2 being concatenated with an "N" linker sequence.

- Since we now do not merge reads based on overlap but just concatenate the R1 and R2 reads, the pseudo-reads length is going to be R1+R2+linker so about 250-300bp. To avoid these sequences to be filtered out, we need to adapt the `amplicon_min_length` paramters to reflect this.

- Another consequence of concatenating reads instead of merging, is that the linker sequence may be taken into account in the BLAST search. Therefore we need to lower both the `blast_qcov` and `blast_perc_id` parameters slightly.

So the adapted command:

```sh
nextflow run bio-raum/FooDMe2 \
    -r main \
    -profile myprofile \
    --input samples.tsv \
    --primer_set COI_ILM_park_insects \
    --non_overlapping \
    --amplicon_min_length 250 \
    --blast_qcov 94 \
    --blast_perc_id 98 
```

In reality the BLAST-related parameters (including others such as `blast_bitscore_diff` and `blast_min_consensus`) should be completely reexamined and optimized for this method. The exercise is left to the reader.
