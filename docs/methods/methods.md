# Standardized methods

FooDMe2 aims at offering **validated** pre-configured standard methods that can be chosen with a single parameter.
This is implemented with the `--primer_set` argument.

Currently following standard methods are implemented:

* 16S metabarcoding of mammals and birds (German ASU L 00.00-184)
* 16S metabarcoding of insects (Hillinger et al. 2023)
* 16S metabarcoding of fish (Dobrovolny et al. 2019; using ASU L 00.00-184 )
* COI metabarcoding of fish (Guenther et al. 2017)
* COI metabarcoding of insects (Park et al. 2001)
* CYTB metabarcoding of fish (German ASU L 10.00-12)

If you would like to see your methods incorporated in FooDMe2 standard set, please get in touch with us!

Please note that these preconfigured methods may make big assumptions on the sequencing raw data.
Especially for Illumina, these methods were developed with 2x150bp sequencing (typically MiSeq) in mind.

**You should always verify these methods with your own laboratory workflows before using them in a diagnostic setting!**