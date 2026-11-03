#!/usr/bin/env python3
"""
Parser for savont log files to extract read counts in format "count <-> event"
"""

import re
import sys

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
                    read_counts.append(f"{matches[0][0]} <-> Number of valid reads")
                    read_counts.append(f"{matches[0][1]} <-> Number of reads below quality threshold")
                elif pattern == patterns[1]:  # Second pattern - two counts
                    read_counts.append(f"{matches[0][0]} <-> Total reads")
                    read_counts.append(f"{matches[0][1]} <-> Reads without SNPmers")
                elif pattern == patterns[2]:  # Third pattern - one count
                    read_counts.append(f"{matches[0]} <-> Filtered reads with ratio > 0.005")
                elif pattern == patterns[3]:  # Fourth pattern - one count
                    read_counts.append(f"{matches[0]} <-> Total assigned reads")
                elif pattern == patterns[4]:  # Fifth pattern - one count
                    read_counts.append(f"{matches[0]} <-> Number of unique equivalence classes")
    
    return read_counts

def main():
    if len(sys.argv) != 2:
        print("Usage: python parse_savont_log.py <log_file_path>")
        sys.exit(1)
    
    log_file_path = sys.argv[1]
    counts = parse_savont_log(log_file_path)
    
    if counts:
        print("Read count information extracted:")
        for count in counts:
            print(count)
    else:
        print("No read count information found in the log file")

if __name__ == "__main__":
    main()