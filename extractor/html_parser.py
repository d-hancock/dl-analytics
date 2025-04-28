#!/usr/bin/env python3
"""
HTML DOM parser module.
Extracts schema information from the HTML version of a PDF document.
"""

import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from bs4 import BeautifulSoup, Tag

from .core import ParsedSection, ParsedResult, clean_table_name, parse_boolean


class HtmlDomParser:
    """
    Parses HTML document to extract database schema elements.
    Works exclusively on the HTML file, never accessing the original PDF.
    """

    def __init__(self, html_path: Path):
        """
        Initialize with path to HTML file.
        
        Args:
            html_path: Path to the HTML file
        """
        try:
            from bs4 import BeautifulSoup
            self.has_bs4 = True
        except ImportError:
            print("BeautifulSoup4 not found. HTML parsing will not be available.")
            print("You can install it with: pip install beautifulsoup4")
            self.has_bs4 = False
            
        if not html_path.exists():
            raise FileNotFoundError(f"HTML file not found: {html_path}")
            
        self.html_path = html_path
        self._soup = None
        
    def parse(self) -> ParsedResult:
        """
        Parse the HTML document to extract table definitions.
        
        Returns:
            Dictionary of ParsedSection objects keyed by "schema.table"
        """
        if not self.has_bs4:
            print("BeautifulSoup4 not available, skipping HTML parsing")
            return {}
            
        print(f"Parsing HTML document: {self.html_path}")
        self._load_soup()
        
        result: ParsedResult = {}
        
        # Find all headings that might contain table names
        headings = self._soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
        
        # Regular expression to match schema.table patterns (with and without brackets)
        table_name_pattern = re.compile(r'(\[?(\w+)\]?\.\[?(\w+)\]?)')
        
        # Process each heading and the content that follows
        for i, heading in enumerate(headings):
            heading_text = heading.get_text(strip=True)
            match = table_name_pattern.search(heading_text)
            
            if not match:
                continue
                
            # Extract and clean the table name
            full_match, schema, table = match.groups()
            table_name = clean_table_name(f"{schema}.{table}")
            
            print(f"  Found table in HTML: {table_name}")
            
            # Initialize the structure for this table
            table_data = ParsedSection(provenance="html")
            
            # Process all content until the next heading
            next_elements = []
            current_elem = heading.next_sibling
            
            # Look for the next heading, collecting tables in between
            while current_elem and (i == len(headings) - 1 or current_elem != headings[i + 1]):
                if current_elem and current_elem.name == 'table':
                    next_elements.append(current_elem)
                if current_elem:
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
                        if table_type == "columns":
                            table_data.columns = data
                        elif table_type == "indexes":
                            table_data.indexes = data
                        elif table_type == "foreign_keys":
                            table_data.foreign_keys = data
                        elif table_type == "computed_columns":
                            table_data.computed_columns = data
                        
                        print(f"    Extracted {len(data)} {table_type}")
            
            # Only add to result if we found any data
            if any([table_data.columns, table_data.indexes, 
                    table_data.foreign_keys, table_data.computed_columns]):
                result[table_name] = table_data
        
        print(f"HTML parsing complete. Found data for {len(result)} tables.")
        return result
    
    def _load_soup(self) -> None:
        """Load the HTML document using BeautifulSoup."""
        if not self.has_bs4:
            return
            
        if self._soup is not None:
            return
            
        with open(self.html_path, 'r', encoding='utf-8') as f:
            self._soup = BeautifulSoup(f, 'html.parser')
    
    def _classify_html_table(self, table: Tag) -> Optional[str]:
        """
        Determines what kind of table this is based on its header content.
        
        Args:
            table: A BeautifulSoup table element
            
        Returns:
            String indicating the table type: "columns", "indexes", "foreign_keys", 
            "computed_columns", or None if it can't be classified
        """
        if not table:
            return None
            
        # Get the table header text
        header_text = ""
        
        # Check if there's a preceding header element
        prev_elem = table.previous_sibling
        while prev_elem and isinstance(prev_elem, str) and prev_elem.strip() == "":
            prev_elem = prev_elem.previous_sibling
            
        if prev_elem and prev_elem.name in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']:
            header_text = prev_elem.get_text(strip=True).lower()
        
        # If no explicit header before the table, check the first row
        if not header_text and table.tr:
            header_cells = table.tr.find_all(['th', 'td'])
            if header_cells:
                header_text = ' '.join(cell.get_text(strip=True).lower() for cell in header_cells)
        
        # Classify based on header content
        if "column" in header_text and "name" in header_text and "data type" in header_text:
            return "columns"
        elif "index" in header_text or ("name" in header_text and "key columns" in header_text):
            return "indexes"
        elif "foreign key" in header_text or ("name" in header_text and "referenced" in header_text):
            return "foreign_keys"
        elif "computed" in header_text and "column" in header_text:
            return "computed_columns"
        
        # Look at the column headers within the table itself
        if table.tr:
            header_cells = table.tr.find_all(['th', 'td'])
            header_text = ' '.join(cell.get_text(strip=True).lower() for cell in header_cells)
            
            if "column name" in header_text and "data type" in header_text:
                return "columns"
            elif "index name" in header_text or "key columns" in header_text:
                return "indexes"
            elif "foreign key" in header_text or "referenced table" in header_text:
                return "foreign_keys"
            elif "computed" in header_text and "formula" in header_text:
                return "computed_columns"
        
        return None
    
    def _extract_data_from_html_table(self, table: Tag, table_type: str) -> List[Dict[str, Any]]:
        """
        Extract structured data from a classified HTML table.
        
        Args:
            table: A BeautifulSoup table element
            table_type: The type of table ("columns", "indexes", etc.)
            
        Returns:
            A list of dictionaries with structured data
        """
        result = []
        
        if not table or not table.find_all('tr'):
            return result
            
        # Extract header row to get column names
        header_row = table.tr
        if not header_row:
            return result
            
        headers = [cell.get_text(strip=True).lower() for cell in header_row.find_all(['th', 'td'])]
        if not headers:
            return result
            
        # Skip the header row when processing data
        data_rows = table.find_all('tr')[1:]
        
        for row in data_rows:
            cells = row.find_all(['th', 'td'])
            if not cells or len(cells) < 2:
                continue
                
            # Create a dictionary mapping header names to cell values
            row_data = {}
            for i, cell in enumerate(cells):
                if i < len(headers):
                    header_name = headers[i].replace(' ', '_')
                    row_data[header_name] = cell.get_text(strip=True)
            
            # Process based on table type
            processed_item = self._normalize_row_data(row_data, table_type)
            if processed_item:
                result.append(processed_item)
        
        return result
    
    def _normalize_row_data(self, row_data: Dict[str, str], table_type: str) -> Optional[Dict[str, Any]]:
        """
        Normalize row data based on the table type.
        
        Args:
            row_data: Dictionary of column name to cell value
            table_type: The type of table ("columns", "indexes", etc.)
            
        Returns:
            Normalized dictionary with proper field names and data types
        """
        if not row_data:
            return None
            
        if table_type == "columns":
            # Normalize column names
            name = row_data.get('column_name') or row_data.get('name')
            if not name:
                return None
                
            return {
                "name": name,
                "data_type": row_data.get('data_type') or row_data.get('type'),
                "max_length": row_data.get('max_length') or row_data.get('length'),
                "allow_nulls": parse_boolean(row_data.get('allow_nulls') or row_data.get('null')),
                "identity": parse_boolean(row_data.get('identity') or row_data.get('ident')),
                "key": row_data.get('key')
            }
            
        elif table_type == "indexes":
            name = row_data.get('name') or row_data.get('index_name')
            if not name:
                return None
                
            key_columns = row_data.get('key_columns') or row_data.get('columns')
            
            # Determine if primary or unique
            is_primary = "PK" in name or name.startswith("PK_")
            is_unique = is_primary or "UK" in name or name.startswith("UQ_") or parse_boolean(row_data.get('is_unique') or row_data.get('unique'))
            
            index_data = {
                "name": name,
                "key_columns": key_columns,
                "is_unique": is_unique,
                "is_primary": is_primary,
                "type": row_data.get('type') or row_data.get('index_type')
            }
            
            # Parse key columns into a list
            if key_columns:
                # Handle special case where key columns are in format "col1(ASC), col2(DESC)"
                cols = re.sub(r'\(ASC\)|\(DESC\)', '', key_columns)
                index_data["key_column_list"] = [col.strip() for col in cols.split(',')]
                
            return index_data
            
        elif table_type == "foreign_keys":
            name = row_data.get('name') or row_data.get('foreign_key_name')
            if not name:
                return None
                
            fk_data = {
                "name": name,
                "columns": row_data.get('columns') or row_data.get('column'),
                "referenced_table": row_data.get('referenced_table'),
                "referenced_columns": row_data.get('referenced_columns') or row_data.get('referenced_column'),
                "update_rule": row_data.get('update_rule'),
                "delete_rule": row_data.get('delete_rule')
            }
            
            # Parse columns into lists
            if fk_data["columns"]:
                fk_data["column_list"] = [col.strip() for col in fk_data["columns"].split(',')]
            if fk_data["referenced_columns"]:
                fk_data["referenced_column_list"] = [col.strip() for col in fk_data["referenced_columns"].split(',')]
                
            return fk_data
            
        elif table_type == "computed_columns":
            name = row_data.get('column_name') or row_data.get('name')
            if not name:
                return None
                
            return {
                "name": name,
                "formula": row_data.get('formula') or row_data.get('definition'),
                "data_type": row_data.get('data_type') or row_data.get('type'),
                "is_persisted": parse_boolean(row_data.get('is_persisted') or row_data.get('persisted'))
            }
            
        return None