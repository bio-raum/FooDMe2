#!/usr/bin/env python3
import argparse
import os
import sys


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Injiziert hochgemappte Read-Counts aus einer VSEARCH-OTU-Tabelle in die Header einer FASTA-Zentroiden-Datei (;size=X;) für UCHIME."
    )
    parser.add_argument(
        "-t", "--table",
        required=True,
        help="Pfad zur VSEARCH OTU-Tabelle (.txt / .tsv)"
    )
    parser.add_argument(
        "-i", "--input",
        required=True,
        help="Pfad zur originalen OTU-Zentroiden-FASTA-Datei"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Pfad für die neu zu erstellende FASTA-Datei mit aktualisierten Counts"
    )
    return parser.parse_args()


def update_otu_headers(otu_table_path, fasta_in_path, fasta_out_path):
    if not os.path.exists(otu_table_path):
        print(f"Error: Die OTU-Tabelle '{otu_table_path}' wurde nicht gefunden.", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(fasta_in_path):
        print(f"Error: Die Eingabe-FASTA '{fasta_in_path}' wurde nicht gefunden.", file=sys.stderr)
        sys.exit(1)

    counts = {}
    with open(otu_table_path, "r") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.strip().split()
            if len(parts) >= 2:
                otu_id = parts[0]
                count = parts[1]
                counts[otu_id] = count

    otu_count = 0
    with open(fasta_in_path, "r") as infile, open(fasta_out_path, "w") as outfile:
        for line in infile:
            if line.startswith(">"):
                otu_count += 1
                # Holt die reine OTU-ID (z.B. "OTU_1") ohne ">" und alte Suffixe
                raw_id = line.strip().split(";")[0].replace(">", "")
                # Holt den echten hochgemappten Count (Default 0 falls nicht gemappt)
                true_size = counts.get(raw_id, "0")
                if true_size == "0":
                    continue  # Skip entries with true_size of 0
                # Schreibt den perfekten Header fuer UCHIME
                outfile.write(f">{raw_id};size={true_size}\n")
            else:
                outfile.write(line)

    print(f"SUCCESS: '{fasta_out_path}' mit {otu_count} OTUs wurde erfolgreich erstellt!")


def main():
    args = parse_arguments()
    update_otu_headers(args.table, args.input, args.output)


if __name__ == "__main__":
    main()
