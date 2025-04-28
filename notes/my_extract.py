#!/usr/bin/env python3
import os
import re
import json
import hashlib
import argparse
import pdfplumber
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any

# Add BeautifulSoup for HTML parsing
try:
    from bs4 import BeautifulSoup
    HAS_BS4 = True
except ImportError:
    print("BeautifulSoup4 not found. Some features will be limited.")
    print("You can install it with: pip install beautifulsoup4")
    HAS_BS4 = False

# --- Configuration ---
DEFAULT_CACHE_FILENAME = "pdf_extraction_cache.json"
DEFAULT_OUTPUT_FILENAME = "extracted_pdf_schema.json"
# Path to HTML version of the PDF if available
DEFAULT_HTML_FILE = "CareTend Data Dictionary OLTP DB.html"
# Page offset might be needed if PDF page numbers differ from document numbers
PDF_PAGE_OFFSET = 2 # Document page numbers are offset by 2 from PDF page numbers
MAX_PAGES_PER_TABLE_DEF = 5 # Safety limit for reading pages for one table

class PdfTableExtractor:
    """
    Extracts structured table definitions (columns, indexes, foreign keys)
    from a PDF data dictionary using pdfplumber, guided by the Table of Contents.

    Features:
    - Reads table names and page numbers from the PDF's Table of Contents.
    - Extracts definition text for each table, potentially spanning multiple pages,
      using text markers to identify start and end boundaries.
    - Parses text to find Columns, Indexes, and Foreign Keys sections.
    - Also parses HTML version of document for better results when available.
    - Structures the extracted information into a defined JSON schema.
    - Uses caching based on PDF file hash to avoid redundant processing.
    - Supports forced regeneration of the output.
    """

    def __init__(self, pdf_path: Path, output_path: Optional[Path] = None, cache_path: Optional[Path] = None):
        """
        Initializes the extractor.

        Args:
            pdf_path: Path to the input PDF file.
            output_path: Path for the final JSON output file. Defaults to DEFAULT_OUTPUT_FILENAME.
            cache_path: Path for the cache file. Defaults to DEFAULT_CACHE_FILENAME.
        """
        if not pdf_path.exists() or not pdf_path.is_file():
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")

        self.pdf_path: Path = pdf_path
        self.output_path: Path = output_path or pdf_path.parent / DEFAULT_OUTPUT_FILENAME
        self.cache_path: Path = cache_path or pdf_path.parent / DEFAULT_CACHE_FILENAME
        self.html_path: Path = pdf_path.parent / DEFAULT_HTML_FILE

        self._pdf_doc: Optional[pdfplumber.PDF] = None
        self._pdf_hash: Optional[str] = None
        # Store TOC as a list of tuples to preserve order for boundary checking
        self._toc_entries: Optional[List[Tuple[str, int]]] = None # [ ("schema.table", page_num), ... ]
        self._toc_dict: Optional[Dict[str, int]] = None # For quick lookups
        self._extracted_data: Optional[Dict[str, Any]] = None
        
        # Store HTML parsed data (populated once for all tables)
        self._html_data: Dict[str, Dict[str, Any]] = {}
        self._has_parsed_html = False

        print(f"Initialized PdfTableExtractor:")
        print(f"  PDF: {self.pdf_path}")
        print(f"  HTML: {self.html_path} ({'exists' if self.html_path.exists() else 'not found'})")
        print(f"  Output: {self.output_path}")
        print(f"  Cache: {self.cache_path}")

    def _get_pdf_hash(self) -> str:
        """Calculates the SHA-256 hash of the PDF file."""
        if self._pdf_hash is None:
            hasher = hashlib.sha256()
            with open(self.pdf_path, 'rb') as f:
                while chunk := f.read(65536): # Read in 64k chunks
                    hasher.update(chunk)
            self._pdf_hash = hasher.hexdigest()
            print(f"Calculated PDF hash: {self._pdf_hash[:10]}...")
        return self._pdf_hash

    def _load_pdf(self) -> pdfplumber.PDF:
        """Loads the pdfplumber PDF object if not already loaded."""
        if self._pdf_doc is None:
            print(f"Loading PDF with pdfplumber: {self.pdf_path}")
            try:
                # pdfplumber automatically handles closing the file when the object is GC'd
                # or used within a 'with' statement (which we do in extract_all)
                self._pdf_doc = pdfplumber.open(self.pdf_path)
                print(f"PDF loaded with {len(self._pdf_doc.pages)} pages.")
            except Exception as e:
                print(f"Error loading PDF with pdfplumber: {e}")
                raise # Re-raise the exception
        return self._pdf_doc

    def _close_pdf(self):
        """Closes the pdfplumber PDF object if it's open."""
        if self._pdf_doc:
            print("Closing PDF document.")
            self._pdf_doc.close()
            self._pdf_doc = None

    def _check_cache(self, force_regenerate: bool = False) -> Optional[Dict[str, Any]]:
        """
        Checks if a valid cache exists.

        Args:
            force_regenerate: If True, ignore the cache.

        Returns:
            The cached data if valid and not forcing regeneration, otherwise None.
        """
        if force_regenerate:
            print("Forcing regeneration, ignoring cache.")
            return None
        if not self.cache_path.exists():
            print("Cache file not found.")
            return None

        try:
            print(f"Loading cache from: {self.cache_path}")
            with open(self.cache_path, 'r', encoding='utf-8') as f:
                cache_data = json.load(f)

            cached_hash = cache_data.get("metadata", {}).get("pdf_hash")
            current_hash = self._get_pdf_hash()

            if cached_hash == current_hash:
                print("Cache is valid (PDF hash matches).")
                return cache_data
            else:
                print("Cache is stale (PDF hash mismatch).")
                return None
        except json.JSONDecodeError:
            print("Cache file is corrupted.")
            return None
        except Exception as e:
            print(f"Error reading cache: {e}")
            return None

    def _save_cache(self, data: Dict[str, Any]):
        """Saves the extracted data to the cache file."""
        if not data:
            print("No data to save to cache.")
            return

        cache_content = {
            "metadata": {
                "pdf_path": str(self.pdf_path),
                "pdf_hash": self._get_pdf_hash(),
                "extraction_date": datetime.now().isoformat(),
                "source_script": __file__ # Or identify the script version
            },
            "tables": data
        }
        try:
            print(f"Saving cache to: {self.cache_path}")
            self.cache_path.parent.mkdir(parents=True, exist_ok=True) # Ensure dir exists
            with open(self.cache_path, 'w', encoding='utf-8') as f:
                json.dump(cache_content, f, indent=2)
            print("Cache saved successfully.")
        except Exception as e:
            print(f"Error saving cache: {e}")

    def _clean_table_name(self, name: str) -> str:
        """
        Standardizes schema.table name format but preserves original case.
        """
        # Store the original format (which might be needed for exact matching)
        original_format = name.strip()
        
        # Remove brackets and split schema and table name
        name_no_brackets = re.sub(r'[\[\]]', '', name).strip()
        if '.' in name_no_brackets:
            schema, table = name_no_brackets.split('.', 1)
            # Preserve the original case - don't convert to PascalCase anymore
            cleaned_name = f"{schema}.{table}"
            
            # For debugging
            if cleaned_name != name_no_brackets:
                print(f"Table name cleaned: {original_format} -> {cleaned_name}")
            
            return cleaned_name
        return name_no_brackets

    def _find_and_parse_toc(self) -> List[Tuple[str, int]]:
        """
        Locates the Table of Contents in the PDF and extracts table names
        and their corresponding document page numbers. Uses text layout.

        Returns:
            A list of tuples: [('schema.table', page_num), ...] sorted by page number.
        """
        if self._toc_entries:
            return self._toc_entries

        print("Searching for Table of Contents...")
        pdf = self._load_pdf()
        toc_data: List[Tuple[str, int]] = []
        # Regex to find lines like "[Schema].[Table].........PageNum"
        # Make it flexible for spacing and dots
        toc_line_regex = re.compile(r'(\[?\w+\]?\.\[?\w+\]?)\s*[\. ]+\s*(\d+)')

        # Search first ~20 pages for TOC marker
        toc_found_page = -1
        for i in range(min(20, len(pdf.pages))):
            page = pdf.pages[i]
            text = page.extract_text()
            if text and "Table of Contents" in text:
                toc_found_page = i
                break

        if toc_found_page == -1:
            print("Table of Contents not found.")
            return []

        # Parse TOC pages starting from where the marker was found
        current_page_num = toc_found_page
        max_toc_pages = 10 # Limit how many pages we consider part of the TOC
        for page_index in range(toc_found_page, min(toc_found_page + max_toc_pages, len(pdf.pages))):
            page = pdf.pages[page_index]
            text = page.extract_text()
            if not text:
                continue

            for line in text.splitlines():
                match = toc_line_regex.search(line)
                if match:
                    table_name, page_num = match.groups()
                    table_name = self._clean_table_name(table_name)
                    # Store the table name with its original case
                    toc_data.append((table_name, int(page_num)))
                    print(f"Found table entry: {table_name} on page {page_num}")

                # Stop processing if "Views" section is encountered
                if "Views" in line:
                    print("Encountered 'Views' section. Stopping TOC parsing.")
                    break

        # Sort by page number, as TOC order might not be strictly page order
        toc_data.sort(key=lambda item: item[1])

        print(f"Found {len(toc_data)} table entries in TOC.")
        self._toc_entries = toc_data
        self._toc_dict = dict(toc_data)
        return self._toc_entries

    def _extract_table_definition_section(self, table_name: str, doc_page_num: int, current_table_index: int) -> Optional[str]:
        """
        Extracts the relevant text block for a table definition starting
        from the given document page number, potentially spanning multiple pages.
        Uses text markers (current table name, next table name) to define boundaries.

        Args:
            table_name: The 'schema.table' name (for context/logging).
            doc_page_num: The starting document page number from the TOC.
            current_table_index: The index of this table in the sorted TOC list.

        Returns:
            The combined text of the definition pages, or None if extraction fails.
        """
        pdf = self._load_pdf()
        start_pdf_page_index = doc_page_num - 1 + PDF_PAGE_OFFSET # Adjust for 0-based index and offset
        print(f"Extracting definition for '{table_name}' starting at doc page {doc_page_num} (PDF page {start_pdf_page_index + 1})")

        if start_pdf_page_index < 0 or start_pdf_page_index >= len(pdf.pages):
            print(f"Warning: Calculated PDF page index {start_pdf_page_index + 1} is out of bounds for '{table_name}'.")
            return None

        # Prepare for table name detection
        schema, table = table_name.split('.', 1) if '.' in table_name else ('dbo', table_name)
        
        # Format used in PDF - both with and without brackets
        bracketed_format = f"[{schema}].[{table}]"
        plain_format = f"{schema}.{table}"
        
        # Get the next table name for boundary detection
        next_table = None
        if current_table_index >= 0 and current_table_index + 1 < len(self._toc_entries or []):
            next_name, _ = self._toc_entries[current_table_index + 1]
            next_schema, next_table = next_name.split('.', 1) if '.' in next_name else ('dbo', next_name)
            next_bracketed = f"[{next_schema}].[{next_table}]"
            print(f"  Using end marker from next table: {next_bracketed}")
        else:
            print("  No next table found in TOC, will read until page limit.")

        full_text_lines = []
        definition_started = False
        definition_ended = False

        for i in range(MAX_PAGES_PER_TABLE_DEF):
            current_pdf_index = start_pdf_page_index + i
            if current_pdf_index >= len(pdf.pages):
                print("  Reached end of PDF.")
                break

            try:
                page = pdf.pages[current_pdf_index]
                page_text = page.extract_text(x_tolerance=2, y_tolerance=2) or ""
                page_lines = page_text.splitlines()

                print(f"  Scanning PDF page {current_pdf_index + 1}...")
                
                # Show a preview of the page content
                if page_lines:
                    preview = " ".join(page_lines[:3])
                    preview = preview[:100] + ("..." if len(preview) > 100 else "")
                    print(f"  Page preview: {preview}")

                for line_num, line in enumerate(page_lines):
                    stripped_line = line.strip()
                    
                    # Check for start marker if definition hasn't started yet
                    if not definition_started:
                        # Look for table name in various formats
                        if bracketed_format in stripped_line or plain_format in stripped_line:
                            definition_started = True
                            print(f"    Found table marker: '{stripped_line}'")
                            full_text_lines.append(line)
                            continue
                        elif schema.lower() in stripped_line.lower() and table.lower() in stripped_line.lower():
                            definition_started = True
                            print(f"    Found table by parts: '{stripped_line}'")
                            full_text_lines.append(line)
                            continue
                    
                    # If definition has started, check for end marker and accumulate text
                    elif definition_started:
                        # Check for next table marker to end definition
                        if next_table and (f"[{next_schema}].[{next_table}]" in stripped_line or 
                                          f"{next_schema}.{next_table}" in stripped_line):
                            print(f"    Found next table marker: '{stripped_line}'")
                            definition_ended = True
                            break

                        # Skip common headers/footers
                        if self._is_header_or_footer(line, current_pdf_index + 1):
                            continue
                            
                        # Add the line to our collected text
                        full_text_lines.append(line)

                if definition_ended:
                    print("  Definition ended at next table marker.")
                    break

            except Exception as e:
                print(f"  Warning: Error extracting text from page {current_pdf_index + 1}: {e}")
                continue

        if not definition_started:
            print(f"Warning: Start marker for '{table_name}' not found near page {doc_page_num}.")
            return None

        if not full_text_lines:
            print(f"Warning: No content collected for '{table_name}' after finding start marker.")
            return None

        # Preview of extracted content
        preview_text = "\n".join(full_text_lines[:3])
        if len(full_text_lines) > 3:
            preview_text += f"\n... plus {len(full_text_lines)-3} more lines"
        print(f"  Extracted text preview:\n{preview_text}")
        
        return "\n".join(full_text_lines)

    def _get_next_table_start_marker(self, current_table_index: int) -> Optional[str]:
        """
        Gets the name of the next table in the TOC to use as an end marker.
        Returns the exact bracketed format for more reliable boundary detection.
        """
        if not self._toc_entries or current_table_index < 0:
            return None
            
        next_index = current_table_index + 1
        if next_index < len(self._toc_entries):
            next_table_name, _ = self._toc_entries[next_index]
            
            # Get schema and table parts
            schema, table = next_table_name.split('.', 1) if '.' in next_table_name else ('dbo', next_table_name)
            
            # Return the exact bracketed format that's used in the PDF for reliable matching
            # This helps prevent content merging issues by having precise boundary detection
            return f"{schema}.{table}"
            
        return None # No next table

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
        # Add more patterns based on the specific PDF
        return False

    # --- Parsing Methods (Stubs - Require Implementation using Regex on stitched text) ---

    def _parse_section(self, section_name: str, definition_text: str) -> Optional[str]:
        """Extracts the text content of a specific section (e.g., Columns)."""
        # Regex to find section header (case-insensitive, multiline)
        start_regex = re.compile(rf'^\s*{section_name}\s*$', re.IGNORECASE | re.MULTILINE)
        start_match = start_regex.search(definition_text)

        if not start_match:
            # print(f"    Section '{section_name}' not found.")
            return None

        start_pos = start_match.end()

        # Find the start of the *next* known section or end of text
        next_section_markers = [r'^\s*Columns\s*$', r'^\s*Indexes\s*$', r'^\s*Foreign Keys\s*$', r'^\s*Computed Columns\s*$']
        end_pos = len(definition_text) # Default to end of text

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
        # print(f"    Extracted section '{section_name}': {len(section_text)} chars")
        return section_text


    def _parse_columns(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parses the 'Columns' section from the definition text.
        Extracts structured information about table columns including name, data type, 
        nullability, identity status, etc.
        """
        print("  Parsing columns...")
        columns = []
        section_text = self._parse_section("Columns", definition_text)
        if not section_text:
            return columns
            
        # Step 1: Split into lines and identify the header line
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
            # Fall back: assume first line with "Key" is header, if available
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
        
        # Step 2: Determine column positions based on header or fixed positions
        # This is the most challenging part - the header line helps us understand where each column starts
        
        if header_line:
            # Option 1: Try to find column positions by detecting multiple spaces in header
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
                                "allow_nulls": self._parse_boolean(col_data.get('allow_nulls') or col_data.get('null')),
                                "identity": self._parse_boolean(col_data.get('identity') or col_data.get('ident')),
                                "key": col_data.get('key') 
                            }
                            columns.append(normalized_data)
            else:
                print("    Could not determine column positions from header")
        
        # Step 3: If positional parsing failed, try alternative parsing strategies
        if not columns and data_lines:
            print("    Falling back to regex-based parsing")
            # Try regex-based extraction - look for patterns like "PK  ColumnName  DataType  Length  Null  Identity"
            for line in data_lines:
                # Simple pattern: optional key marker followed by name, type, etc.
                match = re.match(r'^((?:PK|FK|UK)?\s*)?(\w+)\s+(\w+(?:\(\d+(?:,\d+)?\))?)\s+(\d*)\s+(YES|NO|Y|N)?\s*(YES|NO|Y|N)?', line, re.IGNORECASE)
                if match:
                    key_val, name, data_type, length, nulls, identity = match.groups()
                    columns.append({
                        "name": name,
                        "data_type": data_type,
                        "max_length": length if length else None,
                        "allow_nulls": self._parse_boolean(nulls),
                        "identity": self._parse_boolean(identity),
                        "key": key_val.strip() if key_val else None
                    })
        
        # Step 4: Further cleanup and normalization
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

    def _parse_boolean(self, value: Optional[str]) -> Optional[bool]:
        """Helper to convert string values to boolean."""
        if not value:
            return None
        value = value.upper()
        if value in ('YES', 'Y', '1', 'TRUE'):
            return True
        if value in ('NO', 'N', '0', 'FALSE'):
            return False
        return None

    def _parse_indexes(self, definition_text: str) -> List[Dict[str, Any]]:
        """
        Parses the 'Indexes' section from the definition text.
        Extracts structured information about table indexes including name, uniqueness,
        columns involved, etc. Handles case-sensitivity correctly.
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
                        "is_unique": self._parse_boolean(unique) if unique else (True if key_type and "UK" in key_type.upper() else False),
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
        Parses the 'Foreign Keys' section from the definition text.
        Extracts structured information about table foreign keys including constraint name,
        columns involved, referenced table, etc.
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
        Parses the 'Computed Columns' section from the definition text.
        Extracts structured information about computed columns including name, 
        formula, data type, etc.
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
        
        # Find the header line (contains "Column Name", "Formula", etc.)
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            if "column name" in line.lower() and "formula" in line.lower():
                header_line = line
                data_lines = [l.strip() for l in lines[i+1:] if l.strip()]
                break
        
        if not header_line:
            # Fallback - try to use the first line with content as header
            print("    No computed column header found, using heuristic parsing...")
            data_lines = [l.strip() for l in lines if l.strip() and not l.strip().startswith("Computed Columns")]
        else:
            print(f"    Found header: {header_line}")
        
        # Use positional or pattern-based parsing similar to _parse_columns
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
                                "is_persisted": self._parse_boolean(col_data.get('is_persisted') or col_data.get('persisted'))
                            }
                            computed_columns.append(normalized_data)
            else:
                print("    Could not determine column positions from header")
        
        # Fallback to pattern-based parsing if positional parsing failed
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
                        "is_persisted": self._parse_boolean(parts[3]) if len(parts) > 3 else None
                    })
        
        print(f"    Parsed {len(computed_columns)} computed columns.")
        return computed_columns

    # --- Main Processing ---

    def extract_all(self, force_regenerate: bool = False) -> Dict[str, Any]:
        """
        Performs the full extraction process:
        1. Checks cache.
        2. If cache is invalid or forced, loads PDF.
        3. Finds and parses the Table of Contents.
        4. Parse HTML document once (if available)
        5. For each table in TOC, extracts and parses its definition section.
        6. Formats the results.
        7. Saves output JSON and updates cache.
        8. Closes the PDF.

        Args:
            force_regenerate: If True, bypasses cache and re-extracts from PDF.

        Returns:
            A dictionary containing the structured table definitions.
        """
        print("-" * 30)
        print("Starting PDF Table Extraction Process (using pdfplumber)")
        print("-" * 30)

        cached_data = self._check_cache(force_regenerate)
        if cached_data:
            print("Using cached data.")
            self._extracted_data = cached_data.get("tables", {})
            return self._extracted_data # Return only the table data part

        all_table_data: Dict[str, Any] = {}
        processed_count = 0
        html_fallback_count = 0

        try:
            self._load_pdf() # Ensure PDF is loaded
            toc = self._find_and_parse_toc()

            if not toc:
                print("Error: Could not find or parse Table of Contents. Aborting.")
                return {}

            # Parse HTML document once if available (instead of for each table)
            html_data = {}
            if self.html_path.exists() and HAS_BS4:
                print("HTML version found. Parsing HTML document once...")
                html_data = self._parse_html_document() or {}
                print(f"Parsed HTML data for {len(html_data)} tables")

            total_tables = len(toc)
            print(f"Processing {total_tables} tables found in TOC...")

            for idx, (table_name, doc_page_num) in enumerate(toc):
                processed_count += 1
                print(f"\nProcessing table {processed_count}/{total_tables}: {table_name}")

                schema, table = table_name.split('.', 1) if '.' in table_name else ('dbo', table_name)
                table_entry = {
                    "schema": schema,
                    "table_name": table,
                    "source_pdf_page": doc_page_num, # Document page number from TOC
                    "columns": [],
                    "indexes": [],
                    "foreign_keys": [],
                    "computed_columns": [], # Initialize computed columns array
                    "error": None
                }

                # Check if we have data from HTML parsing first
                clean_table_name = self._clean_table_name(table_name)
                html_table_data = html_data.get(clean_table_name) if html_data else None

                if html_table_data:
                    print(f"  Found table data in pre-parsed HTML")
                    table_entry["columns"] = html_table_data.get("columns", [])
                    table_entry["indexes"] = html_table_data.get("indexes", [])
                    table_entry["foreign_keys"] = html_table_data.get("foreign_keys", [])
                    table_entry["computed_columns"] = html_table_data.get("computed_columns", [])
                    table_entry["extraction_source"] = "html"
                    html_fallback_count += 1

                    # If HTML data is sufficient, skip PDF extraction
                    if any(len(table_entry[section]) > 0 for section in ["columns", "indexes", "foreign_keys", "computed_columns"]):
                        print(f"  Using HTML data for {table_name} (found {len(table_entry['columns'])} columns, "
                              f"{len(table_entry['indexes'])} indexes, {len(table_entry['foreign_keys'])} FKs, "
                              f"{len(table_entry['computed_columns'])} computed columns)")
                        all_table_data[table_name] = table_entry
                        continue

                # If we didn't have HTML data, or it wasn't sufficient, try PDF extraction
                definition_text = self._extract_table_definition_section(table_name, doc_page_num, idx)

                if definition_text:
                    # Attempt to parse sections from the extracted text
                    try:
                        table_entry["columns"] = self._parse_columns(definition_text)
                        table_entry["indexes"] = self._parse_indexes(definition_text)
                        table_entry["foreign_keys"] = self._parse_foreign_keys(definition_text)
                        table_entry["computed_columns"] = self._parse_computed_columns(definition_text)
                        table_entry["extraction_source"] = "pdf"

                        # If we didn't get any data, try html fallback one more time to be sure
                        if not any(table_entry[section] for section in ["columns", "indexes", "foreign_keys", "computed_columns"]):
                            print("  Warning: No structured data parsed from PDF text.")

                            # Try with HTML again only if we didn't already check
                            if not html_table_data:
                                # Try HTML fallback
                                html_data = self._get_html_table_data(table_name)
                                if html_data:
                                    print("  Successfully extracted data from HTML version instead.")
                                    html_fallback_count += 1
                                    table_entry["columns"] = html_data.get("columns", [])
                                    table_entry["indexes"] = html_data.get("indexes", [])
                                    table_entry["foreign_keys"] = html_data.get("foreign_keys", [])
                                    table_entry["computed_columns"] = html_data.get("computed_columns", [])
                                    table_entry["extraction_source"] = "html"

                    except Exception as parse_error:
                         print(f"  Error parsing definition for {table_name}: {parse_error}")
                         table_entry["error"] = f"Parsing failed: {parse_error}"
                else:
                    print(f"  Skipping parsing for {table_name} due to text extraction failure.")
                    table_entry["error"] = "Failed to extract definition text"

                all_table_data[table_name] = table_entry

            self._extracted_data = all_table_data

            # --- Output Schema Formatting ---
            final_output_data = {
                 "metadata": {
                    "pdf_path": str(self.pdf_path),
                    "pdf_hash": self._get_pdf_hash(),
                    "extraction_date": datetime.now().isoformat(),
                    "total_tables_processed": len(all_table_data),
                    "total_tables_in_toc": total_tables,
                    "html_fallback_count": html_fallback_count,
                    "html_path": str(self.pdf_path.parent / DEFAULT_HTML_FILE)
                },
                "tables": self._extracted_data
            }

            # Save final JSON output
            try:
                print(f"\nSaving final output to: {self.output_path}")
                self.output_path.parent.mkdir(parents=True, exist_ok=True) # Ensure dir exists
                with open(self.output_path, 'w', encoding='utf-8') as f:
                    json.dump(final_output_data, f, indent=2)
                print("Output saved successfully.")
            except Exception as e:
                print(f"Error saving output JSON: {e}")

            # Save data to cache for next time
            self._save_cache(self._extracted_data) # Cache only the table data part

        except Exception as e:
            print(f"\nAn unexpected error occurred during extraction: {e}")
            import traceback
            traceback.print_exc()
        finally:
            # Ensure the PDF is closed
            self._close_pdf()

        print("-" * 30)
        print("Extraction Process Complete")
        print(f"Tables processed: {processed_count}")
        print(f"HTML data used: {html_fallback_count}")
        print("-" * 30)
        return self._extracted_data # Return the table data

    def _extract_from_html(self, table_name: str) -> Optional[Dict[str, Any]]:
        """
        Extracts table definition from the HTML version of the PDF if available.
        
        Args:
            table_name: The schema.table name to find in the HTML document.
            
        Returns:
            A dictionary with columns, indexes, etc. if successful, None otherwise.
        """
        # Look for HTML file in the same directory as the PDF
        html_path = self.pdf_path.parent / DEFAULT_HTML_FILE
        
        if not html_path.exists():
            print(f"  HTML version not found at {html_path}")
            return None
            
        try:
            print(f"  Attempting to extract '{table_name}' from HTML version...")
            
            # Load HTML with BeautifulSoup
            with open(html_path, 'r', encoding='utf-8') as f:
                soup = BeautifulSoup(f, 'html.parser')
                
            # Clean the table name for searching
            clean_table_name = self._clean_table_name(table_name)
            schema, table = clean_table_name.split('.', 1) if '.' in clean_table_name else ('dbo', clean_table_name)
            
            # Find all H1-H5 elements that might contain table names
            heading_elements = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5'])
            target_heading = None
            
            # Look for the table name in the headings
            for heading in heading_elements:
                text = heading.get_text(strip=True)
                # Check for [Schema].[Table] or Schema.Table format
                if f"[{schema}].[{table}]" in text or f"{schema}.{table}" in text:
                    target_heading = heading
                    print(f"    Found table heading in HTML: {text}")
                    break
                    
            if not target_heading:
                print(f"    Couldn't find table '{table_name}' in HTML headings")
                return None
                
            # Get the section following this heading until the next heading
            result = {
                "columns": [],
                "indexes": [],
                "foreign_keys": [],
                "computed_columns": []
            }
            
            # Find the next sibling elements until we hit another heading
            current = target_heading.find_next()
            while current and not current.name in ['h1', 'h2', 'h3', 'h4', 'h5']:
                # If it's a table element, process it
                if current.name == 'table':
                    table_elem = current
                    
                    # Try to determine what kind of table this is (columns, indexes, etc.)
                    table_type = self._classify_html_table(table_elem)
                    
                    if table_type:
                        # Extract data from the table based on its type
                        data = self._extract_data_from_html_table(table_elem, table_type)
                        if data:
                            result[table_type].extend(data)
                            print(f"    Extracted {len(data)} {table_type} from HTML table")
                
                current = current.find_next()
            
            # Only return result if we found any data
            if any(result.values()):
                return result
                
            return None
            
        except Exception as e:
            print(f"  Error extracting from HTML: {e}")
            return None
            
    def _parse_html_document(self) -> Dict[str, Dict[str, Any]]:
        """
        Parse the HTML version of the document once to extract all table definitions.
        
        Returns:
            Dictionary with table names as keys and their parsed content as values
        """
        if not HAS_BS4:
            print("BeautifulSoup not available, skipping HTML parsing")
            return {}
            
        if not self.html_path.exists():
            print(f"HTML version not found at {self.html_path}, skipping HTML parsing")
            return {}
            
        if self._has_parsed_html:
            return self._html_data
            
        print(f"Parsing HTML document: {self.html_path}")
        result = {}
        
        try:
            with open(self.html_path, 'r', encoding='utf-8') as f:
                soup = BeautifulSoup(f, 'html.parser')
                
            # Find all headings that might contain table names
            headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
            
            # Regular expression to match schema.table patterns (both with and without brackets)
            table_name_pattern = re.compile(r'(\[?(\w+)\]?\.\[?(\w+)\]?)')
            
            # Process each heading and the content that follows
            for i, heading in enumerate(headings):
                heading_text = heading.get_text(strip=True)
                match = table_name_pattern.search(heading_text)
                
                if not match:
                    continue
                    
                # Extract the table name and clean it
                full_match, schema, table = match.groups()
                table_name = f"{schema}.{table}"
                
                print(f"  Found table in HTML: {table_name}")
                
                # Initialize the structure for this table
                result[table_name] = {
                    "columns": [],
                    "indexes": [],
                    "foreign_keys": [],
                    "computed_columns": []
                }
                
                # Find all content until the next heading
                next_elements = []
                current_elem = heading.next_sibling
                
                # Look for the next heading, collecting all elements in between
                while current_elem and (i == len(headings) - 1 or current_elem != headings[i + 1]):
                    if current_elem and current_elem.name == 'table':  # Check that current_elem is not None
                        next_elements.append(current_elem)
                    if current_elem:  # Ensure current_elem is not None before accessing next_sibling
                        current_elem = current_elem.next_sibling
                    else:
                        break
                
                # Process tables found after the heading
                for table_elem in next_elements:
                    # Determine what kind of table this is (columns, indexes, etc.)
                    table_type = self._classify_html_table(table_elem)
                    
                    if table_type:
                        # Extract structured data from the table
                        data = self._extract_data_from_html_table(table_elem, table_type)
                        if data:
                            result[table_name][table_type] = data
                            print(f"    Extracted {len(data)} {table_type}")
            
            print(f"HTML parsing complete. Found data for {len(result)} tables.")
            self._html_data = result
            self._has_parsed_html = True
            return result
            
        except Exception as e:
            print(f"Error parsing HTML document: {e}")
            import traceback
            traceback.print_exc()
            return {}

    def _get_html_table_data(self, table_name: str) -> Optional[Dict[str, Any]]:
        """
        Get the HTML-parsed data for a specific table.
        Includes validation to prevent data merging issues.
        
        Args:
            table_name: The name of the table to retrieve
            
        Returns:
            Dictionary containing the table structure if found, None otherwise
        """
        # Safety check - do we have HTML support?
        if not HAS_BS4:
            return None
            
        # Make sure HTML has been parsed
        if not self._has_parsed_html:
            self._parse_html_document()
            
        # Clean the table name for consistent lookup
        clean_name = self._clean_table_name(table_name)
        original_name = table_name
        
        # Additional logging to help debug HTML lookups
        print(f"  Looking up HTML data for {original_name} (cleaned: {clean_name})")
        
        # Try to find the table in our HTML data
        html_data = None
        if self._html_data:
            # First try exact match with cleaned name
            if clean_name in self._html_data:
                html_data = self._html_data[clean_name]
                print(f"  Found HTML data using cleaned name: {clean_name}")
            # If not found, try with case-insensitive search
            else:
                for key in self._html_data.keys():
                    if key.lower() == clean_name.lower():
                        html_data = self._html_data[key]
                        print(f"  Found HTML data using case-insensitive match: {key}")
                        break
                        
        # Verify data integrity - make sure we're returning data for the right table
        if html_data:
            # If there's unexpected data inconsistency, log a warning
            schema, table = clean_name.split('.', 1) if '.' in clean_name else ('dbo', clean_name)
            html_schema = html_data.get("schema", schema)
            html_table = html_data.get("table_name", table)
            
            # If the schemas don't match, this might be an incorrect merge
            if html_schema.lower() != schema.lower() or html_table.lower() != table.lower():
                print(f"  WARNING: HTML data schema/table mismatch! Expected: {schema}.{table}, Got: {html_schema}.{html_table}")
                # Return None to avoid incorrect data merging
                return None
                
        return html_data

