#!/usr/bin/env python3
"""
Consolidate multiple extracted JSON files into a single file and parse the sections.
This is more efficient than processing each file individually.
"""

import os
import sys
import json
import argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Any

# Add parent directory to path so we can import our module
sys.path.insert(0, str(Path(__file__).parent.parent))
from extractor.core import parse_column_section, parse_index_section, parse_foreign_key_section


def find_all_json_files(dirs: List[Path], recursive=False) -> List[Path]:
    """Find all JSON files in the specified directories."""
    json_files = []
    for dir_path in dirs:
        if not dir_path.exists() or not dir_path.is_dir():
            print(f"Warning: {dir_path} is not a valid directory.")
            continue
            
        if recursive:
            json_files.extend(list(dir_path.glob("**/*.json")))
        else:
            json_files.extend(list(dir_path.glob("*.json")))
    
    return json_files


def load_json_file(file_path: Path) -> Dict[str, Any]:
    """Load a single JSON file."""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            return data
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}


def load_all_json_files(files: List[Path], max_workers=10) -> Dict[str, Any]:
    """Load all JSON files in parallel using ThreadPoolExecutor."""
    all_data = {}
    success_count = 0
    
    print(f"Loading {len(files)} JSON files...")
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all file loading tasks
        future_to_file = {executor.submit(load_json_file, file_path): file_path for file_path in files}
        
        # Process results as they complete
        for future in as_completed(future_to_file):
            file_path = future_to_file[future]
            try:
                data = future.result()
                if data:
                    # Use table_name as the key
                    if 'table_name' in data:
                        all_data[data['table_name']] = data
                        success_count += 1
                    else:
                        print(f"Warning: {file_path.name} does not have a table_name field.")
            except Exception as e:
                print(f"Error processing {file_path}: {e}")
    
    print(f"Successfully loaded {success_count} out of {len(files)} files.")
    return all_data


def process_table_data(table_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process a single table's data to extract structured information."""
    # Only process if we haven't already parsed these sections
    if not table_data.get('columns') or len(table_data['columns']) == 0:
        if 'column_section' in table_data:
            table_data['columns'] = parse_column_section(table_data['column_section'])
    
    if not table_data.get('indexes') or len(table_data['indexes']) == 0:
        if 'index_section' in table_data:
            table_data['indexes'] = parse_index_section(table_data['index_section'])
    
    if not table_data.get('foreign_keys') or len(table_data['foreign_keys']) == 0:
        if 'fk_section' in table_data:
            table_data['foreign_keys'] = parse_foreign_key_section(table_data['fk_section'])
    
    return table_data


def process_all_tables(all_data: Dict[str, Any], max_workers=10) -> Dict[str, Any]:
    """Process all tables in parallel using ThreadPoolExecutor."""
    processed_data = {}
    count = 0
    total = len(all_data)
    
    print(f"Processing {total} tables...")
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all processing tasks
        future_to_table = {executor.submit(process_table_data, data): table_name 
                         for table_name, data in all_data.items()}
        
        # Process results as they complete
        for future in as_completed(future_to_table):
            table_name = future_to_table[future]
            count += 1
            if count % 50 == 0:
                print(f"Processed {count}/{total} tables...")
                
            try:
                processed_data[table_name] = future.result()
            except Exception as e:
                print(f"Error processing table {table_name}: {e}")
                processed_data[table_name] = all_data[table_name]  # Keep the original data

    # Generate some statistics about the parsed data
    tables_with_columns = sum(1 for table in processed_data.values() if table.get('columns') and len(table['columns']) > 0)
    tables_with_indexes = sum(1 for table in processed_data.values() if table.get('indexes') and len(table['indexes']) > 0)
    tables_with_fks = sum(1 for table in processed_data.values() if table.get('foreign_keys') and len(table['foreign_keys']) > 0)
    
    print(f"Processing complete. Tables with columns: {tables_with_columns}, with indexes: {tables_with_indexes}, with foreign keys: {tables_with_fks}")
    
    return processed_data


def save_consolidated_data(data: Dict[str, Any], output_path: Path) -> None:
    """Save the consolidated data to a JSON file."""
    try:
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Saved consolidated data to {output_path}")
    except Exception as e:
        print(f"Error saving to {output_path}: {e}")


def main():
    parser = argparse.ArgumentParser(description="Consolidate and parse extracted JSON table definitions")
    parser.add_argument(
        "dirs",
        nargs="+",
        help="One or more directories containing JSON files to consolidate"
    )
    parser.add_argument(
        "--recursive", "-r",
        action="store_true",
        help="Search for JSON files recursively in the directories"
    )
    parser.add_argument(
        "--output", "-o",
        default="consolidated_table_definitions.json",
        help="Output file path for the consolidated JSON data"
    )
    parser.add_argument(
        "--workers", "-w",
        type=int,
        default=10,
        help="Maximum number of worker threads for parallel processing"
    )
    
    args = parser.parse_args()
    
    # Convert directory strings to Path objects
    dir_paths = [Path(dir_path) for dir_path in args.dirs]
    output_path = Path(args.output)
    
    # Find all JSON files in the directories
    json_files = find_all_json_files(dir_paths, args.recursive)
    if not json_files:
        print("No JSON files found in the specified directories.")
        return 1
    
    # Load all JSON files into memory
    all_data = load_all_json_files(json_files, args.workers)
    if not all_data:
        print("No valid data loaded from JSON files.")
        return 1
    
    # Process all tables to extract structured data
    processed_data = process_all_tables(all_data, args.workers)
    
    # Save the consolidated and processed data
    save_consolidated_data(processed_data, output_path)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())