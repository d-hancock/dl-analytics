#!/usr/bin/env python3
"""
Reformat consolidated tables JSON data into a hierarchical structure organized by schema.

This script takes a consolidated_tables.json file that contains various tables with their
metadata, foreign keys, indexes, etc. and restructures it into a more organized format
where tables are grouped by their schema. The original file is preserved, and a new
reformatted file is created.

Usage:
    python reformat_consolidated_tables.py [--input INPUT_FILE] [--output OUTPUT_FILE]

Example:
    python reformat_consolidated_tables.py --input consolidated_tables.json --output reformatted_tables.json
"""

import json
import argparse
import os
from typing import Dict, Any
from datetime import datetime


def reformat_consolidated_tables(input_file: str, output_file: str, make_backup: bool = True) -> None:
    """
    Create a new reformatted version of consolidated tables data organized by schema.

    Args:
        input_file: Path to the input JSON file containing consolidated tables data.
        output_file: Path where the reformatted data will be saved.
        make_backup: Whether to create a backup of the original file (default: True).
    """
    try:
        # Create a backup of the original file if requested
        if make_backup:
            backup_file = f"{input_file}.{datetime.now().strftime('%Y%m%d_%H%M%S')}.bak"
            try:
                with open(input_file, 'r') as src, open(backup_file, 'w') as dst:
                    dst.write(src.read())
                print(f"Backup created: {backup_file}")
            except Exception as e:
                print(f"Warning: Could not create backup: {e}")

        # Load the input data
        with open(input_file, 'r') as file:
            data = json.load(file)

        # Create a new dictionary to hold the reformatted data
        reformatted_data = {}

        # Process each table
        for table_key, table_data in data.items():
            # Split the schema and table name
            if '.' in table_key:
                schema, table = table_key.split('.')
            else:
                # Handle case where table_key doesn't have schema
                schema = "Unknown"
                table = table_key

            # Initialize schema in reformatted data if it doesn't exist
            if schema not in reformatted_data:
                reformatted_data[schema] = {}

            # Add table data to the schema
            reformatted_data[schema][table] = {
                "table_name": table_data.get("table_name", table_key),
                "schema": table_data.get("schema", schema),
                "table": table_data.get("table", table),
                "doc_page": table_data.get("doc_page"),
                "pdf_page": table_data.get("pdf_page"),
                "columns": table_data.get("columns", []),
                "indexes": table_data.get("indexes", []),
                "foreign_keys": table_data.get("foreign_keys", [])
            }

        # Save the reformatted data to a new file
        with open(output_file, 'w') as file:
            json.dump(reformatted_data, file, indent=4)
            
        print(f"Successfully created reformatted data in '{output_file}'")
        print(f"Original data preserved in '{input_file}'")
        
    except Exception as e:
        print(f"Error reformatting tables: {e}")


def main() -> None:
    """Parse command line arguments and run the reformatting function."""
    parser = argparse.ArgumentParser(
        description="Reformat consolidated tables into schema-organized structure"
    )
    parser.add_argument(
        "--input", "-i",
        default="consolidated_tables.json",
        help="Path to the input JSON file (default: consolidated_tables.json)"
    )
    parser.add_argument(
        "--output", "-o",
        default="reformatted_tables.json",
        help="Path to the output JSON file (default: reformatted_tables.json)"
    )
    parser.add_argument(
        "--no-backup", 
        action="store_true",
        help="Skip creating a backup of the input file"
    )
    
    args = parser.parse_args()
    
    reformat_consolidated_tables(args.input, args.output, not args.no_backup)


if __name__ == "__main__":
    main()