# --- Example Usage ---
if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Extract table definitions from CareTend Data Dictionary PDF')
    parser.add_argument('--force', action='store_true', help='Force regeneration of output, ignoring cache')
    args = parser.parse_args()
    
    # Assumes the PDF is in the same directory as the script
    script_dir = Path(__file__).parent
    # *** IMPORTANT: Update this path to your actual PDF file ***
    pdf_file = script_dir / "CareTend Data Dictionary OLTP DB.pdf"

    if not pdf_file.exists():
        print(f"Error: Example PDF file not found at {pdf_file}")
        print("Please place the PDF in the script directory or update the path in the script.")
    else:
        try:
            # You can specify output/cache paths if needed:
            # output = script_dir / "output" / "my_schema.json"
            # cache = script_dir / "cache" / "pdf_cache.json"
            # extractor = PdfTableExtractor(pdf_path=pdf_file, output_path=output, cache_path=cache)
            extractor = PdfTableExtractor(pdf_path=pdf_file)

            # Use the force flag from command line arguments
            extracted_schema = extractor.extract_all(force_regenerate=args.force)

            if extracted_schema:
                print(f"\nSuccessfully processed data for {len(extracted_schema)} tables found in TOC.")
                # Print summary for the first few tables
                count = 0
                error_count = 0
                for name, data in extracted_schema.items():
                    if data.get("error"):
                        error_count += 1
                    if count < 5: # Print details for first 5
                        print(f"  - {name}: {len(data.get('columns',[]))} cols, {len(data.get('indexes',[]))} idx, {len(data.get('foreign_keys',[]))} FKs (TOC Page: {data.get('source_pdf_page', 'N/A')})")
                        if data.get("error"):
                             print(f"    Error: {data['error']}")
                    elif count == 5:
                         print(f"  ... and {len(extracted_schema) - 5} more.")

                    count += 1

                print(f"\nExtraction Summary:")
                print(f"  Total tables in TOC: {extractor._toc_entries and len(extractor._toc_entries) or 'N/A'}")
                print(f"  Tables processed: {len(extracted_schema)}")
                print(f"  Tables with errors: {error_count}")
                print(f"\nOutput JSON saved to: {extractor.output_path}")
                print(f"Cache file location: {extractor.cache_path}")

        except FileNotFoundError as fnf:
            print(f"Initialization failed: {fnf}")
        except Exception as main_err:
            print(f"\nAn unexpected error occurred during the main execution: {main_err}")
            import traceback
            traceback.print_exc()
