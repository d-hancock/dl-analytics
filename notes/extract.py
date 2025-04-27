#!/usr/bin/env python3
# filepath: /home/dale/development/dl-analytics/notes/extract.py
# Purpose: Extract table column definitions from CareTend Data Dictionary PDF
import re
import sys
import PyPDF2
import os
import csv
import os.path
from datetime import datetime

PDF = "CareTend Data Dictionary OLTP DB.pdf"
PAGE_OFFSET = 2  # PDF page 3 corresponds to document page 1 (offset of 2)
CACHE_FILE = "table_definitions_cache.csv"

def find_table_of_contents(reader):
    """Find and parse the Table of Contents to get table names and their page numbers"""
    print("Searching for Table of Contents...")
    toc_entries = []
    
    # Look for TOC in first 20 pages
    for i in range(min(20, len(reader.pages))):
        page = reader.pages[i]
        text = page.extract_text() or ""
        
        if "Table of Contents" in text:
            print(f"Found Table of Contents on PDF page {i+1}")
            
            # Parse multiple pages of TOC if necessary
            current_page = i
            while current_page < len(reader.pages):
                toc_page_text = reader.pages[current_page].extract_text() or ""
                
                # Look for table entries in TOC - pattern: [Schema].[Table]..........###
                toc_matches = re.findall(r'(\[\w+\]\.\[\w+\]|\w+\.\w+)\.+(\d+)', toc_page_text)
                
                if toc_matches:
                    for table_name, page_num in toc_matches:
                        doc_page = int(page_num)
                        pdf_page = doc_page + PAGE_OFFSET
                        toc_entries.append((table_name, pdf_page))
                    
                    print(f"  Found {len(toc_matches)} table entries on TOC page {current_page+1}")
                    current_page += 1
                else:
                    # If we don't find any more TOC entries, we're done with the TOC
                    break
            
            break
    
    print(f"Found {len(toc_entries)} tables in Table of Contents")
    return toc_entries

def scan_tables_in_pdf(debug=False):
    """Scan the PDF for potential table names and return a list of found tables"""
    if not os.path.exists(PDF):
        print(f"Error: PDF file '{PDF}' not found in {os.getcwd()}")
        return []

    try:
        reader = PyPDF2.PdfReader(open(PDF, "rb"))
        print(f"Scanning PDF ({len(reader.pages)} pages) for table definitions...")
        
        # First try to get tables from TOC for more accurate page numbers
        toc_tables = find_table_of_contents(reader)
        if toc_tables:
            if debug:
                print("Using Table of Contents for table lookup")
            return toc_tables
        
        # If TOC parsing failed, fall back to page-by-page scanning
        print("Table of Contents parsing failed or incomplete, falling back to page scanning...")
        tables_found = []
        
        for p, page in enumerate(reader.pages):
            if p % 100 == 0:  # Progress indicator
                print(f"  Scanning page {p} of {len(reader.pages)}")
                
            text = page.extract_text() or ""
            
            # Look for header patterns that might indicate a table definition
            if "Table Name:" in text or "Tables:" in text or "Table:" in text:
                # Extract potential table name - different patterns to try
                table_match = None
                
                # Check for pattern: "Table Name: [Schema].[Table]"
                match = re.search(r'Table Name:\s*(\[\w+\]\.\[\w+\]|\w+\.\w+)', text)
                if match:
                    table_match = match.group(1)
                
                # If not found, try other formats
                if not table_match:
                    match = re.search(r'Table:\s*(\[\w+\]\.\[\w+\]|\w+\.\w+)', text)
                    if match:
                        table_match = match.group(1)
                
                # If still not found, try to find any schema.table pattern
                if not table_match:
                    matches = re.findall(r'(\[\w+\]\.\[\w+\]|\w+\.\w+)', text)
                    if matches:
                        table_match = matches[0]
                
                if table_match:
                    tables_found.append((table_match, p))
                    if debug:
                        print(f"Found potential table: {table_match} on page {p+1}")
        
        print(f"Scan complete. Found {len(tables_found)} potential table definitions.")
        return tables_found
        
    except Exception as e:
        print(f"Error scanning PDF: {e}")
        import traceback
        traceback.print_exc()
        return []

