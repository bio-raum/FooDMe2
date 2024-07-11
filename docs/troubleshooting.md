# Common issues and errors

## `Too few reads - stopping sample SAMPLE after PCR primer removal!`

This error suggests that no or too few reads survived the PCR primer removal. Several things could cause this:

- Too few reads to begin with (see [requirements](requirements.md))
- The provided primer sequences are incorrect
- The reads were already trimmed; we only allow reads to pass that have been successfully primer trimmed inside of FooDMe2 to ensure high data quality

## `WARN: SAMPLE - the mean insert size seems to be close to or greater than the mean read length. Should you perhaps use --cutadapt_trim_3p?`

If you see this warning, it means that there is a good chance that your reads contain PCR primer sites at both ends. This is because the insert size, i.e. the size of the sequenced fragment is smaller or roughly the same size as the individual paired-end reads. If your results look very noisy or fragmented, try re-running the analysis with the trimming option `--cutadapt_trim_3p` enabled. 

## `XY read sets are classified as single-end - this typically requires --cutadapt_trim_3p.`

This warning is similar to the previous one. The pipeline has detected single-end data, which makes it very likely that individual reads contain PCR primer sites at both ends. If your results look very noisy or fragmented, try re-running the analysis with the trimming option `--cutadapt_trim_3p` enabled. 

## BLAST searches run out of memory

This error is most likely to occur when screening against the GenBank NT database (`--db genbank`) in combination with a fairly "deep" taxonomic root (`-taxid_filter`). The larger the slice of GenBank that BLAST is asked to search against, the larger the available memory needs to be. For example, searching against all amniotes (mammals and birds) will require around 80GB of RAM (at the time of writing - this value will grow as GenBank grows). 



