# Standardized methods

FooDMe2 aims at offering **validated** pre-configured standard methods that can be chosen with a single parameter.
This is implemented with the `--primer_set` argument.

If you would like to see your methods incorporated in FooDMe2 standard set, please get in touch with us!
Likewise, if you find one of the method underperforming on your datasets, please contact us.

Please note that these preconfigured methods may make big assumptions on the sequencing raw data.

**You should always verify these methods with your own laboratory workflows before using them in a diagnostic setting!**

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

Some of the paramters are set in standardized manner, you may want to adapt them to your specific worklfows:

* `max_expected_errors` is set to 2.5% of the maximum amplicon length for Illumina. However since Illumina sequencing ofter uses 2x150bp sequencing, this parameter is capped to `6` for long amplicons. For IonTorrent and Oxford Nanopore methods, this parameter is set to 5% of the maximum amplicon size, to account for higher error rate with these technologies.
* `min_amplicon_size` and `max_amplicon_size` are set based on *in silico* predicted amplicon size distribution calculated by our companion workflow [BarBeQuE](https://github.com/bio-raum/BarBeQuE). To set this range, we start with the Mean +/- 2 std.dev of the amplicon size. This range is in most cases then enlarged to account for phylogentic variability and avoid exclusion of entire groups of species.

!!! Warning Illumina methods

    The primer trimming and read merging strategies for Illumina methods assume 2 x 150 bp sequencing.
    If you use other sequencing lengths, you will likely need to adapt the methods to your data.
