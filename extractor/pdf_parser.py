#!/usr/bin/env python3
"""
PDF text parser module.
Extracts schema information from the text dump of a PDF file.
"""

import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

from .core import ParsedSection, ParsedResult, clean_table_name, parse_boolean

# Constants
PDF_PAGE_OFFSET = 2  # Document page numbers are offset by 2 from PDF page numbers
MAX_PAGES_PER_TABLE_DEF = 5  # Safety limit for reading pages for one table


class PdfTextParser:
    """
    Parses text extracted from a PDF to identify database schema elements.
    Works exclusively on the extracted text file, not the original PDF.
    """

    def __init__(self, text_path: Path):
        """
        Initialize with path to text file containing PDF text content.
        
        Args:
            text_path: Path to the text file extracted from a PDF
        """
        if not text_path.exists():
            raise FileNotFoundError(f"Text file not found: {text_path}")
        
        self.text_path = text_path
        self._text_content = None
        self._toc_entries = None  # List of (table_name, page_num) tuples
        self._toc_dict = None  # Dict for quick lookups
        self._page_drift_stats = {
            "total_tables": 0,
            "tables_with_drift": 0,
            "drift_counts": {},  # Will store counts for each drift value
            "drifted_tables": []  # Will store (table_name, expected_page, actual_page, drift) tuples
        }
    
    def parse(self) -> ParsedResult:
        """
        Parse the text file to extract table definitions.
        
        Returns:
            Dictionary of ParsedSection objects keyed by "schema.table"
        """
        print(f"Parsing PDF text content from: {self.text_path}")
        self._load_text_content()
        self._find_and_parse_toc()
        
        if not self._toc_entries:
            print("Error: Could not find or parse Table of Contents. Aborting.")
            return {}
        
        # Process each table found in the TOC
        result: ParsedResult = {}
        total_tables = len(self._toc_entries)
        self._page_drift_stats["total_tables"] = total_tables
        
        for idx, (table_name, doc_page_num) in enumerate(self._toc_entries):
            print(f"\nProcessing table {idx+1}/{total_tables}: {table_name}")
            
            # Extract the text for this table definition
            definition_text, actual_page = self._extract_table_definition_section(
                table_name, doc_page_num, idx
            )
            
            if not definition_text:
                print(f"  No definition text found for {table_name}, skipping.")
                continue
            
            # Calculate and record page drift if actual_page was returned
            if actual_page is not None:
                expected_page_idx = doc_page_num + PDF_PAGE_OFFSET - 1  # Convert doc page to PDF 0-indexed page
                drift = actual_page - expected_page_idx
                
                if drift != 0:
                    self._page_drift_stats["tables_with_drift"] += 1
                    if drift not in self._page_drift_stats["drift_counts"]:
                        self._page_drift_stats["drift_counts"][drift] = 0
                    self._page_drift_stats["drift_counts"][drift] += 1
                    self._page_drift_stats["drifted_tables"].append(
                        (table_name, expected_page_idx + 1, actual_page + 1, drift)  # +1 to convert to 1-based page numbers
                    )
            
            # Parse the different sections from the definition text
            try:
                columns = self._parse_columns(definition_text)
                indexes = self._parse_indexes(definition_text)
                foreign_keys = self._parse_foreign_keys(definition_text)
                computed_columns = self._parse_computed_columns(definition_text)
                
                # Create ParsedSection and add to result
                result[table_name] = ParsedSection(
                    columns=columns,
                    indexes=indexes,
                    foreign_keys=foreign_keys,
                    computed_columns=computed_columns,
                    provenance="pdf"
                )
                
                print(f"  Successfully parsed {table_name}: "
                      f"{len(columns)} columns, "
                      f"{len(indexes)} indexes, "
                      f"{len(foreign_keys)} foreign keys, "
                      f"{len(computed_columns)} computed columns")
                      
            except Exception as e:
                print(f"  Error parsing definition for {table_name}: {e}")
        
        # After processing all tables, report page drift statistics
        self._report_page_drift()
        
        return result
    
    def _report_page_drift(self) -> None:
        """Report statistics about page drift between TOC entries and actual table positions."""
        stats = self._page_drift_stats
        
        print("\n=== Page Drift Analysis ===")
        print(f"Total tables processed: {stats['total_tables']}")
        print(f"Tables with page drift: {stats['tables_with_drift']} ({stats['tables_with_drift']/stats['total_tables']*100:.1f}%)")
        
        if stats['tables_with_drift'] > 0:
            print("\nDrift distribution:")
            for drift, count in sorted(stats["drift_counts"].items()):
                print(f"  {drift:+d} pages: {count} tables ({count/stats['total_tables']*100:.1f}%)")
            
            print("\nTop 10 tables with highest drift:")
            sorted_drift = sorted(stats["drifted_tables"], key=lambda x: abs(x[3]), reverse=True)
            for i, (table, expected, actual, drift) in enumerate(sorted_drift[:10]):
                print(f"  {i+1}. {table}: expected p.{expected}, found p.{actual} (drift: {drift:+d})")
                
            if len(sorted_drift) > 10:
                print(f"  ...and {len(sorted_drift) - 10} more tables with drift")
        
        print("=========================\n")
    
    def _load_text_content(self) -> None:
        """Load the full text content from the text file."""
        if self._text_content is not None:
            return
        
        with open(self.text_path, 'r', encoding='utf-8') as f:
            self._text_content = f.read()
    
    def _find_and_parse_toc(self) -> List[Tuple[str, int]]:
        """
        Locate the Table of Contents in the text and extract table names
        with their corresponding page numbers.
        
        Returns:
            A list of tuples: [('schema.table', page_num), ...] sorted by page number
        """
        if self._toc_entries is not None:
            return self._toc_entries
        
        print("Searching for Table of Contents...")
        toc_data: List[Tuple[str, int]] = []
        
        # Split content into pages
        pages = self._text_content.split("--- Page ")
        
        # Look for TOC header in the first ~20 pages
        toc_start_page = -1
        for i in range(1, min(21, len(pages))):
            if "Table of Contents" in pages[i]:
                toc_start_page = i
                break
        
        if toc_start_page == -1:
            print("Table of Contents not found.")
            return []
        
        # Regex to find lines like "[Schema].[Table].........PageNum"
        toc_line_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)\s*[\. ]+\s*(\d+)')
        
        # Parse TOC pages starting from where the marker was found
        max_toc_pages = 10  # Limit how many pages we consider part of the TOC
        for page_idx in range(toc_start_page, min(toc_start_page + max_toc_pages, len(pages))):
            page_text = pages[page_idx]
            
            for line in page_text.splitlines():
                match = toc_line_regex.search(line)
                if match:
                    table_name, page_num = match.groups()
                    table_name = clean_table_name(table_name)
                    toc_data.append((table_name, int(page_num)))
                    print(f"Found table entry: {table_name} on page {page_num}")
                
                # Stop processing if "Views" section is encountered
                if "Views" in line:
                    print("Encountered 'Views' section. Stopping TOC parsing.")
                    break
        
        # Sort by page number
        toc_data.sort(key=lambda item: item[1])
        
        print(f"Found {len(toc_data)} table entries in TOC.")
        self._toc_entries = toc_data
        self._toc_dict = dict(toc_data)
        return self._toc_entries
    
    def _extract_table_definition_section(self, table_name: str, doc_page_num: int, current_table_index: int) -> Tuple[Optional[str], Optional[int]]:
        """
        Extract the text block for a table definition from the specified page,
        potentially spanning multiple pages.
        
        Args:
            table_name: The 'schema.table' name
            doc_page_num: Starting document page number from TOC
            current_table_index: Index of this table in the TOC list
            
        Returns:
            Tuple of (extracted_text, actual_page_index) where:
              - extracted_text is the combined text of the definition, or None if extraction fails
              - actual_page_index is the 0-indexed page where the definition was found, or None if not found
        """
        # Convert document page number to file page marker
        file_page_idx = doc_page_num + PDF_PAGE_OFFSET
        print(f"Looking for definition of '{table_name}' starting at doc page {doc_page_num} (text file page {file_page_idx})")
        
        # Get page markers from the text file
        pages = self._text_content.split(f"--- Page ")
        if file_page_idx >= len(pages):
            print(f"  Warning: Page {file_page_idx} is out of range.")
            return None, None
        
        # Prepare for table name detection
        schema, table = table_name.split('.', 1) if '.' in table_name else ('dbo', table_name)
        
        # Format used in PDF - both with and without brackets
        bracketed_format = f"[{schema}].[{table}]"
        plain_format = f"{schema}.{table}"
        
        # Get next table name for boundary detection
        next_table = None
        if current_table_index >= 0 and current_table_index + 1 < len(self._toc_entries):
            next_name, _ = self._toc_entries[current_table_index + 1]
            next_schema, next_table = next_name.split('.', 1) if '.' in next_name else ('dbo', next_name)
            next_bracketed = f"[{next_schema}].[{next_table}]"
            print(f"  Using end marker from next table: {next_bracketed}")
        
        # Collect text for this table definition
        full_text_lines = []
        definition_started = False
        definition_ended = False
        actual_start_page_idx = None
        
        # Enhanced search: Look for the table definition in multiple pages (before and after expected page)
        search_range = 2  # Search up to 2 pages before and after the expected page
        search_start = max(0, file_page_idx - search_range)
        search_end = min(len(pages), file_page_idx + search_range + 1)
        
        for current_page_idx in range(search_start, search_end):
            if current_page_idx >= len(pages):
                print("  Reached end of text file.")
                break
            
            page_text = pages[current_page_idx]
            page_lines = page_text.splitlines()
            
            # Only show preview for pages where we expect the table might start
            if search_start <= current_page_idx <= search_start + 2*search_range:
                print(f"  Scanning page {current_page_idx}...")
                
                # Show a preview of the page content
                if page_lines:
                    preview = " ".join(page_lines[:3])
                    preview = preview[:100] + ("..." if len(preview) > 100 else "")
                    print(f"  Page preview: {preview}")
            
            for line_idx, line in enumerate(page_lines):
                stripped_line = line.strip()
                
                # Check for start marker if definition hasn't started
                if not definition_started:
                    found_marker = False
                    if (bracketed_format in stripped_line or 
                            plain_format in stripped_line):
                        found_marker = True
                        print(f"    Found table marker: '{stripped_line}'")
                    elif (schema.lower() in stripped_line.lower() and 
                            table.lower() in stripped_line.lower()):
                        found_marker = True
                        print(f"    Found table by parts: '{stripped_line}'")

                    if found_marker:
                        definition_started = True
                        actual_start_page_idx = current_page_idx
                        
                        # Page drift detection
                        expected_page_idx = doc_page_num + PDF_PAGE_OFFSET - 1
                        if current_page_idx != expected_page_idx:
                            drift = current_page_idx - expected_page_idx
                            print(f"    *** PAGE DRIFT DETECTED: Expected on PDF page {expected_page_idx+1}, "
                                  f"found on PDF page {current_page_idx+1} (drift: {drift:+d} pages) ***")
                        
                        full_text_lines.append(line)
                        continue # Move to the next line
                
                # If definition has started, check for end marker
                elif definition_started:
                    # Check for next table marker to end definition
                    if next_table and (f"[{next_schema}].[{next_table}]" in stripped_line or 
                                      f"{next_schema}.{next_table}" in stripped_line):
                        print(f"    Found next table marker: '{stripped_line}'")
                        definition_ended = True
                        break
                    
                    # Skip common headers/footers
                    if self._is_header_or_footer(line, current_page_idx):
                        continue
                    
                    # Add the line to collected text
                    full_text_lines.append(line)
            
            if definition_ended:
                print("  Definition ended at next table marker.")
                break
            
            # If we found the table on this page but haven't hit the end yet,
            # keep processing a limited number of additional pages
            if definition_started and not definition_ended:
                # If we're searching beyond the initially defined range, limit how far we go
                if current_page_idx >= file_page_idx + MAX_PAGES_PER_TABLE_DEF:
                    print(f"  Reached max pages limit ({MAX_PAGES_PER_TABLE_DEF}) for table definition.")
                    break
        
        if not definition_started:
            print(f"Warning: Start marker for '{table_name}' not found within search range.")
            return None, None
        
        if not full_text_lines:
            print(f"Warning: No content collected for '{table_name}' after finding start marker.")
            return None, None
        
        # Preview of extracted content
        preview_text = "\n".join(full_text_lines[:3])
        if len(full_text_lines) > 3:
            preview_text += f"\n... plus {len(full_text_lines)-3} more lines"
        print(f"  Extracted text preview:\n{preview_text}")
        
        return "\n".join(full_text_lines), actual_start_page_idx
    
    def _is_header_or_footer(self, line: str, pdf_page_num: int) -> bool:
        """Simple heuristic to identify common header/footer lines."""
        line_lower = line.strip().lower()
        # Page number patterns
        if re.match(rf'^page\s+{pdf_page_num - PDF_PAGE_OFFSET}\s+of\s+\d+', line_lower):
            return True
        if re.match(r'^page\s+\d+', line_lower):
            return True
        # Common document titles/footers
        if "caretend oltp db data dictionary" in line_lower:
            return True
        if "copyright" in line_lower:
            return True
        return False

    def _parse_section(self, section_name: str, definition_text: str) -> Optional[str]:
        """Extract the text content of a specific section (e.g., Columns)."""
        # Regex to find section header (case-insensitive, multiline)
        start_regex = re.compile(rf'^\s*{section_name}\s*$', re.IGNORECASE | re.MULTILINE)
        start_match = start_regex.search(definition_text)

        if not start_match:
            return None

        start_pos = start_match.end()

        # Find the start of the *next* known section or end of text
        next_section_markers = [r'^\s*Columns\s*$', r'^\s*Indexes\s*$', r'^\s*Foreign Keys\s*$', r'^\s*Computed Columns\s*$']
        end_pos = len(definition_text)  # Default to end of text

        for marker in next_section_markers:
            # Don't use the current section's marker as the end marker
            if section_name.lower() in marker.lower():
                continue

            next_match = re.search(marker, definition_text[start_pos:], re.IGNORECASE | re.MULTILINE)
            if next_match:
                # Adjust end position relative to the start of the search string
                potential_end_pos = start_pos + next_match.start()
                # Take the earliest end position found
                end_pos = min(end_pos, potential_end_pos)

        section_text = definition_text[start_pos:end_pos].strip()
        return section_text

    def _parse_columns(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parse the 'Columns' section from the definition text.
        
        Returns:
            List of dictionaries with column information
        """
        print("  Parsing columns...")
        columns = []
        section_text = self._parse_section("Columns", definition_text)
        if not section_text:
            return columns
            
        # Split into lines and identify the header line
        lines = section_text.splitlines()
        header_line = ""
        data_lines = []
        
        # Find the header line (contains "Column Name", "Data Type", etc.)
        for i, line in enumerate(lines):
            line = line.strip()
            if not line: 
                continue
            if ("column name" in line.lower() or "name" in line.lower()) and ("data type" in line.lower() or "type" in line.lower()):
                header_line = line
                # Take all subsequent non-empty lines as data
                data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                break
        
        if not header_line:
            print("    Could not find column header line, attempting alternative parsing...")
            # Fall back: assume first line with "Key" is header
            for i, line in enumerate(lines):
                if "key" in line.lower() and ("name" in line.lower() or "column" in line.lower()):
                    header_line = line
                    data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                    break
        
        if not header_line:
            # Last resort: try to parse without a clear header
            print("    No column header found, using heuristic parsing...")
            data_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("Columns")]
        else:
            print(f"    Found header: {header_line}")
        
        # Determine column positions based on header
        if header_line:
            # Try to find column positions by detecting multiple spaces in header
            header_parts = re.split(r'(\s{2,})', header_line)
            if len(header_parts) > 1:
                # Process header parts to get column positions and names
                positions = []
                header_pos = 0
                column_names = []
                
                for part in header_parts:
                    if re.match(r'\s{2,}', part):
                        # This is a separator
                        header_pos += len(part)
                    else:
                        # This is a column name
                        positions.append(header_pos)
                        column_names.append(part.strip())
                        header_pos += len(part)
                
                # Column names should be things like "Key", "Column Name", "Data Type", etc.
                if len(column_names) >= 3:  # At minimum need Key, Name, Type
                    print(f"    Detected {len(column_names)} columns: {column_names}")
                    
                    # Process each data line using the detected positions
                    for line in data_lines:
                        if len(line) < 10:  # Skip very short lines
                            continue
                            
                        col_data = {}
                        for i in range(len(positions)):
                            field_name = column_names[i].lower().replace(' ', '_')
                            
                            # Get value based on position ranges
                            start_pos = positions[i]
                            end_pos = positions[i+1] if i+1 < len(positions) else len(line)
                            
                            if start_pos < len(line):
                                field_value = line[start_pos:end_pos].strip()
                                # Convert empty strings to None
                                col_data[field_name] = field_value if field_value else None
                        
                        if col_data.get('column_name') or col_data.get('name'):
                            # Normalize field names for consistency
                            normalized_data = {
                                "name": col_data.get('column_name') or col_data.get('name'),
                                "data_type": col_data.get('data_type') or col_data.get('type'),
                                "max_length": col_data.get('max_length') or col_data.get('length'),
                                "allow_nulls": parse_boolean(col_data.get('allow_nulls') or col_data.get('null')),
                                "identity": parse_boolean(col_data.get('identity') or col_data.get('ident')),
                                "key": col_data.get('key') 
                            }
                            columns.append(normalized_data)
            else:
                print("    Could not determine column positions from header")
        
        # Alternative parsing strategies if positional parsing failed
        if not columns and data_lines:
            print("    Falling back to regex-based parsing")
            # Try regex-based extraction
            for line in data_lines:
                # Simple pattern: optional key marker followed by name, type, etc.
                match = re.match(r'^((?:PK|FK|UK)?\s*)?(\w+)\s+(\w+(?:\(\d+(?:,\d+)?\))?)\s+(\d*)\s+(YES|NO|Y|N)?\s*(YES|NO|Y|N)?', line, re.IGNORECASE)
                if match:
                    key_val, name, data_type, length, nulls, identity = match.groups()
                    columns.append({
                        "name": name,
                        "data_type": data_type,
                        "max_length": length if length else None,
                        "allow_nulls": parse_boolean(nulls),
                        "identity": parse_boolean(identity),
                        "key": key_val.strip() if key_val else None
                    })
        
        # Further cleanup and normalization
        for col in columns:
            # Normalize data types (e.g., "varchar(50)" -> type="varchar", length=50)
            if col["data_type"]:
                type_match = re.match(r'(\w+)(?:\((\d+)(?:,(\d+))?\))?', col["data_type"])
                if type_match:
                    base_type, length1, length2 = type_match.groups()
                    col["base_data_type"] = base_type.lower()
                    
                    # If we didn't get length from a separate column
                    if not col["max_length"] and length1:
                        col["max_length"] = length1
                        
                    if length2:  # For types like decimal(18,2)
                        col["numeric_precision"] = length1
                        col["numeric_scale"] = length2

        print(f"    Parsed {len(columns)} columns.")
        return columns

    def _parse_indexes(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parse the 'Indexes' section from the definition text.
        
        Returns:
            List of dictionaries with index information
        """
        print("  Parsing indexes...")
        indexes = []
        section_text = self._parse_section("Indexes", definition_text)
        if not section_text:
            return indexes
        
        # Similar approach to column parsing - find header line first
        lines = section_text.splitlines()
        header_line = ""
        data_lines = []
        
        # Find the header line
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            if "name" in line.lower() and "key columns" in line.lower():
                header_line = line
                data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                break
        
        if not header_line:
            # Fallback for when header line isn't found
            print("    No index header found, using heuristic parsing...")
            data_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("Indexes")]
        else:
            print(f"    Found header: {header_line}")
        
        # Process each data line
        for line in data_lines:
            if len(line) < 5:  # Skip very short lines
                continue
            
            # Try using multi-space splitting for more reliable detection of columns
            parts = re.split(r'\s{2,}', line)
            if len(parts) >= 2:
                # First part is the index name
                name = parts[0]
                # Second part is key columns
                key_cols = parts[1]
                
                # Check if this is a primary key or unique index
                is_primary = "PK" in name or name.startswith("PK_")
                is_unique = "UK" in name or name.startswith("UQ_") or is_primary  # Primary keys are also unique
                
                # Create the index data structure
                index_data = {
                    "name": name,  # Preserve the original case
                    "key_columns": key_cols,
                    "is_unique": is_unique,
                    "is_primary": is_primary,
                }
                
                # Add any additional attributes if present
                if len(parts) > 2:
                    # The third part might be uniqueness indicator or index type
                    third_part = parts[2].upper()
                    if third_part in ("YES", "Y", "UNIQUE"):
                        index_data["is_unique"] = True
                    elif third_part in ("NO", "N"):
                        index_data["is_unique"] = False
                    else:
                        # Might be an index type like CLUSTERED
                        index_data["type"] = parts[2]
                        
                    if len(parts) > 3:
                        # Fourth part is usually the index type if the third part was uniqueness
                        index_data["type"] = parts[3]
                
                indexes.append(index_data)
            else:
                # Fallback to regex for more complex formats
                match = re.match(r'^((?:PK|UK)?\s*)?([^\s]+)\s+([^(]+(?:\([^)]*\))?)\s*(YES|NO|Y|N|UNIQUE)?\s*(\w+)?', line, re.IGNORECASE)
                
                if match:
                    key_type, name, key_columns, unique, idx_type = match.groups()
                    index_data = {
                        "name": name,  # Preserve the original case
                        "key_columns": key_columns.strip(),
                        "is_unique": parse_boolean(unique) if unique else (True if key_type and "UK" in key_type.upper() else False),
                        "type": idx_type.strip() if idx_type else None,
                        "is_primary": True if key_type and "PK" in key_type.upper() else False
                    }
                    indexes.append(index_data)
        
        # Cleanup and normalize
        for idx in indexes:
            # Parse key columns - usually in format "col1, col2, col3"
            if idx["key_columns"]:
                # Handle special case where key columns are in format "col1(ASC), col2(DESC)"
                cols = re.sub(r'\(ASC\)|\(DESC\)', '', idx["key_columns"])
                # Note: We're explicitly keeping the original case of column names
                idx["key_column_list"] = [col.strip() for col in cols.split(',')]
        
        print(f"    Parsed {len(indexes)} indexes.")
        return indexes

    def _parse_foreign_keys(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parse the 'Foreign Keys' section from the definition text.
        
        Returns:
            List of dictionaries with foreign key information
        """
        print("  Parsing foreign keys...")
        foreign_keys = []
        section_text = self._parse_section("Foreign Keys", definition_text)
        if not section_text:
            return foreign_keys
        
        # Process similar to the other sections - look for header line
        lines = section_text.splitlines()
        header_line = ""
        data_lines = []
        
        # Find the header line
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            if "name" in line.lower() and "referenced" in line.lower():
                header_line = line
                data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                break
        
        if not header_line:
            print("    No FK header found, using heuristic parsing...")
            data_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("Foreign Keys")]
        else:
            print(f"    Found header: {header_line}")
        
        # Process each data line
        for line in data_lines:
            if len(line) < 5:  # Skip very short lines
                continue
            
            # Pattern: Name    Column(s)    Referenced Table    Referenced Column(s)    [Update] [Delete]
            
            # Try multi-space splitting first
            parts = re.split(r'\s{2,}', line)
            if len(parts) >= 3:
                fk_data = {
                    "name": parts[0],
                    "columns": parts[1],
                    "referenced_table": None,
                    "referenced_columns": None,
                    "update_rule": None,
                    "delete_rule": None
                }
                
                # Parse reference information
                ref_info = parts[2]
                
                # Match format: [Schema].[Table].[Column] or Schema.Table.Column
                ref_match = re.match(r'(?:\[?([^\]]+)\]?\.)?(?:\[?([^\]]+)\]?)\.(?:\[?([^\]]+)\]?)', ref_info)
                if ref_match:
                    ref_schema, ref_table, ref_cols = ref_match.groups()
                    fk_data["referenced_schema"] = ref_schema
                    fk_data["referenced_table"] = ref_table
                    fk_data["referenced_columns"] = ref_cols
                else:
                    # If can't parse cleanly, store as-is
                    fk_data["referenced_info"] = ref_info
                
                # Add update/delete rules if available
                if len(parts) > 3:
                    fk_data["update_rule"] = parts[3]
                if len(parts) > 4:
                    fk_data["delete_rule"] = parts[4]
                
                foreign_keys.append(fk_data)
            
        # Cleanup and normalize
        for fk in foreign_keys:
            # Parse columns into lists
            if "columns" in fk and fk["columns"]:
                fk["column_list"] = [col.strip() for col in fk["columns"].split(',')]
            if "referenced_columns" in fk and fk["referenced_columns"]:
                fk["referenced_column_list"] = [col.strip() for col in fk["referenced_columns"].split(',')]
        
        print(f"    Parsed {len(foreign_keys)} foreign keys.")
        return foreign_keys

    def _parse_computed_columns(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parse the 'Computed Columns' section from the definition text.
        
        Returns:
            List of dictionaries with computed column information
        """
        print("  Parsing computed columns...")
        computed_columns = []
        section_text = self._parse_section("Computed Columns", definition_text)
        if not section_text:
            return computed_columns
        
        # Similar approach to column parsing - find header line first
        lines = section_text.splitlines()
        header_line = ""
        data_lines = []
        
        # Find the header line
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            if "column name" in line.lower() and "formula" in line.lower():
                header_line = line
                data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                break
        
        if not header_line:
            # Fallback
            print("    No computed column header found, using heuristic parsing...")
            data_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("Computed Columns")]
        else:
            print(f"    Found header: {header_line}")
        
        # Use positional or pattern-based parsing
        if header_line:
            # Try to find column positions by detecting multiple spaces in header
            header_parts = re.split(r'(\s{2,})', header_line)
            if len(header_parts) > 1:
                positions = []
                header_pos = 0
                column_names = []
                
                for part in header_parts:
                    if re.match(r'\s{2,}', part):
                        header_pos += len(part)
                    else:
                        positions.append(header_pos)
                        column_names.append(part.strip())
                        header_pos += len(part)
                
                if len(column_names) >= 2:  # At minimum need Name, Formula
                    print(f"    Detected {len(column_names)} computed column attributes: {column_names}")
                    
                    for line in data_lines:
                        if len(line) < 5:  # Skip very short lines
                            continue
                        
                        col_data = {}
                        for i in range(len(positions)):
                            field_name = column_names[i].lower().replace(' ', '_')
                            
                            start_pos = positions[i]
                            end_pos = positions[i+1] if i+1 < len(positions) else len(line)
                            
                            if start_pos < len(line):
                                field_value = line[start_pos:end_pos].strip()
                                col_data[field_name] = field_value if field_value else None
                        
                        if col_data.get('column_name') or col_data.get('name'):
                            normalized_data = {
                                "name": col_data.get('column_name') or col_data.get('name'),
                                "formula": col_data.get('formula') or col_data.get('definition'),
                                "data_type": col_data.get('data_type') or col_data.get('type'),
                                "is_persisted": parse_boolean(col_data.get('is_persisted') or col_data.get('persisted'))
                            }
                            computed_columns.append(normalized_data)
            else:
                print("    Could not determine column positions from header")
        
        # Fallback to pattern-based parsing
        if not computed_columns and data_lines:
            print("    Falling back to pattern-based parsing for computed columns")
            # Try to capture column name followed by formula
            for line in data_lines:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    computed_columns.append({
                        "name": parts[0],
                        "formula": parts[1],
                        "data_type": parts[2] if len(parts) > 2 else None,
                        "is_persisted": parse_boolean(parts[3]) if len(parts) > 3 else None
                    })
        
        print(f"    Parsed {len(computed_columns)} computed columns.")
        return computed_columns