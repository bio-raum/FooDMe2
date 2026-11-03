import re
import json
import argparse
import sys

def parse_savont_log(file_path):
    # The dictionary to collect counts in
    results = {}
    
    # Regex-Patterns to find read counts in log file
    patterns = [
        (r"Number of reads removed due to length filtering:\s*(\d+)", "Removed due to length filtering"),
        (r"Number of valid reads\s*-\s*(\d+)", "Valid reads"),
        (r"Number of reads below quality threshold\s*-\s*(\d+)", "Below quality threshold"),
        (r"Total reads:\s*(\d+)", "Total reads after initial filters"),
        (r"Reads without SNPmers:\s*(\d+)", "Reads without SNPmers"),
        (r"Largest cluster:\s*(\d+)\s*reads", "Reads in largest cluster"),
        (r"Mapping\s*(\d+)\s*reads to", "Reads mapped to ASVs (Stage 7)"),
        (r"Filtered\s*(\d+)\s*reads with ratio", "Filtered reads (ratio > 0.005)")
    ]
    
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                for pattern, operation in patterns:
                    match = re.search(pattern, line)
                    if match:
                        # Operation wird zum Key, Read-Count zum Integer-Wert
                        results[operation] = int(match.group(1))
                        break  # Sobald ein Pattern matcht, nächste Zeile prüfen
                        
    except FileNotFoundError:
        print(f"Error: The file'{file_path}' could not be found.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(1)
                
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extracts read counts from Savont-Logfile.")
    parser.add_argument("--log", required=True, help="Path to savont log file")
    
    args = parser.parse_args()
    
    # Run parser
    read_counts = parse_savont_log(args.log)
    
    # JSON-result
    print(json.dumps(read_counts, indent=4))
    
 