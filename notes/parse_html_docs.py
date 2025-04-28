import json
import re
import os
import hashlib
import argparse
import sys
from pathlib import Path
from bs4 import BeautifulSoup

# Use current directory for relative paths
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
HTML_FILE = CURRENT_DIR / "CareTend Data Dictionary OLTP DB.html"
OUTPUT_JSON_FILE = CURRENT_DIR / "extracted_table_definitions.json"
CACHE_FILE = CURRENT_DIR / "table_definitions_cache.csv"

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Extract table definitions from HTML file.')
    parser.add_argument('--force', action='store_true', help='Force regeneration of output regardless of cache status')
    return parser.parse_args()

def get_file_hash(file_path):
    """Calculate SHA-256 hash of a file to detect changes."""
    hasher = hashlib.sha256()
    with open(file_path, 'rb') as f:
        buf = f.read(65536)  # Read in 64k chunks
        while len(buf) > 0:
            hasher.update(buf)
            buf = f.read(65536)
    return hasher.hexdigest()

def check_cache(force_regenerate=False):
    """Check if we need to reprocess the HTML by comparing file hashes."""
    if force_regenerate:
        print("Forcing regeneration of output file...")
        # Update cache with current hash but still return False to force processing
        if HTML_FILE.exists():
            html_hash = get_file_hash(HTML_FILE)
            with open(CACHE_FILE, 'w') as f:
                f.write(html_hash)
        return False
        
    if not HTML_FILE.exists():
        print(f"Error: HTML file not found at {HTML_FILE}")
        return False
        
    html_hash = get_file_hash(HTML_FILE)
    
    # If cache file exists, read the cached hash
    if CACHE_FILE.exists():
        with open(CACHE_FILE, 'r') as f:
            cached_hash = f.read().strip()
        
        # If output file exists and hash matches, no need to reprocess
        if OUTPUT_JSON_FILE.exists() and cached_hash == html_hash:
            print(f"HTML file unchanged since last processing. Using cached data from {OUTPUT_JSON_FILE}")
            return True
    
    # If we reach here, we need to process the file
    # Save the current hash to the cache file
    with open(CACHE_FILE, 'w') as f:
        f.write(html_hash)
    
    return False

def clean_schema_table_name(name):
    """Standardize schema.table name format by removing brackets and extra whitespace."""
    return name.replace('[', '').replace(']', '').strip()

def extract_tables_from_html():
    """Extract a list of all schema.table mentioned in the document."""
    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    
    # Regular expression to match schema.table patterns
    schema_table_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)')
    
    # Find all text content that might contain table references
    all_text_elements = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'p', 'div', 'span'])
    
    table_references = set()
    for element in all_text_elements:
        text = element.get_text(strip=True)
        matches = schema_table_regex.findall(text)
        for match in matches:
            cleaned_name = clean_schema_table_name(match)
            table_references.add(cleaned_name)
    
    return sorted(list(table_references))

def find_table_sections(soup):
    """Find table sections in the HTML document that represent database tables."""
    table_sections = []
    
    # Find all headings that might contain table names
    headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p'])
    schema_table_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)')
    
    for i, heading in enumerate(headings):
        text = heading.get_text(strip=True)
        match = schema_table_regex.search(text)
        
        if match:
            table_name = clean_schema_table_name(match.group(1))
            
            # Determine the end of this section
            next_heading_idx = i + 1
            end_element = None
            while next_heading_idx < len(headings):
                next_text = headings[next_heading_idx].get_text(strip=True)
                if schema_table_regex.search(next_text):
                    end_element = headings[next_heading_idx]
                    break
                next_heading_idx += 1
            
            # Find all HTML tables in this section
            tables = []
            
            # Start from the heading and look for tables
            current = heading.next_element
            while current and current != end_element:
                if hasattr(current, 'name') and current.name == 'table':
                    tables.append(current)
                
                # Move to the next element
                if hasattr(current, 'next_element'):
                    current = current.next_element
                else:
                    break
            
            # Add this section if it contains tables
            if tables:
                table_sections.append({
                    'table_name': table_name,
                    'heading': heading,
                    'tables': tables
                })
    
    return table_sections

