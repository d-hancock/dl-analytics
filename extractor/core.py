#!/usr/bin/env python3
"""
Core data structures and utilities for the PDF schema extractor.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional


@dataclass
class ParsedSection:
    columns: List[Dict] = field(default_factory=list)
    indexes: List[Dict] = field(default_factory=list)
    foreign_keys: List[Dict] = field(default_factory=list)
    computed_columns: List[Dict] = field(default_factory=list)
    provenance: str = ""  # "pdf" | "html" | "ocr"


ParsedResult = Dict[str, ParsedSection]  # keyed by "schema.table"


def parse_column_section(column_text: str) -> List[Dict]:
    """
    Parse the column section text into a structured list of dictionaries.
    
    Args:
        column_text: The raw text of the column section
    
    Returns:
        A list of dictionaries with column information
    """
    if not column_text:
        return []
    
    # Split the text into lines and remove empty lines
    lines = [line.strip() for line in column_text.split('\n') if line.strip()]
    
    # The first line might contain column headers, check if it has "Data Type" or similar
    header_line = None
    data_lines = lines
    
    for i, line in enumerate(lines):
        if "Data Type" in line or "Allow Nulls" in line:
            header_line = line
            data_lines = lines[i+1:]
            break
    
    # If we couldn't find a header, try a different approach
    if not header_line:
        # Try to find a line with "Key Name" which often indicates the start of columns
        for i, line in enumerate(lines):
            if "Key Name" in line:
                header_line = line
                data_lines = lines[i+1:]
                break
    
    columns = []
    
    for line in data_lines:
        # Skip lines that are clearly not column definitions
        if not line or line.startswith("Page") or line.startswith("Copyright") or "OLTP DB" in line:
            continue
        
        parts = line.split()
        if len(parts) < 3:  # Need at least name, type, and some property
            continue
        
        column = {
            "name": parts[0],
            "data_type": parts[1]
        }
        
        # Try to extract length if present
        length_idx = -1
        for i, part in enumerate(parts):
            if part.isdigit() and i > 1:  # Skip the first two parts which are name and type
                column["length"] = int(part)
                length_idx = i
                break
        
        # Extract nullability
        if "True" in parts[length_idx+1:] or "False" in parts[length_idx+1:]:
            column["nullable"] = "True" in parts[length_idx+1:]
        
        # Check for identity property
        if length_idx > 0 and length_idx < len(parts) - 1:
            remaining = " ".join(parts[length_idx+1:])
            if "-" in remaining and any(char.isdigit() for char in remaining):
                identity_parts = remaining.split("-")
                if len(identity_parts) >= 2 and identity_parts[0].strip().isdigit():
                    column["identity_seed"] = identity_parts[0].strip()
                    column["identity_increment"] = identity_parts[1].strip()
        
        # Check for default value
        if "((" in line and "))" in line:
            default_start = line.find("((")
            default_end = line.find("))", default_start) + 2
            column["default"] = line[default_start:default_end]
        
        columns.append(column)
    
    return columns


def parse_index_section(index_text: str) -> List[Dict]:
    """
    Parse the index section text into a structured list of dictionaries.
    
    Args:
        index_text: The raw text of the index section
    
    Returns:
        A list of dictionaries with index information
    """
    if not index_text:
        return []
    
    # Split the text into lines and remove empty lines
    lines = [line.strip() for line in index_text.split('\n') if line.strip()]
    
    # The first line might be a header
    header_line = None
    data_lines = lines
    
    for i, line in enumerate(lines):
        if "Key Name" in line and "Key Columns" in line:
            header_line = line
            data_lines = lines[i+1:]
            break
    
    # If we couldn't find a header, use a different approach
    if not header_line:
        for i, line in enumerate(lines):
            if line.startswith("PK_") or line.startswith("IX_") or line.startswith("UQ_"):
                data_lines = lines[i:]
                break
    
    indices = []
    
    for line in data_lines:
        # Skip lines that are clearly not index definitions
        if (not line or line.startswith("Page") or line.startswith("Copyright") 
            or "OLTP DB" in line or "Proprietary" in line):
            continue
        
        parts = line.split()
        if len(parts) < 2:
            continue
        
        index = {
            "name": parts[0]
        }
        
        # Extract key columns - they are usually the second element
        columns_part = " ".join(parts[1:-2]) if len(parts) > 3 else parts[1]
        index["columns"] = columns_part
        
        # Check for uniqueness
        index["is_unique"] = "True" in parts[-2] if len(parts) > 2 else False
        
        # Check for fill factor if present
        if len(parts) > 3 and parts[-1].isdigit():
            index["fill_factor"] = int(parts[-1])
        
        indices.append(index)
    
    return indices


def parse_foreign_key_section(fk_text: str) -> List[Dict]:
    """
    Parse the foreign key section text into a structured list of dictionaries.
    
    Args:
        fk_text: The raw text of the foreign key section
    
    Returns:
        A list of dictionaries with foreign key information
    """
    if not fk_text:
        return []
    
    # Split the text into lines and remove empty lines
    lines = [line.strip() for line in fk_text.split('\n') if line.strip()]
    
    # Foreign keys are more complex, they may span multiple lines
    # We'll look for patterns like "FK_" followed by "References" later in the text
    
    foreign_keys = []
    current_fk = None
    
    for line in lines:
        # Skip irrelevant lines
        if (not line or line.startswith("Page") or line.startswith("Copyright") 
            or "OLTP DB" in line or "Proprietary" in line):
            continue
        
        # Start of a new FK
        if line.startswith("FK_") or "foreign key" in line.lower():
            if current_fk:  # Save the previous FK if exists
                foreign_keys.append(current_fk)
            
            current_fk = {
                "name": line.split()[0],
                "columns": []
            }
        
        # Reference information
        elif current_fk and ("references" in line.lower() or "refer" in line.lower()):
            # Extract referenced table and columns
            parts = line.lower().split("references")
            if len(parts) > 1:
                ref_parts = parts[1].strip().split("(")
                
                current_fk["referenced_table"] = ref_parts[0].strip()
                
                if len(ref_parts) > 1 and ")" in ref_parts[1]:
                    col_part = ref_parts[1].split(")")[0].strip()
                    current_fk["referenced_columns"] = [c.strip() for c in col_part.split(",")]
        
        # Columns information
        elif current_fk and "(" in line and ")" in line:
            col_start = line.find("(")
            col_end = line.find(")")
            if col_start != -1 and col_end != -1:
                columns = line[col_start+1:col_end].strip()
                current_fk["columns"] = [c.strip() for c in columns.split(",")]
    
    # Add the last FK if exists
    if current_fk:
        foreign_keys.append(current_fk)
    
    return foreign_keys