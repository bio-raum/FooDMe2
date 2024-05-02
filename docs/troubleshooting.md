# Common issues

## Cutadapt: Multiple hits from the same species/genus per sample

If you find that the results are "exploded" into many redundant hits (i.e. from the same species or genus), chances are that something has gone wrong during primer site removal, resulting in many near-redundant OTUs being formed.
If you elected to use Cutadapt for primer site removal, check if it would perhaps be appropriate to also set the option `--cutadapt_trim_3p`, i.e. in such cases where your target is so small that it is contained within a single read.
Cutadapt will otherwise fail to properly clean the primer sites, resulting in sequences that cannot be fully merged into unique OTUs later on.
