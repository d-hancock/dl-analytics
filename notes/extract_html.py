import pdfplumber
import os
import json
import re
import base64
from pathlib import Path
import html
import csv
# Use current directory for relative paths
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
CACHE_FILE = CURRENT_DIR / "table_definitions_cache.json"
PDF_FILE = CURRENT_DIR / "CareTend Data Dictionary OLTP DB.pdf"

# Load cache if it exists
def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            return json.load(f)
    return {}

# Save cache to file
def save_cache(cache):
    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=4)

# Check if a table contains the specified table name
def is_table_match(table, table_name):
    # Convert to lowercase for case-insensitive matching
    table_name_lower = table_name.lower()
    
    # Check all cells in the table for the table name
    for row in table:
        for cell in row:
            if cell and isinstance(cell, str) and table_name_lower in cell.lower():
                return True
    return False

# Extract tables from PDF and convert to HTML
def extract_table_to_html(table_name):
    cache = load_cache()

    # Check if table is already cached
    if table_name in cache:
        print(f"Found cached table: {table_name}")
        return cache[table_name]

    found_tables = []
    with pdfplumber.open(PDF_FILE) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            tables = page.extract_tables()
            for table_idx, table in enumerate(tables):
                if is_table_match(table, table_name):
                    # Create an HTML table with better formatting
                    html_table = f"<h3>Table found on page {page_num}</h3>\n"
                    html_table += "<table border='1' cellpadding='5'>\n"
                    
                    # Add header row with proper formatting
                    if table and len(table) > 0:
                        html_table += "  <tr style='background-color: #f2f2f2; font-weight: bold;'>\n"
                        for header in table[0]:
                            cell_content = header or "&nbsp;"  # Replace None with empty space
                            html_table += f"    <th>{cell_content}</th>\n"
                        html_table += "  </tr>\n"
                    
                    # Add data rows
                    for row in table[1:]:  # Skip header row
                        html_table += "  <tr>\n"
                        for cell in row:
                            cell_content = cell or "&nbsp;"  # Replace None with empty space
                            html_table += f"    <td>{cell_content}</td>\n"
                        html_table += "  </tr>\n"
                    
                    html_table += "</table>"
                    found_tables.append(html_table)

    if found_tables:
        # Join all found tables with separators
        result = "<div>\n" + "\n<hr/>\n".join(found_tables) + "\n</div>"
        
        # Cache the result
        cache[table_name] = result
        save_cache(cache)
        
        return result

    raise ValueError(f"Table '{table_name}' not found in PDF.")

