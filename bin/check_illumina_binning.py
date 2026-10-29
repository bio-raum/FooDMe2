#!/usr/bin/env python3
import sys
import gzip
import os

def check_binning(fastq_path, output_path):
    # Handle empty/missing files safely
    if not os.path.exists(fastq_path) or os.path.getsize(fastq_path) == 0:
        with open(output_path, 'w') as f:
            f.write("false\n")
        return

    unique_chars = set()
    line_counter = 0
    reads_analyzed = 0

    try:
        # Open with gzip if it ends with .gz, otherwise normal open
        open_func = gzip.open if fastq_path.endswith('.gz') else open
        mode = 'rt' if fastq_path.endswith('.gz') else 'r' # read text mode
        
        with open_func(fastq_path, mode, errors='ignore') as f:
            for line in f:
                line_counter += 1
                
                # Check every 4th line (Quality score lines)
                if line_counter % 4 == 0:
                    reads_analyzed += 1
                    # Strip newline and add characters to our unique set
                    unique_chars.update(line.strip())
                    
                    # Stop early once we hit 100 reads
                    if reads_analyzed >= 100:
                        break
    except Exception as e:
        # If the container cuts the stream or the file is corrupted, 
        # log it to stderr but don't crash the script execution
        sys.stderr.write(f"Warning encountered: {str(e)}\n")

    # If we read absolutely nothing, default to false
    if reads_analyzed == 0:
        is_binned = "false"
    else:
        # NovaSeq/Binned data typically shows <= 10 unique quality chars
        is_binned = "true" if len(unique_chars) <= 10 else "false"

    with open(output_path, 'w') as f:
        f.write(f"{is_binned}\n")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: check_illumina_binning.py <input_fastq> <output_status_txt>\n")
        sys.exit(1)
        
    check_binning(sys.argv[1], sys.argv[2])
