#!/usr/bin/env python3

import argparse
import os
import urllib.request
from urllib.parse import urlparse
import zipfile
import tarfile

# Global dictionary mapping version numbers to lists of URLs
midori = {
    "267": "https://zenodo.org/records/23071879/files/MIDORI2_GB267_BLAST.zip?download=1"
}

def download_file(url, output_dir, proxy=None):
    """Download a single file from URL to the specified directory"""
    try:
        # Extract filename from URL
        parsed_url = urlparse(url)
        filename = os.path.basename(parsed_url.path)
        
        # Create full output path
        output_path = os.path.join(output_dir, filename)
        
        print(f"Downloading {filename}...")
        
        # Setup proxy if provided
        if proxy:
            proxy_handler = urllib.request.ProxyHandler({'https': proxy})
            opener = urllib.request.build_opener(proxy_handler)
            urllib.request.install_opener(opener)
        
        urllib.request.urlretrieve(url, output_path)
        print(f"Downloaded {filename}")
        return output_path  # Return the path to the downloaded file
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return None

def unzip_file(file_path, extract_to):
    """Unzip a downloaded file to the specified directory"""
    try:
        print(f"Extracting {os.path.basename(file_path)}...")
        
        if file_path.endswith('.zip'):
            with zipfile.ZipFile(file_path, 'r') as zip_ref:
                zip_ref.extractall(extract_to)
        elif file_path.endswith(('.tar', '.gz')):
            with tarfile.open(file_path, 'r:*') as tar_ref:
                tar_ref.extractall(extract_to)
        else:
            print(f"Unsupported file format: {file_path}")
            return False
            
        print(f"Extraction complete for {os.path.basename(file_path)}")
        return True
    except Exception as e:
        print(f"Error extracting {file_path}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Download MIDORI database files')
    parser.add_argument('--version', required=True, help='Database version to download')
    parser.add_argument('--outdir', required=True, help='Output directory for downloaded files')
    
    args = parser.parse_args()
    
    # Check if the version exists in our dictionary
    if args.version not in midori:
        print(f"Error: Version '{args.version}' not found in database")
        return
    
    # Get proxy from environment variable
    proxy = os.environ.get('HTTPS_PROXY')
    
    # Create output directory if it doesn't exist
    os.makedirs(args.outdir, exist_ok=True)
    
    # Get URLs for the specified version
    url = midori[args.version]
    
    print(f"Downloading file for version {args.version} to {args.outdir}")
    
    # Download each file
    if url:
        downloaded_file = download_file(url, args.outdir, proxy)
        if downloaded_file:
            print(f"Download successful!")
            
            # Unzip the downloaded file
            if unzip_file(downloaded_file, args.outdir):
                print("Unzipping completed successfully!")
            else:
                print("Failed to unzip the downloaded file")

if __name__ == "__main__":
    main()
