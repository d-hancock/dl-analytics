#!/usr/bin/env python3
"""
TOC Extractor - A script that loads a Table of Contents from a CSV file
and creates a proper index of tables for extraction.
"""

import sys
import re
import json
import csv
from pathlib import Path
import pdfplumber

# Constants
PDF_PAGE_OFFSET = 2  # Document page numbers are offset by 2 from PDF page numbers
# TOC_START_PAGE = 3   # No longer needed, reading from CSV
# TOC_END_PAGE = 31    # No longer needed

def clean_table_name(name):
    """Clean table name by removing brackets and standardizing format"""
    result = name.strip()
    result = re.sub(r'\[|\]', '', result)
    return result

def load_toc_from_csv(csv_path):
    """
    Load the table of contents from a CSV file.
    Expects CSV format: Table,DocPage,PdfPage,Schema (header optional)
    or just: Schema.Table,Page
    
    Args:
        csv_path: Path to the CSV file
    
    Returns:
        A list of tuples: [('schema.table', page_num), ...] sorted by page number
    """
    print(f"Loading TOC from CSV: {csv_path}")
    toc_entries = []
    
    try:
        with open(csv_path, 'r', newline='') as csvfile:
            reader = csv.reader(csvfile)
            header = next(reader) # Skip header row
            
            # Determine column indices based on header
            try:
                table_col_idx = header.index('Table')
                page_col_idx = header.index('DocPage')
            except ValueError:
                # Fallback if header doesn't match expected names
                print("Warning: CSV header doesn't match 'Table,DocPage'. Assuming first column is table, second is page.")
                table_col_idx = 0
                page_col_idx = 1

            for row in reader:
                if len(row) > max(table_col_idx, page_col_idx):
                    table_name = row[table_col_idx]
                    page_num_str = row[page_col_idx]
                    try:
                        clean_name = clean_table_name(table_name)
                        page_num_int = int(page_num_str)
                        toc_entries.append((clean_name, page_num_int))
                    except ValueError:
                        print(f"Warning: Skipping invalid row in CSV: {row}")
                else:
                     print(f"Warning: Skipping short row in CSV: {row}")

    except FileNotFoundError:
        print(f"Error: CSV file not found: {csv_path}")
        return []
    except Exception as e:
        print(f"Error reading CSV file {csv_path}: {e}")
        return []

    # Sort by page number just in case CSV wasn't sorted
    toc_entries.sort(key=lambda item: item[1])
    
    # Display analytics
    schemas = {}
    for table_name, _ in toc_entries:
        schema = table_name.split('.')[0] if '.' in table_name else 'unknown'
        schemas[schema] = schemas.get(schema, 0) + 1
    
    print(f"\nLoaded {len(toc_entries)} tables from CSV")
    print("Schema distribution:")
    for schema, count in sorted(schemas.items()):
        print(f"  {schema}: {count} tables")
        
    return toc_entries

def create_extraction_plan(toc_entries):
    """
    Create a detailed extraction plan with page ranges for each table.
    This helps determine where each table starts and ends.
    
    Args:
        toc_entries: List of (table_name, page_num) tuples from TOC
        
    Returns:
        List of dicts with extraction information for each table
    """
    extraction_plan = []
    
    for i, (table_name, page_num) in enumerate(toc_entries):
        # Calculate the ending boundary
        end_marker = None
        if i + 1 < len(toc_entries):
            next_table, next_page = toc_entries[i + 1]
            # Ensure end_marker is in the format [Schema].[Table] if possible
            parts = next_table.split('.')
            if len(parts) == 2:
                end_marker = f"[{parts[0]}].[{parts[1]}]"
            else:
                end_marker = next_table # Fallback if format is unexpected
        
        # Add PDF page offset to get the actual page in the PDF file
        pdf_page = page_num + PDF_PAGE_OFFSET
        
        # Parse schema and table
        parts = table_name.split('.')
        schema = parts[0] if len(parts) > 1 else 'unknown'
        table = parts[1] if len(parts) > 1 else table_name
        
        extraction_plan.append({
            "table_name": table_name,
            "doc_page": page_num,         # Page as listed in document
            "pdf_page": pdf_page,         # Actual page in PDF (with offset)
            "end_marker": end_marker,     # Name of the next table (boundary)
            "schema": schema,
            "table": table
        })
    
    return extraction_plan

