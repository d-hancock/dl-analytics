#!/usr/bin/env python3
"""
Schema merger module.
Reconciles schema data extracted from different sources (PDF and HTML).
"""

from datetime import datetime
from typing import Dict, List, Any, Optional
from copy import deepcopy

from .core import ParsedResult, ParsedSection


class SchemaMerger:
    """
    Merges schema information from different sources with configurable preferences.
    Reconciles conflicts and produces a unified result.
    """
    
    def __init__(self, prefer_html: bool = True):
        """
        Initialize the merger with source preference.
        
        Args:
            prefer_html: If True, HTML data takes precedence when both sources 
                       have values for the same fields. If False, PDF wins.
        """
        self.prefer_html = prefer_html
    
    def merge(self, pdf_data: ParsedResult, html_data: ParsedResult) -> Dict[str, Any]:
        """
        Merge data from PDF and HTML sources.
        
        Args:
            pdf_data: Table definitions extracted from PDF
            html_data: Table definitions extracted from HTML
            
        Returns:
            A JSON-serializable dict with merged schema information
        """
        print("Merging schema data from PDF and HTML sources...")
        print(f"Strategy: {'HTML preferred' if self.prefer_html else 'PDF preferred'}")
        print(f"PDF data: {len(pdf_data)} tables")
        print(f"HTML data: {len(html_data)} tables")
        
        # Initialize result structure
        result = {
            "metadata": {
                "extraction_date": datetime.now().isoformat(),
                "total_tables": 0,
                "pdf_only_tables": 0,
                "html_only_tables": 0,
                "merged_tables": 0,
                "warnings": []
            },
            "tables": {}
        }
        
        # Get all unique table names
        all_tables = set(pdf_data.keys()) | set(html_data.keys())
        result["metadata"]["total_tables"] = len(all_tables)
        
        # Process each table
        for table_name in all_tables:
            merged_table = self._merge_table(
                table_name, 
                pdf_data.get(table_name), 
                html_data.get(table_name)
            )
            
            # Add table to result
            if merged_table:
                result["tables"][table_name] = merged_table
                
                # Update metadata counters
                if table_name in pdf_data and table_name in html_data:
                    result["metadata"]["merged_tables"] += 1
                elif table_name in pdf_data:
                    result["metadata"]["pdf_only_tables"] += 1
                else:  # table_name in html_data
                    result["metadata"]["html_only_tables"] += 1
        
        print(f"Merge complete. {result['metadata']['total_tables']} tables in result.")
        return result
    
    def _merge_table(self, 
                    table_name: str, 
                    pdf_section: Optional[ParsedSection], 
                    html_section: Optional[ParsedSection]) -> Dict[str, Any]:
        """
        Merge data for a single table from both sources.
        
        Args:
            table_name: The name of the table
            pdf_section: ParsedSection from PDF source, or None if not available
            html_section: ParsedSection from HTML source, or None if not available
            
        Returns:
            Dictionary with merged table data
        """
        # Initialize output structure
        merged_data = {
            "schema": table_name.split('.')[0] if '.' in table_name else "dbo",
            "table_name": table_name.split('.')[1] if '.' in table_name else table_name,
            "columns": [],
            "indexes": [],
            "foreign_keys": [],
            "computed_columns": [],
            "extraction_source": "",
            "warnings": []
        }
        
        # Case 1: We only have PDF data
        if pdf_section and not html_section:
            merged_data["extraction_source"] = "pdf"
            merged_data["columns"] = deepcopy(pdf_section.columns)
            merged_data["indexes"] = deepcopy(pdf_section.indexes)
            merged_data["foreign_keys"] = deepcopy(pdf_section.foreign_keys)
            merged_data["computed_columns"] = deepcopy(pdf_section.computed_columns)
            return merged_data
            
        # Case 2: We only have HTML data
        elif html_section and not pdf_section:
            merged_data["extraction_source"] = "html"
            merged_data["columns"] = deepcopy(html_section.columns)
            merged_data["indexes"] = deepcopy(html_section.indexes)
            merged_data["foreign_keys"] = deepcopy(html_section.foreign_keys)
            merged_data["computed_columns"] = deepcopy(html_section.computed_columns)
            return merged_data
            
        # Case 3: We have both sources - need to merge
        elif pdf_section and html_section:
            merged_data["extraction_source"] = "merged"
            
            # Preferred source goes first
            primary = html_section if self.prefer_html else pdf_section
            secondary = pdf_section if self.prefer_html else html_section
            primary_name = "html" if self.prefer_html else "pdf"
            secondary_name = "pdf" if self.prefer_html else "html"
            
            # Merge columns
            merged_data["columns"] = self._merge_section_items(
                primary.columns, secondary.columns, 
                table_name, "column", "name", 
                merged_data["warnings"], primary_name, secondary_name
            )
            
            # Merge indexes
            merged_data["indexes"] = self._merge_section_items(
                primary.indexes, secondary.indexes, 
                table_name, "index", "name", 
                merged_data["warnings"], primary_name, secondary_name
            )
            
            # Merge foreign keys
            merged_data["foreign_keys"] = self._merge_section_items(
                primary.foreign_keys, secondary.foreign_keys, 
                table_name, "foreign key", "name", 
                merged_data["warnings"], primary_name, secondary_name
            )
            
            # Merge computed columns
            merged_data["computed_columns"] = self._merge_section_items(
                primary.computed_columns, secondary.computed_columns, 
                table_name, "computed column", "name", 
                merged_data["warnings"], primary_name, secondary_name
            )
            
            return merged_data
            
        # Should never get here
        return merged_data
    
    def _merge_section_items(self, 
                            primary_items: List[Dict[str, Any]], 
                            secondary_items: List[Dict[str, Any]], 
                            table_name: str,
                            item_type: str,
                            id_field: str,
                            warnings: List[str],
                            primary_name: str,
                            secondary_name: str) -> List[Dict[str, Any]]:
        """
        Merge lists of items (columns, indexes, etc.) using the preferred source precedence.
        
        Args:
            primary_items: Items from the preferred source
            secondary_items: Items from the secondary source
            table_name: Name of the table being processed
            item_type: Type of item ('column', 'index', etc.)
            id_field: Field name used to identify items (usually 'name')
            warnings: List to append warnings to
            primary_name: Name of the primary source ('pdf' or 'html')
            secondary_name: Name of the secondary source
            
        Returns:
            List of merged items
        """
        # If either list is empty, return the other one
        if not primary_items:
            return deepcopy(secondary_items)
        if not secondary_items:
            return deepcopy(primary_items)
            
        # Start with all items from primary source
        result = deepcopy(primary_items)
        
        # Create a map of primary items by ID for quick lookup
        primary_map = {item[id_field].lower(): item for item in primary_items if id_field in item}
        
        # Process secondary items
        for sec_item in secondary_items:
            if id_field not in sec_item:
                # Items without an ID can't be merged properly, so append them
                result.append(deepcopy(sec_item))
                warnings.append(
                    f"Warning: {item_type} in {table_name} from {secondary_name} "
                    f"is missing {id_field}, added as separate item"
                )
                continue
                
            # Check if this item exists in the primary source
            sec_id = sec_item[id_field].lower()
            if sec_id in primary_map:
                # Item exists in both sources - check for conflicts
                pri_item = primary_map[sec_id]
                
                # Compare items for differences and log warnings
                for key, sec_value in sec_item.items():
                    if key in pri_item:
                        pri_value = pri_item[key]
                        # Check for non-trivial differences
                        if (sec_value != pri_value and 
                            sec_value is not None and 
                            pri_value is not None):
                            warnings.append(
                                f"Conflict: {item_type} '{sec_item[id_field]}' in {table_name} "
                                f"has different '{key}' values: "
                                f"{primary_name}='{pri_value}', {secondary_name}='{sec_value}'. "
                                f"Using {primary_name} version."
                            )
            else:
                # Item only in secondary source - add it
                result.append(deepcopy(sec_item))
                
        return result