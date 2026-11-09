#!/usr/bin/env python3
"""
Parser for savont log files to extract read counts in format "count <-> event"
"""

import re
import sys
import json
from argparse import ArgumentParser

def parse_savont_log(log_file_path):
    """
    Parse savont log file and extract read count information
    """
    try:
        with open(log_file_path, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File {log_file_path} not found")
        return []
    
    read_counts = []
    
    # Patterns to match read count information
    patterns = [
        # Pattern for "Number of valid reads - X. Number of reads below quality threshold - Y"
        r'Number of valid reads\s*-\s*(\d+).+?Number of reads below quality threshold\s*-\s*(\d+)',
        
        # Pattern for "Total reads: X, Reads without SNPmers: Y"
        r'Total reads:\s*(\d+),\s*Reads without SNPmers:\s*(\d+)',
        
        # Pattern for "Filtered X reads with ratio > Y"
        r'Filtered\s+(\d+)\s+reads\s+with\s+ratio\s+>\s+\d+\.\d+',
        
        # Pattern for "Total assigned reads: X"
        r'Total assigned reads:\s*(\d+)',
        
        # Pattern for "Number of unique equivalence classes: X"
        r'Number of unique equivalence classes:\s*(\d+)',
    ]
    
    for line_num, line in enumerate(lines, 1):
        # Check each pattern
        for pattern in patterns:
            matches = re.findall(pattern, line)
            if matches:
                if pattern == patterns[0]:  # First pattern - two counts
                    read_counts.append({"count": matches[0][0], "event": "Number of valid reads"})
                    read_counts.append({"count": matches[0][1], "event": "Number of reads below quality threshold"})
                elif pattern == patterns[1]:  # Second pattern - two counts
                    read_counts.append({"count": matches[0][0], "event": "Total reads"})
                    read_counts.append({"count": matches[0][1], "event": "Reads without SNPmers"})
                elif pattern == patterns[2]:  # Third pattern - one count
                    read_counts.append({"count": matches[0], "event": "Filtered reads with ratio > 0.005"})
                elif pattern == patterns[3]:  # Fourth pattern - one count
                    read_counts.append({"count": matches[0], "event": "Total assigned reads"})
                elif pattern == patterns[4]:  # Fifth pattern - one count
                    read_counts.append({"count": matches[0], "event": "Number of unique equivalence classes"})
    
    return read_counts

def main():
    parser = ArgumentParser(description="Parse savont log file and extract read counts")
    parser.add_argument("log_file", help="Path to the savont log file")
    parser.add_argument("--output", "-o", help="Output JSON file path")
    
    args = parser.parse_args()
    
    counts = parse_savont_log(args.log_file)
    
    if counts:
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(counts, f, indent=2)
            print(f"Read count information written to {args.output}")
        else:
            print("Read count information extracted:")
            for count in counts:
                print(f"{count['count']} <-> {count['event']}")
    else:
        print("No read count information found in the log file")

if __name__ == "__main__":
    main()