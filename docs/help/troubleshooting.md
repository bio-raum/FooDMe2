# Common issues and errors

## `Too few reads - stopping sample SAMPLE after PCR primer removal!`

This error suggests that no or too few reads survived the PCR primer removal. Several things could cause this:

- Too few reads to begin with (see [requirements](../user_doc/requirements.md))
- The provided primer sequences are incorrect
- The reads were already trimmed; we only allow reads to pass that have been successfully primer trimmed inside of FooDMe2 to ensure high data quality

## `WARN: SAMPLE - the mean insert size seems to be close to or greater than the mean read length. Should you perhaps use --cutadapt_trim_3p?`

If you see this warning, it means that there is a good chance that your reads contain PCR primer sites at both ends. This is because the insert size, i.e. the size of the sequenced fragment is smaller or roughly the same size as the individual paired-end reads. If your results look very noisy or fragmented, try re-running the analysis with the trimming option `--cutadapt_trim_3p` enabled. 

## `XY read sets are classified as single-end - this typically requires --cutadapt_trim_3p.`

This warning is similar to the previous one. The pipeline has detected single-end data, which makes it very likely that individual reads contain PCR primer sites at both ends. If your results look very noisy or fragmented, try re-running the analysis with the trimming option `--cutadapt_trim_3p` enabled. 

## `The required reference directory was not found on your system, exiting!`

Make sure that you provided the path to the **base directory** where references are installed. This is the exact same path you provided when running `--build_references`. For example if the folder structure is:

```
/home/user/reference_base/foodme/1.0/...
```

You should provide `--reference_base /home/user/reference_base` 

## BLAST searches run out of memory

This error is most likely to occur when screening against the GenBank NT database (`--db genbank`) in combination with a fairly "deep" taxonomic root (`-taxid_filter`). The larger the slice of GenBank that BLAST is asked to search against, the larger the available memory needs to be. For example, searching against all amniotes (mammals and birds) will require around 80GB of RAM (at the time of writing - this value will grow as GenBank grows). 

## The pipeline immediately fails with a "no such file" error

Most likely you saw something like this:

```bash
ERROR ~ No such file or directory: 
```

This is most likely happening because you passed the `reference_base` option from a custom config file via the "-c" argument. There is currently a [known bug](https://github.com/nextflow-io/nextflow/issues/2662) in Nextflow which prevents the correct passing of parameters from a custom config file to the workflow. Please use the command line argument `--reference_base` instead or consider contributing a site-specific [config file](https://github.com/bio-raum/nf-configs). 

## Working behind a proxy

When working behind a proxy Apptainer, Podman, Singularity and Docker depdendency managers fail to download images/containers. This will usually be accompanied by an error that a host was not reachable. 

First, check if your proxy settings are already configured:

```bash
echo $HTTPS_PROXY
```

If this returns your proxy settings, great. If not, you can add the correct proxy information to your local bash profile (e.g. $HOME/.bashrc):

```bash
export HTTPS_PROXY="myproxy.adress.com:80"
```

Next, you need to tell the container to import this variable for it becomes visible to the processes. You do this by adding the `envWhitelist` parameter to the dependency manager configuration in your config (wether local or remote):

```bash
singularity {
  enabled = true
  cacheDir = "/projects/singularity_cache"
  envWhitelist = "HTTP_PROXY,HTTPS_PROXY"
}
```