def categorize_table(table, global_headers):
    """Determine if a table contains columns, indexes, or foreign keys data."""
    headers = []
    
    # Extract the headers from the table
    header_row = table.find('tr')
    if header_row:
        for th in header_row.find_all(['th', 'td']):
            header_text = th.get_text(strip=True).lower()
            headers.append(header_text)
    
    if not headers:
        return None, headers
    
    # Calculate how many header keywords match each table type
    match_counts = {
        "columns": sum(1 for h in headers if any(kw in h.lower() for kw in global_headers["columns"])),
        "indexes": sum(1 for h in headers if any(kw in h.lower() for kw in global_headers["indexes"])),
        "foreign_keys": sum(1 for h in headers if any(kw in h.lower() for kw in global_headers["foreign_keys"]))
    }
    
    # Determine the most likely table type based on matching headers
    if match_counts["columns"] >= 2:
        return "columns", headers
    elif match_counts["indexes"] >= 2:
        return "indexes", headers
    elif match_counts["foreign_keys"] >= 2:
        return "foreign_keys", headers
    else:
        return None, headers

def extract_table_data(table):
    """Extract data rows from an HTML table."""
    rows = []
    
    # Skip the header row and extract data rows
    data_rows = table.find_all('tr')[1:] if table.find('tr') else []
    
    for row in data_rows:
        cells = [td.get_text(strip=True) for td in row.find_all('td')]
        if cells and any(cells):  # Skip empty rows
            rows.append(cells)
    
    return rows

def extract_definitions_from_html(force_regenerate=False):
    """Extracts table definitions from the HTML file and saves to JSON."""
    # Check if we need to process the file or can use cached data
    if check_cache(force_regenerate):
        return
        
    if not HTML_FILE.exists():
        print(f"Error: HTML file not found at {HTML_FILE}")
        print("Please run the --full-pdf option in extract_html.py first.")
        return

    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    # Define the expected headers for different table types
    global_headers = {
        "columns": ["key", "name", "data type", "max length (bytes)", "identity"],
        "indexes": ["key", "name", "key columns", "unique", "page locks", "no recompute"],
        "foreign_keys": ["fk name", "referenced table", "referenced column"]
    }

    # Initialize the output data structure
    extracted_data = {
        "global_headers": global_headers,
        "tables": {}
    }

    # First, extract all potential table references from the document
    all_tables = extract_tables_from_html()
    print(f"Found {len(all_tables)} potential table references in the document.")

    # Initialize data structure for all tables
    for table_name in all_tables:
        extracted_data["tables"][table_name] = {
            "columns": [],
            "indexes": [],
            "foreign_keys": [],
            "other_tables": []
        }

    # Find all table sections in the document
    table_sections = find_table_sections(soup)
    print(f"Found {len(table_sections)} table sections with actual table data.")

    # Process each table section
    for section in table_sections:
        table_name = section['table_name']
        print(f"Processing table: {table_name}")
        
        # Process each table in this section
        for table in section['tables']:
            # Categorize the table and get its data
            table_type, headers = categorize_table(table, global_headers)
            data_rows = extract_table_data(table)
            
            if not data_rows:
                continue  # Skip tables with no data rows
            
            # Add the data to the appropriate section of the output
            if table_name not in extracted_data["tables"]:
                extracted_data["tables"][table_name] = {
                    "columns": [],
                    "indexes": [],
                    "foreign_keys": [],
                    "other_tables": []
                }
            
            if table_type:
                extracted_data["tables"][table_name][table_type].extend(data_rows)
            else:
                extracted_data["tables"][table_name]["other_tables"].append({
                    "headers": headers,
                    "rows": data_rows
                })
    
    # Remove tables with no data
    tables_to_remove = []
    for table_name, table_data in extracted_data["tables"].items():
        if not any([table_data["columns"], table_data["indexes"], table_data["foreign_keys"], table_data["other_tables"]]):
            tables_to_remove.append(table_name)
    
    for table_name in tables_to_remove:
        del extracted_data["tables"][table_name]
    
    # If we found very few tables with data, try using a direct approach as fallback
    populated_tables = [table for table in extracted_data["tables"].values() 
                    if any([table["columns"], table["indexes"], table["foreign_keys"], table["other_tables"]])]
    
    if len(populated_tables) < 10:
        print("Few tables found with data. Using fallback direct table processing approach.")
        process_tables_directly(soup, extracted_data, global_headers)
    
    print(f"Extracted data for {len(extracted_data['tables'])} tables")
    populated_count = sum(1 for t in extracted_data["tables"].values() 
                      if any([t["columns"], t["indexes"], t["foreign_keys"], t["other_tables"]]))
    print(f"Of which {populated_count} tables have actual data")
    
    print(f"Saving extracted data to: {OUTPUT_JSON_FILE}")
    with open(OUTPUT_JSON_FILE, 'w', encoding='utf-8') as f:
        json.dump(extracted_data, f, indent=4)

    print("Parsing complete.")