def extract_and_save_tables_to_combined_csv(schema_table_name, combined_csv_path):
    """
    Extracts the columns table, index table, and foreign keys table for a given [schema].[table]
    and appends them to a single combined CSV file for searchability.
    
    Note: Accounts for the PDF having two unnumbered pages before the page numbering starts.
    """
    try:
        # Extract the HTML for the specified table
        html_output = extract_table_to_html(schema_table_name)

        # Parse the HTML to identify the relevant tables
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html_output, 'html.parser')

        # Define the table types to extract
        table_types = ['Columns', 'Indexes', 'Foreign Keys']
        
        # Check if the CSV file exists, if not create it with headers
        file_exists = os.path.isfile(combined_csv_path)
        
        # Open the combined CSV file in append mode
        with open(combined_csv_path, 'a', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            
            # Write header if file doesn't exist
            if not file_exists:
                writer.writerow(['Schema.Table', 'Table Type', 'PDF Page', 'Column 1', 'Column 2', 'Column 3', 'Column 4', 'Column 5', 'Column 6', 'Column 7', 'Column 8'])

            # Iterate over all tables in the HTML
            table_count = 0
            for table in soup.find_all('table'):
                # Get the page number from the preceding heading
                page_heading = table.find_previous('h3')
                page_num = "Unknown"
                if page_heading:
                    # Extract page number from the heading text
                    page_match = re.search(r'page (\d+)', page_heading.text, re.IGNORECASE)
                    if page_match:
                        # Adjust page number to account for the two unnumbered pages
                        actual_page = int(page_match.group(1)) - 2
                        if actual_page > 0:
                            page_num = str(actual_page)
                        else:
                            page_num = "Front Matter"
                
                # Determine the table type based on content or table count
                table_type = "Unknown"
                if table_count == 0:
                    table_type = "Columns"
                elif table_count == 1:
                    table_type = "Indexes"
                elif table_count == 2:
                    table_type = "Foreign Keys"
                
                # Extract rows from the table
                rows = []
                for row in table.find_all('tr'):
                    cells = [cell.get_text(strip=True) for cell in row.find_all(['th', 'td'])]
                    # Add schema.table, table type, and page number as the first columns
                    writer.writerow([schema_table_name, table_type, page_num] + cells)
                
                table_count += 1

        print(f"Saved table data for {schema_table_name} to {combined_csv_path}")
        return True

    except ValueError as e:
        print(f"Error extracting tables for {schema_table_name}: {e}")
        return False

def extract_all_tables_to_combined_csv(combined_csv_path):
    """
    Extracts all tables (columns, indexes, and foreign keys) from the documentation
    and appends them to a single combined CSV file for searchability.
    """
    try:
        # Create a new CSV file with headers
        with open(combined_csv_path, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['Schema.Table', 'Table Type', 'PDF Page', 'Column 1', 'Column 2', 'Column 3', 'Column 4', 'Column 5', 'Column 6', 'Column 7', 'Column 8'])

        # Find all schema.table names by scanning the PDF
        schema_table_patterns = []
        with pdfplumber.open(PDF_FILE) as pdf:
            for page_num, page in enumerate(pdf.pages, 1):
                text = page.extract_text()
                if text:
                    # Look for patterns like [schema].[table] or schema.table
                    matches = re.findall(r'(\[\w+\]\.\[\w+\]|\w+\.\w+)', text)
                    for match in matches:
                        # Clean up the pattern (remove square brackets)
                        clean_match = re.sub(r'[\[\]]', '', match)
                        if clean_match not in schema_table_patterns:
                            schema_table_patterns.append(clean_match)

        # Process each schema.table
        success_count = 0
        for schema_table_name in schema_table_patterns:
            try:
                if extract_and_save_tables_to_combined_csv(schema_table_name, combined_csv_path):
                    success_count += 1
            except Exception as e:
                print(f"Error processing {schema_table_name}: {e}")

        print(f"Extracted {success_count} tables out of {len(schema_table_patterns)} found patterns")
        return combined_csv_path

    except Exception as e:
        print(f"An error occurred while extracting all tables: {e}")
        return None

# List all potential table names in the PDF
def list_potential_tables():
    potential_tables = []
    
    with pdfplumber.open(PDF_FILE) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            # Extract text and look for table identifiers
            text = page.extract_text()
            if text:
                # Look for table headers or specific formatting
                table_matches = re.findall(r'Table\s+\d+[\.\:]\s+([^\n]+)', text, re.IGNORECASE)
                potential_tables.extend([(match, page_num) for match in table_matches])
                
                # Also extract title-like text
                title_matches = re.findall(r'^([A-Z][A-Za-z\s]+)\s*$', text, re.MULTILINE)
                potential_tables.extend([(match, page_num) for match in title_matches if len(match) > 5])
    
    return potential_tables

# Extract all tables from PDF and save as HTML
def extract_all_tables():
    all_tables = []
    
    with pdfplumber.open(PDF_FILE) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            tables = page.extract_tables()
            for table_idx, table in enumerate(tables):
                if not table or len(table) < 2:  # Skip empty tables
                    continue
                    
                # Determine a table name from the contents if possible
                table_name = f"Table_Page{page_num}_{table_idx}"
                
                # Create HTML for this table
                html_table = f"<h3>{table_name} (Page {page_num})</h3>\n"
                html_table += "<table border='1' cellpadding='5'>\n"
                
                # Add header row with proper formatting
                html_table += "  <tr style='background-color: #f2f2f2; font-weight: bold;'>\n"
                for header in table[0]:
                    cell_content = header or "&nbsp;"
                    html_table += f"    <th>{cell_content}</th>\n"
                html_table += "  </tr>\n"
                
                # Add data rows
                for row in table[1:]:
                    html_table += "  <tr>\n"
                    for cell in row:
                        cell_content = cell or "&nbsp;"
                        html_table += f"    <td>{cell_content}</td>\n"
                    html_table += "  </tr>\n"
                
                html_table += "</table>\n"
                all_tables.append((table_name, html_table))
                
    # Save all tables to cache
    cache = load_cache()
    for name, html in all_tables:
        cache[name] = html
    save_cache(cache)
    
    return all_tables

# Save all tables to individual HTML files
def save_all_tables_to_files():
    all_tables = extract_all_tables()
    output_dir = CURRENT_DIR / "table_html"
    output_dir.mkdir(exist_ok=True)
    
    index_content = "<html><body><h1>Table Index</h1><ul>\n"
    
    for name, html in all_tables:
        # Create a valid filename
        filename = re.sub(r'[^\w]', '_', name) + ".html"
        filepath = output_dir / filename
        
        with open(filepath, "w") as f:
            f.write(f"<html><body>\n{html}\n</body></html>")
        
        index_content += f"<li><a href='{filename}'>{name}</a></li>\n"
    
    index_content += "</ul></body></html>"
    with open(output_dir / "index.html", "w") as f:
        f.write(index_content)
    
    return len(all_tables), output_dir

# Convert a PDF page to HTML
def convert_page_to_html(page, page_num):
    """Convert a single PDF page to HTML with text and tables."""
    
    # Create container for the page with CSS for layout
    page_html = f"""
    <div class="pdf-page" id="page-{page_num}" style="margin-bottom: 20px; border-bottom: 1px solid #ccc; padding-bottom: 20px;">
        <div class="page-header">
            <h2>Page {page_num}</h2>
        </div>
        <div class="page-content">
    """
    
    # Extract text content
    text = page.extract_text()
    if text:
        # Process text to preserve some formatting (paragraphs, etc.)
        paragraphs = text.split('\n\n')
        for paragraph in paragraphs:
            if paragraph.strip():
                # Check if this looks like a heading
                if re.match(r'^[A-Z][A-Z\s]+$', paragraph.strip()):
                    page_html += f'<h3>{html.escape(paragraph.strip())}</h3>\n'
                else:
                    # Replace single newlines with breaks
                    formatted_paragraph = paragraph.replace('\n', '<br>\n')
                    page_html += f'<p>{html.escape(formatted_paragraph)}</p>\n'
    
    # Extract and insert tables
    tables = page.extract_tables()
    for table_idx, table in enumerate(tables):
        if not table or len(table) < 1:  # Skip empty tables
            continue
            
        page_html += f'<div class="table-container">\n'
        page_html += f'<table border="1" cellpadding="5" class="pdf-table">\n'
        
        # Determine if first row is header
        if table and len(table) > 0:
            page_html += '  <tr style="background-color: #f2f2f2; font-weight: bold;">\n'
            for header in table[0]:
                cell_content = header or "&nbsp;"
                page_html += f'    <th>{html.escape(cell_content) if isinstance(cell_content, str) else "&nbsp;"}</th>\n'
            page_html += '  </tr>\n'
        
        # Add data rows
        for row in table[1:]:
            page_html += '  <tr>\n'
            for cell in row:
                cell_content = cell or "&nbsp;"
                page_html += f'    <td>{html.escape(cell_content) if isinstance(cell_content, str) else "&nbsp;"}</td>\n'
            page_html += '  </tr>\n'
        
        page_html += '</table>\n'
        page_html += '</div>\n'
    
    # Try to extract images if available
    try:
        for img_idx, img in enumerate(page.images):
            img_data = img["stream"].get_data()
            img_ext = guess_image_extension(img_data)
            img_b64 = base64.b64encode(img_data).decode('utf-8')
            img_src = f"data:image/{img_ext};base64,{img_b64}"
            page_html += f'<div class="image-container">\n'
            page_html += f'<img src="{img_src}" alt="Image on page {page_num}" />\n'
            page_html += '</div>\n'
    except Exception as e:
        page_html += f'<!-- Error extracting images: {str(e)} -->\n'
    
    # Close page containers
    page_html += '</div></div>\n'
    return page_html

def guess_image_extension(image_data):
    """Try to guess the image file extension based on the binary data"""
    if image_data.startswith(b'\x89PNG'):
        return 'png'
    elif image_data.startswith(b'\xff\xd8'):
        return 'jpeg'
    else:
        return 'png'  # Default to PNG

# Convert entire PDF to HTML
def convert_pdf_to_html(pdf_path=None, output_path=None):
    """Convert the entire PDF to a single HTML file with CSS styling"""
    if pdf_path is None:
        pdf_path = PDF_FILE
    
    if output_path is None:
        pdf_filename = os.path.basename(pdf_path)
        pdf_name = os.path.splitext(pdf_filename)[0]
        output_path = CURRENT_DIR / f"{pdf_name}.html"
    
    # Start creating the HTML document with CSS
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PDF Document</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .pdf-page {
            max-width: 800px;
            margin: 0 auto 30px auto;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            background-color: white;
        }
        .page-header {
            border-bottom: 1px solid #eee;
            margin-bottom: 15px;
            padding-bottom: 10px;
        }
        .page-content {
            margin-top: 15px;
        }
        table.pdf-table {
            border-collapse: collapse;
            width: 100%;
            margin: 15px 0;
        }
        table.pdf-table th, table.pdf-table td {
            padding: 8px;
            text-align: left;
            vertical-align: top;
        }
        table.pdf-table th {
            background-color: #f2f2f2;
        }
        table.pdf-table tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .image-container {
            margin: 15px 0;
            text-align: center;
        }
        .image-container img {
            max-width: 100%;
            height: auto;
        }
        .navigation {
            position: fixed;
            top: 10px;
            right: 10px;
            background: white;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .toc {
            margin: 20px 0;
            padding: 15px;
            background: #f9f9f9;
            border: 1px solid #ddd;
        }
        @media print {
            .navigation {
                display: none;
            }
            .pdf-page {
                box-shadow: none;
                margin: 0;
                padding: 0;
            }
            body {
                padding: 0;
            }
        }
    </style>
</head>
<body>
    <div class="navigation">
        <a href="#toc">Table of Contents</a>
    </div>
    <h1>PDF Document Conversion</h1>
    <div class="toc" id="toc">
        <h2>Table of Contents</h2>
        <ul>
"""

    # Process the PDF
    with pdfplumber.open(pdf_path) as pdf:
        # First pass: build table of contents
        for page_num, _ in enumerate(pdf.pages, 1):
            html_content += f'            <li><a href="#page-{page_num}">Page {page_num}</a></li>\n'
        
        html_content += """        </ul>
    </div>
    <div class="content">
"""
        
        # Second pass: convert each page
        for page_num, page in enumerate(pdf.pages, 1):
            print(f"Converting page {page_num} of {len(pdf.pages)}...")
            page_html = convert_page_to_html(page, page_num)
            html_content += page_html
    
    # Close the HTML document
    html_content += """    </div>
    <script>
        // Add simple navigation functionality
        document.addEventListener('DOMContentLoaded', function() {
            // Nothing complex needed for now
        });
    </script>
</body>
</html>"""

    # Write to file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"PDF successfully converted to HTML: {output_path}")
    return output_path

# Command-line interface
def main():
    import argparse

    parser = argparse.ArgumentParser(description="Extract tables from PDF and convert to HTML.")
    parser.add_argument("--table", help="Name of the table to extract.")
    parser.add_argument("--list", action="store_true", help="List all potential table names in the PDF.")
    parser.add_argument("--extract-all", action="store_true", help="Extract all tables and save to HTML files.")
    parser.add_argument("--clear-cache", action="store_true", help="Clear the cache before processing.")
    parser.add_argument("--full-pdf", action="store_true", help="Convert entire PDF to HTML.")
    parser.add_argument("--pdf-file", help="Path to the PDF file to process.")
    parser.add_argument("--output", help="Path for the output HTML file.")
    args = parser.parse_args()

    # Set the PDF file path if provided
    pdf_path = args.pdf_file if args.pdf_file else PDF_FILE

    if args.clear_cache and os.path.exists(CACHE_FILE):
        os.remove(CACHE_FILE)
        print(f"Cache cleared: {CACHE_FILE}")

    if args.list:
        tables = list_potential_tables()
        print(f"Found {len(tables)} potential table references:")
        for table_name, page in tables:
            print(f"- {table_name} (Page {page})")
    
    elif args.extract_all:
        count, output_dir = save_all_tables_to_files()
        print(f"Extracted {count} tables to {output_dir}")
        print(f"View the index at {output_dir}/index.html")
        
    elif args.full_pdf:
        output_path = args.output if args.output else None
        output_file = convert_pdf_to_html(pdf_path, output_path)
        print(f"Full PDF converted to HTML: {output_file}")
        
    elif args.table:
        try:
            html_output = extract_table_to_html(args.table)
            print(html_output)
            
            # Also save to a file for convenience
            output_file = CURRENT_DIR / f"{args.table.replace(' ', '_')}.html"
            with open(output_file, "w") as f:
                f.write(f"<html><body>\n{html_output}\n</body></html>")
            print(f"Table also saved to {output_file}")
            
        except ValueError as e:
            print(e)
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main()