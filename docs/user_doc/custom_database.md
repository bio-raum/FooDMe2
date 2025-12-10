# Creating a custom database

FooDMe2 supplies users with a range of (versioned) reference databases to analyse their metabarcoding data against. However, we understand that some users already have their own (potentially curated) databases and would like to use it with FooDMe2. The instructions below are meant to help you with this process. 

## Disclaimer

The use of a curated database is typically meant to achieve two things - ensure that no incorrectly labelled reference sequences are present and to include data that may not yet be included in published databases.

However, please be aware that manually created databases - for example including only a set of species that you are interested in - may bias your results. FooDMe2 will identify the best species match for a given OTU based on sequence similarity (within certain limits). If the actual species is not included in your database, you may end up with incorrect assignments. So please make sure that your database is comprehensive for your particular purpose. 

## Requirements

FooDMe2 uses BLAST to compare OTUs against a given database. For this, the BLAST database must include taxonomic information, which is added during formatting of the database flatfile (FASTA). Taxonomic information has to be provided in a tabular format (sequence id <-> NCBI tax id). If you are working with sequences from GenBank, you can use the NCBI lookup table. Else, you will have to somehow produce this file yourself. More below. 

## Step-by-Step

Blast: Version 2.15.0 (install via Conda or use a container)

### Tax ID lookup table

If your database includes GenBank accessions in the FASTA headers, you can use the NCBI lookup table:
 
```bash 
wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
gunzip -c nucl_gb.accession2taxid.gz | cut -f 1,3 | tail -n +2 > genbank2taxid
```

If your database is using other kinds of sequence IDs, please create a file with the following format:

```TSV
SequenceA   2134
SequenceB   67891
...
```
Each line should include the sequence identifier of a database entry, mapped to a (species-level) taxonomy ID from [NCBI](https://www.ncbi.nlm.nih.gov/taxonomy).
 
### Formatting the BLAST database

We assume that your database is called `my_db.fasta`; else adjust the command below. The taxonomy lookup file in our example will be called `genbank2taxid`. If you are using your own lookup file, adjust the command accordingly. 

```bash 
makeblastdb \\
    -in my_db.fasta \\
    -parse_seqids \\
    -taxid_map genbank2taxid \\
 
mkdir  my_custom_db
 
mv my_db.fasta* my_custom_db/

```

The BLAST database is now stored in the folder `my_custom_db` (change to better fit your situation). This folder can now be passed to FooDMe2 like so:

```bash
nextflow run bio-raum/FooDMe2 -profile my_profile --input samples.tsv --blast_db /path/to/my_custom_db <other options here>
```


