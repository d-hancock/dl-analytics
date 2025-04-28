import json
import re
import os
from pathlib import Path
from bs4 import BeautifulSoup
import csv

# Use current directory for relative paths
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
HTML_FILE = CURRENT_DIR / "CareTend Data Dictionary OLTP DB.html"
OUTPUT_CSV_FILE = CURRENT_DIR / "all_table_references.csv"

def clean_schema_table_name(name):
    """Standardize schema.table name format by removing brackets and extra whitespace."""
    return name.replace('[', '').replace(']', '').strip()

def extract_tables_from_toc():
    """
    Extract a comprehensive list of all schema.table references from the document,
    with special attention to the table of contents and headings.
    """
    if not HTML_FILE.exists():
        print(f"Error: HTML file not found at {HTML_FILE}")
        print("Please run the --full-pdf option in extract_html.py first.")
        return []

    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    
    # Regular expression to match schema.table patterns
    schema_table_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)')
    
    # Find table references in the document
    table_references = {}
    
    # First check the table of contents specifically
    toc_element = soup.find(id='toc')
    if toc_element:
        print("Found table of contents! Extracting references...")
        toc_links = toc_element.find_all('a')
        for link in toc_links:
            text = link.get_text(strip=True)
            matches = schema_table_regex.findall(text)
            for match in matches:
                cleaned_name = clean_schema_table_name(match)
                href = link.get('href', '')
                page_number = href.replace('#page-', '')
                table_references[cleaned_name] = {
                    'source': 'toc',
                    'page': page_number,
                    'context': text
                }
                print(f"Found in TOC: {cleaned_name} on page {page_number}")
    
    # Now check all headings (h1-h5) which often contain table names
    for heading_tag in ['h1', 'h2', 'h3', 'h4', 'h5']:
        headings = soup.find_all(heading_tag)
        for heading in headings:
            text = heading.get_text(strip=True)
            matches = schema_table_regex.findall(text)
            for match in matches:
                cleaned_name = clean_schema_table_name(match)
                
                # Find which page this heading is on
                page_element = heading.find_parent(class_='pdf-page')
                page_number = "Unknown"
                if page_element and page_element.get('id'):
                    page_number = page_element.get('id').replace('page-', '')
                
                # Only add if not already found in TOC
                if cleaned_name not in table_references:
                    table_references[cleaned_name] = {
                        'source': f'heading-{heading_tag}',
                        'page': page_number,
                        'context': text
                    }
                    print(f"Found in {heading_tag}: {cleaned_name} on page {page_number}")
    
    # Finally check all other content for table references
    all_text_elements = soup.find_all(['p', 'div', 'span', 'td', 'th'])
    for element in all_text_elements:
        # Skip if it's inside the TOC (we already processed it)
        if toc_element and toc_element in element.parents:
            continue
            
        text = element.get_text(strip=True)
        matches = schema_table_regex.findall(text)
        for match in matches:
            cleaned_name = clean_schema_table_name(match)
            
            # Only add if not already found
            if cleaned_name not in table_references:
                # Find which page this text is on
                page_element = element.find_parent(class_='pdf-page')
                page_number = "Unknown"
                if page_element and page_element.get('id'):
                    page_number = page_element.get('id').replace('page-', '')
                
                table_references[cleaned_name] = {
                    'source': 'content',
                    'page': page_number,
                    'context': text[:100] + ('...' if len(text) > 100 else '')
                }
                print(f"Found in content: {cleaned_name} on page {page_number}")
    
    # Count by schema
    schemas = {}
    for table_name in table_references.keys():
        schema = table_name.split('.')[0] if '.' in table_name else 'Unknown'
        schemas[schema] = schemas.get(schema, 0) + 1
    
    print("\nTables found by schema:")
    for schema, count in sorted(schemas.items()):
        print(f"{schema}: {count} tables")
    
    return table_references

def save_to_csv(table_references):
    """Save the extracted table references to a CSV file"""
    with open(OUTPUT_CSV_FILE, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['schema_table', 'schema', 'table', 'source', 'page', 'context']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for table_name, data in sorted(table_references.items()):
            schema = table_name.split('.')[0] if '.' in table_name else 'Unknown'
            table = table_name.split('.')[1] if '.' in table_name and len(table_name.split('.')) > 1 else table_name
            
            writer.writerow({
                'schema_table': table_name,
                'schema': schema,
                'table': table,
                'source': data['source'],
                'page': data['page'],
                'context': data['context']
            })
    
    print(f"\nSaved {len(table_references)} table references to {OUTPUT_CSV_FILE}")
    return OUTPUT_CSV_FILE

def main():
    print("Extracting tables from table of contents and document...")
    table_references = extract_tables_from_toc()
    
    if table_references:
        csv_file = save_to_csv(table_references)
        print(f"Total unique tables found: {len(table_references)}")
    else:
        print("No tables were found!")

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
    
    main()