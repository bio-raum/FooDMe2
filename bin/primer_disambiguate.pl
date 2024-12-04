#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Bio::PrimarySeq;
use Bio::Tools::IUPAC;
use Bio::SeqIO;
use Data::Dumper;

my $usage = qq{
perl primer_disambiguate.pl
    Getting help:
    [--help]

    Input:
    [--fasta filename]
        The name of the FASTA file to read

    Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile     = undef;
my $fasta       = undef;

my $help;

GetOptions(
    "help" => \$help,
    "fasta=s" => \$fasta,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

my $seqin = Bio::SeqIO->new(-file => $fasta, -format => "Fasta");
my $seqout = Bio::SeqIO->new(-file => ">$outfile", -format => "Fasta");

# All valid IUPAC bases
my %iupac_nuc = Bio::Tools::IUPAC->new->iupac_iub;

while (my $seq = $seqin->next_seq) {

    my $id = $seq->display_id();
    my $count = 0;

    # Check if the sequence contains non-IUPAC bases
    my @nucleotides = split(//, $seq->seq());
    foreach my $n (@nucleotides) {
        my $nuc = uc($n);
        if (!defined $iupac_nuc{$nuc}) {
            die "Your primer sequence contains non-IUPAC characters ($n in $id)\nPlease fix this.\n";
        }
    }

   # Create all possible non-degenerate sequences
    my $iupac = Bio::Tools::IUPAC->new(-seq => $seq);
    while (my $uniqueseq = $iupac->next_seq()) {
    # process the unique Bio::Seq object.
        $count += 1;
        my $new_id = $id . "." . $count;
        $uniqueseq->id($new_id);
        $uniqueseq->desc("");

        $seqout->write_seq($uniqueseq);
    }
}

 