def extract_table_definition(pdf_path, table_info, output_dir=None):
    """
    Extract a single table definition from the PDF, searching for start/end markers.

    Args:
        pdf_path: Path to the PDF file
        table_info: Dictionary with table information (from extraction plan)
        output_dir: Directory to save the extracted definition

    Returns:
        Dictionary with the extracted table definition, or None if extraction fails.
    """
    table_name = table_info['table_name']
    schema = table_info['schema']
    table = table_info['table']
    doc_page = table_info['doc_page']
    pdf_page_expected = table_info['pdf_page'] - 1 # Expected 0-indexed page
    # end_marker_text = table_info['end_marker'] # No longer needed for generic pattern

    print(f"\nExtracting {table_name} (expected page {doc_page})")

    # Generic pattern to find the start of ANY table definition
    generic_table_start_pattern = r"\[\w+\]\.\[\w+\]\\nColumns\\n"
    end_marker_regex = re.compile(generic_table_start_pattern)

    with pdfplumber.open(pdf_path) as pdf:
        max_pdf_page = len(pdf.pages) - 1

        # --- Enhanced Start Marker Search ---
        # More flexible patterns for finding the start marker
        start_patterns = [
            f"\\[{schema}\\]\\.\\[{table}\\]\\nColumns\\n",  # Standard pattern with newlines
            f"\\[{schema}\\]\\.\\[{table}\\]",               # Just the table name with brackets
            f"{schema}\\.{table}\\nColumns",                 # Without brackets
            f"{schema}\\.{table}",                          # Plain name
            table                                           # Just the table name as fallback
        ]

        # Define a wider search range (looking further back and forward)
        search_range = 4  # Search up to 4 pages before and after
        search_pages = list(range(
            max(0, pdf_page_expected - search_range),
            min(max_pdf_page + 1, pdf_page_expected + search_range + 1)
        ))
        
        # Also search from the beginning if we're near the start of the PDF
        if pdf_page_expected < 10:
            # Add pages 0 through 10 to the search range if not already included
            for page in range(min(11, max_pdf_page + 1)):
                if page not in search_pages:
                    search_pages.append(page)

        # Sort search pages - prioritize expected page and then nearby pages
        search_pages.sort(key=lambda p: abs(p - pdf_page_expected))

        start_match = None
        actual_start_page_idx = -1
        text_on_start_page = ""
        matched_pattern = ""

        print(f"  Searching across {len(search_pages)} pages: {min(search_pages) + 1}-{max(search_pages) + 1}...")

        for page_idx_to_search in search_pages:
            print(f"  Searching for start marker on PDF page {page_idx_to_search + 1}...")
            page = pdf.pages[page_idx_to_search]
            try:
                text = page.extract_text(x_tolerance=3, y_tolerance=3)
            except Exception as e:
                print(f"  Error extracting text from PDF page {page_idx_to_search + 1}: {e}")
                continue

            if not text:
                print(f"  Could not extract text from PDF page {page_idx_to_search + 1}.")
                continue

            # Try each pattern until we find a match
            for pattern in start_patterns:
                start_match = re.search(pattern, text)
                if start_match:
                    print(f"  Found start marker for {table_name} on PDF page {page_idx_to_search + 1} using pattern '{pattern}'")
                    actual_start_page_idx = page_idx_to_search
                    text_on_start_page = text
                    matched_pattern = pattern
                    break
            
            if start_match:
                break

        if not start_match:
            search_range_str = f"{min(search_pages) + 1} to {max(search_pages) + 1}"
            print(f"Error: Start marker '{table_name}' not found across PDF pages {search_range_str}. Skipping table.")
            return None

        # --- Text Collection using Generic End Marker ---
        start_pos_on_page = start_match.start()
        
        # NEW: Check if this is actually the table we're looking for
        # Sometimes we find the marker but it's actually a reference to the table, not its definition
        if "Columns" not in text_on_start_page[start_pos_on_page:start_pos_on_page+200]:
            # Look for a Columns section within a reasonable distance
            columns_match = re.search(r"Columns\s*\n", text_on_start_page[start_pos_on_page:])
            if not columns_match:
                print(f"  Warning: Found '{table_name}' but no 'Columns' section nearby. This might not be the table definition.")
        
        # Start collecting text *from* the specific start marker found
        full_text = text_on_start_page[start_pos_on_page:]
        current_page_idx = actual_start_page_idx
        found_end = False

        # Search subsequent pages for the generic end marker
        max_search_pages_for_end = 5  # Increased from original
        pages_searched_for_end = 0

        # First, check the remainder of the starting page for the *next* table marker
        # We search *after* the start marker we just found
        end_match_on_start_page = end_marker_regex.search(text_on_start_page, start_match.end())
        if end_match_on_start_page:
            print(f"  Found end marker (next table) on the starting page {current_page_idx + 1}. Truncating.")
            # Truncate before the start of the *next* table marker
            full_text = text_on_start_page[start_pos_on_page : end_match_on_start_page.start()]
            found_end = True

        # If end not found on the first page, search subsequent pages
        while not found_end and pages_searched_for_end <= max_search_pages_for_end:
            current_page_idx += 1
            pages_searched_for_end += 1

            if current_page_idx > max_pdf_page:
                print(f"  Reached end of PDF while searching for end marker for {table_name}")
                break

            print(f"  Reading next page {current_page_idx + 1} to check for end marker...")
            next_page = pdf.pages[current_page_idx]
            try:
                next_text = next_page.extract_text(x_tolerance=3, y_tolerance=3)
            except Exception as e:
                print(f"  Error extracting text from PDF page {current_page_idx + 1}: {e}")
                continue

            if not next_text:
                print(f"  Page {current_page_idx + 1} is empty or unreadable.")
                continue

            # Check if the generic end marker is at the *very beginning* of the next page's text
            # Use match() to check from the start of the string
            end_match_at_start = end_marker_regex.match(next_text.strip())
            if end_match_at_start:
                 print(f"  Found end marker '{end_match_at_start.group(0).strip()}' at start of page {current_page_idx + 1}. Stopping collection.")
                 found_end = True
                 break # Don't add this page's text

            # Check if the generic end marker is *within* the next page's text
            end_match_within = end_marker_regex.search(next_text)
            if end_match_within:
                print(f"  Found end marker '{end_match_within.group(0).strip()}' within page {current_page_idx + 1}. Adding partial text and stopping.")
                # Add text *up to* the start of the end marker
                full_text += "\n" + next_text[:end_match_within.start()]
                found_end = True
                break # Stop collecting

            # If no end marker found on this page, add the whole page's text
            print(f"  End marker not found on page {current_page_idx + 1}. Appending full page text.")
            full_text += "\n" + next_text

        # --- NEW: Validate the captured table definition ---
        # Check if we captured our actual table and not just a reference to it
        is_correct_table = False
        
        # Look for table definition patterns like "Columns" followed by column definitions
        if re.search(r"Columns\s*\n", full_text[:500]):  # Check first 500 chars
            # Check for column definition patterns
            column_pattern = re.compile(r"Key\s+Name\s+Data\s+Type", re.IGNORECASE)
            if column_pattern.search(full_text[:1000]): # Check first 1000 chars
                is_correct_table = True
                
        # Check if we captured the wrong table (another table's definition)
        other_table_pattern = re.compile(r"\[\w+\]\.\[\w+\]\s*\nColumns", re.IGNORECASE)
        other_table_matches = other_table_pattern.findall(full_text)
        
        if other_table_matches and len(other_table_matches) > 1:
            # If we found multiple table definitions, extract just the first one
            print(f"  Warning: Captured multiple table definitions. Extracting only {table_name}.")
            
            # Find the position of the second table start
            for match in other_table_matches:
                if not match.startswith(f"[{schema}].[{table}]"):
                    second_table_pos = full_text.find(match)
                    if second_table_pos > 0:
                        print(f"  Truncating at next table: {match}")
                        full_text = full_text[:second_table_pos]
                        found_end = True
                        break

        if not is_correct_table:
            print(f"  Warning: The extracted text may not contain a proper table definition for {table_name}.")

        # --- Final Processing ---
        if not found_end:
            print(f"Warning: Generic end marker pattern '{generic_table_start_pattern}' not found within {max_search_pages_for_end} pages for {table_name}. Text might be longer than expected.")

        result = {
            "table_name": table_name,
            "schema": schema,
            "table": table,
            "doc_page": doc_page,
            "pdf_page": actual_start_page_idx + 1, # Record the actual start page found
            "raw_text": full_text.strip(), # Store the collected text
            "columns": [], # Placeholder for actual parsing
            "indexes": [], # Placeholder
            "foreign_keys": [] # Placeholder
        }

        # Attempt to parse sections from the collected raw_text
        column_section = extract_section(full_text, "Columns", "Indexes")
        if column_section:
            result["column_section"] = column_section
            if schema.lower() == 'dbo':
                print(f"DBO TABLE DETECTED: {table_name}")
        else:
             print(f"Warning: 'Columns' section marker not found for {table_name}")

        index_section = extract_section(full_text, "Indexes", "Foreign Keys")
        if index_section:
            result["index_section"] = index_section
        else:
             print(f"Warning: 'Indexes' section marker not found for {table_name}")

        fk_section = extract_section(full_text, "Foreign Keys", "Computed Columns") # Assuming 'Computed Columns' is a reliable next marker
        if fk_section:
            result["fk_section"] = fk_section
        else:
             # Try a different potential end marker if 'Computed Columns' isn't there
             fk_section_alt = extract_section(full_text, "Foreign Keys", r"Page \d+ of \d+") # Look for page number as end
             if fk_section_alt:
                 result["fk_section"] = fk_section_alt
                 print(f"Warning: 'Foreign Keys' section end marker 'Computed Columns' not found, used page number instead for {table_name}")
             else:
                 print(f"Warning: 'Foreign Keys' section marker not found or end marker unclear for {table_name}")


        # Save the result if an output directory is specified
        if output_dir:
            output_path = Path(output_dir) / f"{table_name.replace('.', '_')}.json"
            try:
                with open(output_path, 'w') as f:
                    json.dump(result, f, indent=2)
                print(f"Saved extracted definition to {output_path}")
            except Exception as e:
                print(f"Error saving file {output_path}: {e}")

        return result