def load_cache():
    """Load the table definitions cache from CSV file"""
    cache = {}
    if not os.path.exists(CACHE_FILE):
        return cache
    
    try:
        with open(CACHE_FILE, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.reader(csvfile)
            next(reader)  # Skip header
            for row in reader:
                if len(row) >= 3:
                    table_name = row[0]
                    page_num = int(row[1])
                    definition = row[2]
                    cache[table_name.lower()] = (table_name, page_num, definition)
        print(f"Loaded {len(cache)} table definitions from cache")
        return cache
    except Exception as e:
        print(f"Error loading cache: {e}")
        return {}

def save_to_cache(table_name, page_num, definition):
    """Save a table definition to the cache CSV file"""
    try:
        file_exists = os.path.exists(CACHE_FILE)
        with open(CACHE_FILE, 'a', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            if not file_exists:
                writer.writerow(['TableName', 'PageNumber', 'Definition', 'ExtractedDate'])
            writer.writerow([table_name, page_num, definition, datetime.now().strftime('%Y-%m-%d %H:%M:%S')])
        return True
    except Exception as e:
        print(f"Error saving to cache: {e}")
        return False

def extract_table_definition(reader, page_num):
    """Extract the column definition from a specific page"""
    if page_num >= len(reader.pages):
        return None
    
    text = reader.pages[page_num].extract_text() or ""
    lines = text.splitlines()
    
    # Find column header line (e.g., "Key Name Data Type...")
    column_section = []
    found_header = False
    
    for i, line in enumerate(lines):
        if "Key" in line and "Name" in line and ("Data Type" in line or "DataType" in line):
            found_header = True
            column_section.append(line)
            
            # Get the lines after the header
            j = i + 1
            while j < len(lines) and len(column_section) < 30:
                if lines[j].strip():
                    column_section.append(lines[j].strip())
                j += 1
            break
    
    if found_header:
        return "\n".join(column_section)
    
    # If we didn't find a standard header, try to get any relevant content
    for pattern in ["Columns", "Column", "Fields", "Field"]:
        if pattern in text:
            idx = text.find(pattern)
            if idx > 0:
                return text[idx:idx+1000]  # Return a chunk of text after the pattern
    
    return None

def grab(table, debug=False):
    """
    Extract column information for a specific table from the PDF.
    
    Args:
        table (str): The table name to search for (e.g. "[Utilities].[Date]")
        debug (bool): Whether to print debug information
    
    Returns:
        bool: True if the table was found, False otherwise
    """
    print(f"Searching for table: {table}")
    
    # Check if PDF exists
    if not os.path.exists(PDF):
        print(f"Error: PDF file '{PDF}' not found in {os.getcwd()}")
        return False
    
    # First check the cache
    cache = load_cache()
    table_key = table.strip().lower()
    
    if table_key in cache:
        orig_name, page_num, definition = cache[table_key]
        print(f"Found table in cache: {orig_name} (page {page_num+1})")
        print(f"\n=== {orig_name} (page {page_num+1}) [CACHED] ===")
        print(definition)
        return True
    
    try:
        reader = PyPDF2.PdfReader(open(PDF, "rb"))
        print(f"PDF loaded successfully: {len(reader.pages)} pages")
        
        # Check if this table is in our TOC-based lookup
        tables = scan_tables_in_pdf(debug=debug)
        table_normalized = table.strip().lower()
        
        # Find matching table in our tables list
        target_pages = []
        found_table_name = table
        for table_name, page_num in tables:
            if table_name.lower() == table_normalized or table_name.lower().replace('[', '').replace(']', '') == table_normalized.replace('[', '').replace(']', ''):
                target_pages.append(page_num)
                found_table_name = table_name
                print(f"Found table '{table_name}' in table lookup, expected on PDF page {page_num+1}")
        
        # If we found pages to check in the TOC
        if target_pages:
            for page_num in target_pages:
                if page_num < len(reader.pages):
                    definition = extract_table_definition(reader, page_num)
                    
                    if definition:
                        print(f"Found column information on page {page_num+1}")
                        print(f"\n=== {found_table_name} (page {page_num+1}) ===")
                        print(definition)
                        
                        # Save to cache
                        save_to_cache(found_table_name, page_num, definition)
                        return True
        
        # Fall back to scanning the whole document if we didn't find it in TOC
        print("Table not found in lookup or column info not found on target page, scanning full document...")
        
        # Normalize table name for more flexible matching
        table_normalized = table.strip().replace('[', '').replace(']', '').lower()
        
        for p, page in enumerate(reader.pages):
            if p % 100 == 0 and debug:  # Progress indicator in debug mode
                print(f"  Checking page {p} of {len(reader.pages)}")
                
            text = page.extract_text() or ""
            text_lower = text.lower()
            
            # Check if this page contains our table
            if table.lower() in text_lower or table_normalized in text_lower:
                print(f"Found potential table match on page {p+1}")
                
                # Look for column definitions section
                column_patterns = [
                    "Columns:", "Column Name", "Column Names", 
                    "Field", "Fields", "Key", "Name", "Data Type"
                ]
                
                for pattern in column_patterns:
                    if pattern in text:
                        print(f"Found '{pattern}' pattern on page {p+1}")
                        
                        definition = extract_table_definition(reader, p)
                        if definition:
                            print(f"\n=== {table} (page {p+1}) ===")
                            print(definition)
                            
                            # Save to cache
                            save_to_cache(table, p, definition)
                            return True
        
        print(f"No column information found for table '{table}'")
        
        # If table not found, suggest looking at tables in the PDF
        if debug:
            print("\nThe following tables were found in the PDF:")
            for table_name, page_num in tables[:10]:  # Show first 10
                print(f"  - {table_name} (page {page_num+1})")
            if len(tables) > 10:
                print(f"  - ...and {len(tables)-10} more")
                
        return False
        
    except Exception as e:
        print(f"Error processing PDF: {e}")
        import traceback
        traceback.print_exc()
        return False

def export_all_tables_to_csv(output_file=None):
    """
    Extract all tables from the PDF and export them to a CSV file
    
    Args:
        output_file (str): Optional filename for the output CSV file
    """
    if output_file is None:
        output_file = "all_table_definitions.csv"
    
    print(f"Exporting all table definitions to {output_file}...")
    
    try:
        reader = PyPDF2.PdfReader(open(PDF, "rb"))
        tables = scan_tables_in_pdf(debug=False)
        
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['TableName', 'PageNumber', 'Definition', 'ExtractedDate'])
            
            for i, (table_name, page_num) in enumerate(tables):
                print(f"Processing {i+1}/{len(tables)}: {table_name}")
                
                definition = extract_table_definition(reader, page_num)
                if definition:
                    writer.writerow([
                        table_name, 
                        page_num, 
                        definition,
                        datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    ])
        
        print(f"Export completed. Saved to {output_file}")
        return True
        
    except Exception as e:
        print(f"Error exporting tables: {e}")
        import traceback
        traceback.print_exc()
        return False

def list_tables(max_tables=20):
    """List tables found in the PDF"""
    tables = scan_tables_in_pdf(debug=False)
    print(f"\nFound {len(tables)} potential tables in the PDF:")
    for i, (table_name, page_num) in enumerate(tables):
        if i < max_tables:
            print(f"{i+1}. {table_name} (page {page_num+1})")
        else:
            remaining = len(tables) - max_tables
            print(f"...and {remaining} more tables")
            break
    return tables

def process_table_list(file_path):
    """Process a list of tables from a file"""
    if not os.path.exists(file_path):
        print(f"Error: Table list file '{file_path}' not found")
        return False
        
    try:
        with open(file_path, 'r') as f:
            tables = [line.strip() for line in f if line.strip()]
            
        print(f"Processing {len(tables)} tables from {file_path}")
        for table in tables:
            grab(table, debug=False)
            print("\n" + "-"*50 + "\n")
        
        return True
    except Exception as e:
        print(f"Error processing table list: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <table_name> [--debug] [--list] [--export] [--process-list <file>]")
        print("  <table_name>: The name of the table to search for (e.g. \"[Utilities].[Date]\")")
        print("  --debug: Enable debug output")
        print("  --list: List tables found in the PDF")
        print("  --export: Export all table definitions to CSV")
        print("  --process-list <file>: Process a list of tables from a file (one table name per line)")
        print("Examples:")
        print("  python extract.py \"[Utilities].[Date]\" --debug")
        print("  python extract.py --list")
        print("  python extract.py --export")
        print("  python extract.py --process-list tables.txt")
        sys.exit(1)
    
    if "--list" in sys.argv:
        list_tables()
        sys.exit(0)
        
    if "--export" in sys.argv:
        output_file = None
        export_index = sys.argv.index("--export")
        if export_index + 1 < len(sys.argv) and not sys.argv[export_index + 1].startswith("--"):
            output_file = sys.argv[export_index + 1]
        export_all_tables_to_csv(output_file)
        sys.exit(0)
        
    if "--process-list" in sys.argv:
        list_index = sys.argv.index("--process-list")
        if list_index + 1 < len(sys.argv):
            file_path = sys.argv[list_index + 1]
            process_table_list(file_path)
            sys.exit(0)
        else:
            print("Error: No file specified for --process-list")
            sys.exit(1)
        
    debug_mode = "--debug" in sys.argv
    tables = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    
    for t in tables:
        grab(t, debug=debug_mode)
