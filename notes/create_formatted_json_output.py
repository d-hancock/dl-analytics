#!/usr/bin/env python3
import json
import os
import re
import csv
import time
import hashlib
import argparse
from pathlib import Path
from datetime import datetime
from collections import defaultdict

# Use current directory for relative paths
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
HTML_FILE = CURRENT_DIR / "CareTend Data Dictionary OLTP DB.html"
OUTPUT_JSON_FILE = CURRENT_DIR / "formatted_table_definitions.json"
EXTRACTED_JSON_FILE = CURRENT_DIR / "extracted_table_definitions.json"
CSV_FILE = CURRENT_DIR / "all_table_definitions.csv"
PROCESSING_CACHE_FILE = CURRENT_DIR / "formatted_json_cache.json"

# Debug flag
DEBUG_LOGGING = False

# Set up logging
def log(message, level="INFO"):
    """Log message with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # Only print DEBUG messages if debug logging is enabled
    if level == "DEBUG" and not DEBUG_LOGGING:
        return
        
    print(f"[{timestamp}] [{level}] {message}")

def get_file_hash(file_path):
    """Calculate SHA-256 hash of a file to detect changes."""
    if not os.path.exists(file_path):
        return None
        
    hasher = hashlib.sha256()
    try:
        with open(file_path, 'rb') as f:
            buf = f.read(65536)  # Read in 64k chunks
            while len(buf) > 0:
                hasher.update(buf)
                buf = f.read(65536)
        return hasher.hexdigest()
    except Exception as e:
        log(f"Error calculating hash for {file_path}: {e}", "ERROR")
        return None

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Generate formatted JSON output from extracted JSON source.')
    parser.add_argument('--force', '-f', action='store_true', help='Force regeneration of output regardless of cache status')
    parser.add_argument('--output', '-o', type=str, help=f'Output file path (default: {OUTPUT_JSON_FILE})')
    parser.add_argument('--json-input', type=str, help=f'JSON input file path (default: {EXTRACTED_JSON_FILE})')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose (debug) logging')
    return parser.parse_args()

def check_cache(force_regenerate=False):
    """Check if we can use cached data or need to reprocess."""
    if force_regenerate:
        log("Force regeneration enabled, ignoring cache")
        return None
        
    if not os.path.exists(PROCESSING_CACHE_FILE):
        log("No processing cache found, will generate fresh data")
        return None
        
    # Check if source files have changed
    source_files = [EXTRACTED_JSON_FILE, HTML_FILE]
    current_hashes = {}
    
    for file_path in source_files:
        if os.path.exists(file_path):
            current_hashes[str(file_path)] = get_file_hash(file_path)
    
    try:
        with open(PROCESSING_CACHE_FILE, 'r', encoding='utf-8') as f:
            cache_data = json.load(f)
        
        # Check if file hashes match
        cached_hashes = cache_data.get('file_hashes', {})
        for file_path, current_hash in current_hashes.items():
            if current_hash != cached_hashes.get(file_path):
                log(f"Source file changed: {file_path}")
                return None
                
        log("Using cached processed data (source files unchanged)")
        return cache_data.get('data', {})
    except Exception as e:
        log(f"Error reading cache: {e}", "ERROR")
        return None

def save_to_cache(data):
    """Save processed data to cache along with file hashes."""
    source_files = [EXTRACTED_JSON_FILE, HTML_FILE]
    file_hashes = {}
    
    for file_path in source_files:
        if os.path.exists(file_path):
            file_hashes[str(file_path)] = get_file_hash(file_path)
    
    cache_data = {
        'file_hashes': file_hashes,
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'data': data
    }
    
    try:
        with open(PROCESSING_CACHE_FILE, 'w', encoding='utf-8') as f:
            json.dump(cache_data, f, indent=2)
        log(f"Cache saved to {PROCESSING_CACHE_FILE}")
    except Exception as e:
        log(f"Error saving cache: {e}", "ERROR")

def clean_value(value):
    """Clean and normalize a value from text or HTML."""
    if value is None:
        return None
    if isinstance(value, str):
        # Remove extra whitespace
        return re.sub(r'\s+', ' ', value).strip()
    return value

def parse_boolean(value):
    """Parse a string as boolean."""
    if value is None:
        return None
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        value = value.strip().lower()
        return value in ('yes', 'true', '1', 'y')
    return bool(value)

def extract_key_type(value):
    """Extract key type (PK, UK, etc.) from a string."""
    if not value or not isinstance(value, str):
        return None
    value = value.upper().strip()
    if 'PK' in value or 'PRIMARY KEY' in value:
        return "PK"
    if 'UK' in value or 'UNIQUE KEY' in value:
        return "UK"
    return None

def process_extracted_json(json_file_path=None):
    """Process previously extracted JSON data."""
    if json_file_path is None:
        json_file_path = EXTRACTED_JSON_FILE
    
    if not os.path.exists(json_file_path):
        log(f"Extracted JSON file not found: {json_file_path}", "WARNING")
        return {}

    try:
        log(f"Processing JSON data from {json_file_path}")
        start_time = time.time()
        
        with open(json_file_path, 'r', encoding='utf-8') as f:
            extracted_data = json.load(f)
        
        tables = {}
        formatted_data = {}
        table_count = 0
        column_count = 0
        index_count = 0
        fk_count = 0

        # Get a list of tables from all_table_definitions.csv to ensure we only include actual tables
        with open(CSV_FILE, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                table_name_raw = row.get('TableName', '')
                if not table_name_raw:
                    continue
                    
                # Extract schema and table name
                match = re.match(r'\[(\w+)\]\.\[(\w+)\]', table_name_raw)
                if match:
                    schema = match.group(1)
                    table_name = match.group(2)
                    table_key = f"{schema}.{table_name}"
                    
                    if table_key not in tables:
                        tables[table_key] = {
                            "schema": schema,
                            "table_name": table_name
                        }
        
        # Process JSON data using the table list we extracted
        log(f"Found {len(tables)} tables in CSV data")
        log(f"Found {len(extracted_data.get('tables', {}))} tables in JSON data")
        
        for table_key, table_info in tables.items():
            schema = table_info['schema']
            table = table_info['table_name']
            json_key = f"{schema}.{table}"
            
            # Initialize the formatted table entry
            formatted_data[table_key] = {
                "table": {
                    "schema": schema,
                    "table_name": table
                },
                "columns": [],
                "indexes": [],
                "foreign_keys": []
            }
            
            # Check if this table exists in the extracted JSON data
            if json_key in extracted_data.get("tables", {}):
                table_data = extracted_data["tables"][json_key]
                
                # Process columns
                for col_row in table_data.get("columns", []):
                    if len(col_row) < 2:
                        continue
                        
                    column = {}
                    # Try to extract column key (PK, UK)
                    column["key"] = extract_key_type(col_row[0])
                    column["name"] = clean_value(col_row[1])
                    
                    # Extract data type if available
                    if len(col_row) >= 3:
                        column["data_type"] = clean_value(col_row[2])
                    
                    # Extract max length if available and relevant
                    if len(col_row) >= 4:
                        try:
                            # Extract number from possible format like "100 bytes"
                            length_str = clean_value(col_row[3])
                            if length_str:
                                length_match = re.search(r'(\d+)', length_str)
                                if length_match:
                                    column["max_length_bytes"] = int(length_match.group(1))
                        except (ValueError, TypeError):
                            pass
                    
                    # Extract allow_nulls if available
                    if len(col_row) >= 5:
                        column["allow_nulls"] = parse_boolean(col_row[4])
                    
                    # Extract identity if available
                    if len(col_row) >= 6:
                        column["identity"] = parse_boolean(col_row[5])
                    
                    # Extract default if available
                    if len(col_row) >= 7:
                        column["default"] = clean_value(col_row[6])
                    
                    # Only add non-empty columns
                    if column.get("name"):
                        formatted_data[table_key]["columns"].append(column)
                        column_count += 1
                
                # Process indexes
                for idx_row in table_data.get("indexes", []):
                    if len(idx_row) < 2:
                        continue
                        
                    index = {}
                    # Try to extract index key (PK, UK)
                    index["key"] = extract_key_type(idx_row[0])
                    index["name"] = clean_value(idx_row[1])
                    
                    # Extract key columns if available
                    if len(idx_row) >= 3 and idx_row[2]:
                        key_cols = clean_value(idx_row[2])
                        if key_cols:
                            index["key_columns"] = [col.strip() for col in key_cols.split(',')]
                    
                    # Extract included columns if available
                    if len(idx_row) >= 4 and idx_row[3]:
                        incl_cols = clean_value(idx_row[3])
                        if incl_cols:
                            index["included_columns"] = [col.strip() for col in incl_cols.split(',')]
                    
                    # Extract unique flag if available
                    if len(idx_row) >= 5:
                        index["unique"] = parse_boolean(idx_row[4])
                    
                    # Extract page_locks flag if available
                    if len(idx_row) >= 6:
                        index["page_locks"] = parse_boolean(idx_row[5])
                    
                    # Extract fill_factor if available
                    if len(idx_row) >= 7:
                        try:
                            fill_factor = clean_value(idx_row[6])
                            if fill_factor and fill_factor.isdigit():
                                index["fill_factor"] = int(fill_factor)
                        except (ValueError, TypeError, AttributeError):
                            pass
                    
                    # Only add non-empty indexes
                    if index.get("name"):
                        formatted_data[table_key]["indexes"].append(index)
                        index_count += 1
                
                # Process foreign keys
                for fk_row in table_data.get("foreign_keys", []):
                    if len(fk_row) < 3:
                        continue
                        
                    fk = {}
                    fk["name"] = clean_value(fk_row[0])
                    
                    # Extract column name
                    if len(fk_row) >= 2:
                        fk["column_name"] = clean_value(fk_row[1])
                    
                    # Extract reference information
                    if len(fk_row) >= 3:
                        # Check if the reference is in format like [schema].[table].[column]
                        ref_match = re.match(r'\[(\w+)\]\.\[(\w+)\](?:\.\[(\w+)\])?', clean_value(fk_row[2]) or '')
                        if ref_match:
                            fk["references_schema"] = ref_match.group(1)
                            fk["references_table"] = ref_match.group(2)
                            if ref_match.group(3):
                                fk["references_column"] = ref_match.group(3)
                        else:
                            # Try simpler format: schema.table.column
                            ref_match = re.match(r'(\w+)\.(\w+)(?:\.(\w+))?', clean_value(fk_row[2]) or '')
                            if ref_match:
                                fk["references_schema"] = ref_match.group(1)
                                fk["references_table"] = ref_match.group(2)
                                if ref_match.group(3):
                                    fk["references_column"] = ref_match.group(3)
                    
                    # If references_column wasn't found but there's a 4th element, use it
                    if len(fk_row) >= 4 and 'references_column' not in fk and fk_row[3]:
                        fk["references_column"] = clean_value(fk_row[3])
                    
                    # Only add non-empty foreign keys with required fields
                    if fk.get("name") and fk.get("column_name") and fk.get("references_schema") and fk.get("references_table"):
                        formatted_data[table_key]["foreign_keys"].append(fk)
                        fk_count += 1
            
            table_count += 1
            
            # Log progress periodically
            if table_count % 50 == 0:
                log(f"Processed {table_count}/{len(tables)} tables")
        
        elapsed = time.time() - start_time
        log(f"Processing complete in {elapsed:.2f} seconds")
        log(f"Processed {table_count} tables with {column_count} columns, {index_count} indexes, and {fk_count} foreign keys")
        
        return formatted_data
    except Exception as e:
        log(f"Error processing data: {e}", "ERROR")
        import traceback
        log(traceback.format_exc(), "ERROR")
        return {}

def main():
    """Main function to produce the formatted JSON output."""
    args = parse_arguments()
    
    # Configure logging verbosity
    global DEBUG_LOGGING
    DEBUG_LOGGING = args.verbose
    
    # Set output and input paths
    output_file = args.output if args.output else OUTPUT_JSON_FILE
    json_input = args.json_input if args.json_input else EXTRACTED_JSON_FILE
    
    log("Starting formatted JSON output generation")
    log(f"JSON input: {json_input}")
    log(f"Output file: {output_file}")
    log(f"Force regeneration: {'Yes' if args.force else 'No'}")
    log(f"Verbose logging: {'Yes' if args.verbose else 'No'}")
    
    overall_start = time.time()
    
    # Check cache first
    tables_data = check_cache(force_regenerate=args.force)
    if tables_data:
        log("Using cached data instead of reprocessing")
    else:
        # Process data from extracted JSON
        tables_data = process_extracted_json(json_input)
        
        # Save the processed data to cache
        save_to_cache(tables_data)
    
    # Save the formatted data
    log(f"Saving formatted data to {output_file}")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(tables_data, f, indent=2)
    
    # Print statistics
    total_columns = sum(len(table_data.get("columns", [])) for table_data in tables_data.values())
    total_indexes = sum(len(table_data.get("indexes", [])) for table_data in tables_data.values())
    total_foreign_keys = sum(len(table_data.get("foreign_keys", [])) for table_data in tables_data.values())
    
    elapsed = time.time() - overall_start
    log(f"Process completed in {elapsed:.2f} seconds")
    log(f"Output summary:")
    log(f"  - {len(tables_data)} total tables")
    log(f"  - {total_columns} total columns")
    log(f"  - {total_indexes} total indexes")
    log(f"  - {total_foreign_keys} total foreign keys")
    log(f"Formatted table definitions saved to: {output_file}")

if __name__ == "__main__":
    main()