def extract_section(text, start_marker, end_marker):
    """Extract a section from the text between start_marker and end_marker.
       Uses regex for potentially more robust line-based matching."""
    if not text:
        return None
    
    # Regex to find the start marker at the beginning of a line (case-insensitive)
    start_regex = re.compile(f"^\\s*{re.escape(start_marker)}\\s*$\\n?", re.MULTILINE | re.IGNORECASE)
    start_match = start_regex.search(text)
    
    if not start_match:
        # Fallback: find marker anywhere if not on its own line
        start_pos = text.lower().find(start_marker.lower())
        if start_pos == -1:
            # print(f"Debug: Start marker '{start_marker}' not found.")
            return None
        start_content_pos = start_pos + len(start_marker)
        # Consume potential newline after the marker if found loosely
        if start_content_pos < len(text) and text[start_content_pos] == '\n':
            start_content_pos += 1
    else:
        start_content_pos = start_match.end() # Position after the start marker line (and its newline)

    # Regex to find the end marker at the beginning of a line, *after* the start marker
    # Handle case where end_marker might be a regex pattern itself (like page number)
    try:
        end_marker_pattern = f"^\\s*{end_marker}\\s*$\\n?" if end_marker.startswith('Page') else f"^\\s*{re.escape(end_marker)}\\s*$\\n?"
        end_regex = re.compile(end_marker_pattern, re.MULTILINE | re.IGNORECASE)
        end_match = end_regex.search(text, start_content_pos)
    except re.error as e:
        print(f"Warning: Invalid regex pattern for end marker '{end_marker}': {e}")
        end_match = None # Treat as if not found

    if not end_match:
         # Fallback: find end marker anywhere after start marker
         # Handle potential regex in end_marker for loose search too?
         # For now, treat end_marker as literal string for loose search
         end_pos = text.lower().find(str(end_marker).lower(), start_content_pos)
         if end_pos == -1:
             # End marker not found, use the rest of the text *after* the start marker
             # print(f"Debug: End marker '{end_marker}' not found after '{start_marker}'. Taking rest of text.")
             return text[start_content_pos:].strip()
         else:
             # print(f"Debug: Found end marker '{end_marker}' loosely at pos {end_pos}.")
             return text[start_content_pos:end_pos].strip() # Text between start and loose end
    else:
        # print(f"Debug: Found end marker '{end_marker}' strictly at pos {end_match.start()}.")
        return text[start_content_pos:end_match.start()].strip() # Text between start and strict end


