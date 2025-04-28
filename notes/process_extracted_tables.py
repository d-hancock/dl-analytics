#!/usr/bin/env python3
"""
Process extracted table definitions and convert the text sections into structured arrays.
"""

import os
import sys
import json
import argparse
from pathlib import Path

# Add parent directory to path so we can import our module
sys.path.insert(0, str(Path(__file__).parent.parent))
from extractor.core import parse_column_section, parse_index_section, parse_foreign_key_section


def process_file(file_path):
    """
    Process a single extracted table definition file.
    
    Args:
        file_path: Path to the JSON file to process
        
    Returns:
        True if the file was successfully processed and updated, False otherwise
    """
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        updated = False
        
        # Process column section if it exists
        if "column_section" in data and (not data.get("columns") or len(data["columns"]) == 0):
            data["columns"] = parse_column_section(data["column_section"])
            updated = True
            print(f"Parsed {len(data['columns'])} columns from {file_path.name}")
        
        # Process index section if it exists
        if "index_section" in data and (not data.get("indexes") or len(data["indexes"]) == 0):
            data["indexes"] = parse_index_section(data["index_section"])
            updated = True
            if data["indexes"]:
                print(f"Parsed {len(data['indexes'])} indexes from {file_path.name}")
        
        # Process foreign key section if it exists
        if "fk_section" in data and (not data.get("foreign_keys") or len(data["foreign_keys"]) == 0):
            data["foreign_keys"] = parse_foreign_key_section(data["fk_section"])
            updated = True
            if data["foreign_keys"]:
                print(f"Parsed {len(data['foreign_keys'])} foreign keys from {file_path.name}")
        
        if updated:
            # Write the updated data back to the file
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2)
            return True
        
        return False
    
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False


def process_directory(directory_path, recursive=False):
    """
    Process all JSON files in a directory.
    
    Args:
        directory_path: Path to the directory containing JSON files
        recursive: If True, also process JSON files in subdirectories
        
    Returns:
        Tuple of (total files processed, number of files successfully updated)
    """
    dir_path = Path(directory_path)
    
    if recursive:
        json_files = list(dir_path.glob("**/*.json"))
    else:
        json_files = list(dir_path.glob("*.json"))
    
    total = len(json_files)
    success = 0
    
    print(f"Found {total} JSON files in {directory_path}")
    
    for i, file_path in enumerate(json_files):
        print(f"Processing {i+1}/{total}: {file_path.name}... ", end="")
        if process_file(file_path):
            print("Updated")
            success += 1
        else:
            print("No changes needed")
    
    return total, success


def main():
    parser = argparse.ArgumentParser(description="Process extracted table definitions")
    parser.add_argument(
        "path",
        help="Path to a JSON file or directory containing JSON files to process"
    )
    parser.add_argument(
        "--recursive", "-r",
        action="store_true",
        help="Process JSON files in subdirectories (only relevant if path is a directory)"
    )
    
    args = parser.parse_args()
    path = Path(args.path)
    
    if not path.exists():
        print(f"Error: Path '{path}' does not exist.")
        return 1
    
    if path.is_file():
        if path.suffix.lower() != ".json":
            print(f"Error: File '{path}' is not a JSON file.")
            return 1
        
        if process_file(path):
            print(f"Successfully updated {path}")
        else:
            print(f"No changes made to {path}")
    
    elif path.is_dir():
        total, success = process_directory(path, recursive=args.recursive)
        print(f"\nProcessed {total} files, updated {success} files.")
    
    else:
        print(f"Error: Path '{path}' is neither a file nor a directory.")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())