def process_tables_directly(soup, extracted_data, global_headers):
    """Process all tables directly, trying to associate them with table names."""
    # Find all tables in the document
    all_tables = soup.find_all('table')
    
    # For each table, try to find which database table it belongs to
    for table in all_tables:
        # Look for table name in preceding elements
        table_name = find_table_name_for_element(table)
        
        if not table_name or table_name not in extracted_data["tables"]:
            continue
        
        # Categorize the table and extract its data
        table_type, headers = categorize_table(table, global_headers)
        data_rows = extract_table_data(table)
        
        if not data_rows:
            continue
        
        # Add the data to the appropriate section
        if table_type:
            extracted_data["tables"][table_name][table_type].extend(data_rows)
        else:
            extracted_data["tables"][table_name]["other_tables"].append({
                "headers": headers,
                "rows": data_rows
            })

def find_table_name_for_element(element):
    """Try to find the table name associated with an HTML element."""
    schema_table_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)')
    
    # Check up to 5 previous siblings for a table name
    current = element.previous_sibling
    for _ in range(5):
        if not current:
            break
            
        if hasattr(current, 'get_text'):
            text = current.get_text(strip=True)
            match = schema_table_regex.search(text)
            if match:
                return clean_schema_table_name(match.group(1))
        
        current = current.previous_sibling
    
    # If no match in siblings, check parent and its previous siblings
    parent = element.parent
    if parent:
        if hasattr(parent, 'get_text'):
            text = parent.get_text(strip=True)
            match = schema_table_regex.search(text)
            if match:
                return clean_schema_table_name(match.group(1))
        
        # Check parent's previous siblings
        current = parent.previous_sibling
        for _ in range(5):
            if not current:
                break
                
            if hasattr(current, 'get_text'):
                text = current.get_text(strip=True)
                match = schema_table_regex.search(text)
                if match:
                    return clean_schema_table_name(match.group(1))
            
            current = current.previous_sibling
    
    return None

if __name__ == "__main__":
    # Ensure BeautifulSoup is installed
    try:
        import bs4
    except ImportError:
        print("BeautifulSoup4 not found. Attempting to install...")
        os.system("pip install beautifulsoup4")
        try:
            import bs4 # Try importing again
        except ImportError:
             print("Failed to install BeautifulSoup4. Please install it manually (`pip install beautifulsoup4`) and rerun the script.")
             exit(1)

    # Parse command line arguments
    args = parse_arguments()
    
    # Extract definitions with the force flag if specified
    extract_definitions_from_html(force_regenerate=args.force)