def save_output(toc_entries, extraction_plan, output_path):
    """Save the TOC entries and extraction plan to a JSON file"""
    output = {
        "toc_entries": [(name, page) for name, page in toc_entries],
        "table_count": len(toc_entries),
        "extraction_plan": extraction_plan
    }
    
    output_path_json = Path(output_path) # Ensure it's a Path object
    
    try:
        with open(output_path_json, 'w') as f:
            json.dump(output, f, indent=2)
        print(f"Saved extraction plan to {output_path_json}")
    except Exception as e:
         print(f"Error saving JSON plan to {output_path_json}: {e}")

    # Also save a simple CSV version for reference
    csv_path = output_path_json.with_suffix('.plan.csv') # Use different suffix
    try:
        with open(csv_path, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(["Table", "DocPage", "PdfPage", "Schema", "EndMarker"]) # Add header
            for entry in extraction_plan:
                writer.writerow([
                    entry['table_name'],
                    entry['doc_page'],
                    entry['pdf_page'],
                    entry['schema'],
                    entry.get('end_marker', '') # Use .get for safety
                ])
        print(f"Saved CSV version of plan to {csv_path}")
    except Exception as e:
        print(f"Error saving CSV plan to {csv_path}: {e}")


def process_specific_table(pdf_path, toc_data, table_name=None, schema=None, start_from_table=None, output_dir=None):
    """Process tables based on criteria, optionally starting from a specific table."""
    plan = toc_data.get("extraction_plan")
    if not plan:
        print("Error: 'extraction_plan' not found in TOC data.")
        return []

    # Create output directory if needed
    if output_dir:
        Path(output_dir).mkdir(exist_ok=True, parents=True)
    
    full_plan = plan # Keep the original full plan
    
    # --- Determine the starting point ---
    start_index = 0
    if start_from_table:
        start_from_table_lower = start_from_table.lower()
        found_start = False
        for i, table_info in enumerate(full_plan):
            if table_info['table_name'].lower() == start_from_table_lower:
                start_index = i
                found_start = True
                print(f"Starting processing from table: {start_from_table} (index {start_index})")
                break
        if not found_start:
            print(f"Warning: Start table '{start_from_table}' not found in plan. Processing all tables.")
            start_index = 0
            
    # Slice the plan to start from the determined index
    plan_to_process = full_plan[start_index:]

    # --- Filter the sliced plan further if needed ---
    tables_to_process = []
    if table_name:
        # Filter by specific table name (within the sliced plan)
        table_name_lower = table_name.lower()
        for table_info in plan_to_process:
            if table_name_lower in table_info['table_name'].lower():
                tables_to_process.append(table_info)
    elif schema:
        # Filter by schema (within the sliced plan)
        schema_lower = schema.lower()
        for table_info in plan_to_process:
            if schema_lower == table_info['schema'].lower():
                tables_to_process.append(table_info)
    else:
        # If no further filtering, use the sliced plan
        tables_to_process = plan_to_process

    if not tables_to_process:
        print(f"No tables found matching the criteria after applying start_from filter: table={table_name}, schema={schema}, start_from={start_from_table}")
        return []
    
    print(f"Processing {len(tables_to_process)} tables (starting from index {start_index})...")
    
    results = []
    for i, table_info in enumerate(tables_to_process):
        # Calculate the overall index in the full plan for logging
        overall_index = start_index + i
        print(f"--- Table {i+1}/{len(tables_to_process)} (Overall index: {overall_index}) --- ")
        result = extract_table_definition(pdf_path, table_info, output_dir)
        if result:
            results.append(result)
        else:
            print(f"Failed to extract definition for {table_info['table_name']}")
    
    print(f"\nFinished processing. Extracted {len(results)} table definitions.")
    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python toc_extractor.py <command> [options]")
        print("Commands:")
        print("  create_plan <toc_csv_path> [output_json_plan]")
        print("  process_tables <pdf_path> <plan_json_path> [--table <name>] [--schema <name>] [--start_from <table_name>] [--output_dir <dir>]")
        print("\nExamples:") # Corrected f-string escape
        print("  python toc_extractor.py create_plan 'notes/CareTend Data Dictionary OLTP DB.toc.csv'")
        print("  python toc_extractor.py process_tables <pdf> <plan> --schema dbo --output_dir notes/extracted_dbo")
        print("  python toc_extractor.py process_tables <pdf> <plan> --start_from Delivery.CompanyPointOfOrigin --output_dir notes/extracted_delivery_onwards")
        print("  python toc_extractor.py process_tables <pdf> <plan> --output_dir notes/extracted_all") # Process all
        return
    
    command = sys.argv[1]
    
    if command == "create_plan":
        if len(sys.argv) < 3:
            print("Error: Missing TOC CSV path")
            return
        
        toc_csv_path = sys.argv[2]
        if not Path(toc_csv_path).exists():
            print(f"Error: TOC CSV file not found: {toc_csv_path}")
            return
        
        # Default output path based on input filename
        output_path = sys.argv[3] if len(sys.argv) > 3 else Path(toc_csv_path).with_suffix('.plan.json')
        
        # Load the TOC from CSV
        toc_entries = load_toc_from_csv(toc_csv_path)
        
        if not toc_entries:
            print("No tables loaded from the CSV. Exiting.")
            return
        
        # Create extraction plan
        extraction_plan = create_extraction_plan(toc_entries)
        
        # Save outputs (JSON plan and CSV version of plan)
        save_output(toc_entries, extraction_plan, output_path)
        
        # Special analysis for dbo schema tables
        dbo_tables = [entry for entry in extraction_plan if entry['schema'].lower() == 'dbo']
        if dbo_tables:
            # Corrected f-string escape
            print(f"\nDBO schema tables ({len(dbo_tables)}):") 
            for entry in dbo_tables:
                print(f"  {entry['table_name']} on page {entry['doc_page']}")

    elif command == "process_tables": 
        if len(sys.argv) < 4:
            print("Error: Missing required arguments (pdf_path, plan_json_path)")
            return
        
        pdf_path = sys.argv[2]
        plan_json_path = sys.argv[3]
        
        if not Path(pdf_path).exists():
            print(f"Error: PDF file not found: {pdf_path}")
            return
            
        if not Path(plan_json_path).exists():
            print(f"Error: Plan JSON file not found: {plan_json_path}")
            return
        
        # Parse optional arguments
        table_name = None
        schema_name = None
        start_from_table = None # New argument
        output_dir = None
        
        i = 4
        while i < len(sys.argv):
            arg = sys.argv[i]
            if arg == "--table" and i+1 < len(sys.argv):
                table_name = sys.argv[i+1]
                i += 2
            elif arg == "--schema" and i+1 < len(sys.argv):
                schema_name = sys.argv[i+1]
                i += 2
            elif arg == "--start_from" and i+1 < len(sys.argv): # Parse --start_from
                start_from_table = sys.argv[i+1]
                i += 2
            elif arg == "--output_dir" and i+1 < len(sys.argv):
                output_dir = sys.argv[i+1]
                i += 2
            else:
                print(f"Warning: Ignoring unknown or incomplete argument: {arg}")
                i += 1
        
        # Load Plan JSON
        try:
            with open(plan_json_path, 'r') as f:
                plan_data = json.load(f)
        except Exception as e:
            print(f"Error loading Plan JSON file {plan_json_path}: {e}")
            return

        # Process the specified table(s) using the loaded plan and start_from option
        process_specific_table(pdf_path, plan_data, table_name, schema_name, start_from_table, output_dir)
    
    else:
        print(f"Unknown command: {command}")

if __name__ == "__main__":
    main()