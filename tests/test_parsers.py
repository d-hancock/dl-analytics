#!/usr/bin/env python3
"""
Test parsers for extracted table definitions.
"""

import os
import sys
import json
import unittest
from pathlib import Path

# Add parent directory to path so we can import our module
sys.path.insert(0, str(Path(__file__).parent.parent))
from extractor.core import parse_column_section, parse_index_section, parse_foreign_key_section

class TestParsers(unittest.TestCase):
    """Test the parsers for table definition sections."""
    
    def test_column_parser(self):
        """Test the column section parser."""
        sample_text = """Max Length
Key Name Data Type (Bytes) Allow Nulls Identity Default
Id int 4 False 500001 - 1
Name varchar(255) 255 False
Description varchar(1000) 1000 True
IsActive bit 1 False ((1))"""
        
        result = parse_column_section(sample_text)
        
        # Basic validations
        self.assertEqual(len(result), 4)
        self.assertEqual(result[0]["name"], "Id")
        self.assertEqual(result[0]["data_type"], "int")
        self.assertEqual(result[0]["length"], 4)
        self.assertEqual(result[0]["nullable"], False)
        
        self.assertEqual(result[1]["name"], "Name")
        self.assertEqual(result[1]["data_type"], "varchar(255)")
        self.assertEqual(result[1]["length"], 255)
        self.assertEqual(result[1]["nullable"], False)
        
        self.assertEqual(result[2]["name"], "Description")
        self.assertEqual(result[2]["data_type"], "varchar(1000)")
        self.assertEqual(result[2]["length"], 1000)
        self.assertEqual(result[2]["nullable"], True)
        
        self.assertEqual(result[3]["name"], "IsActive")
        self.assertEqual(result[3]["data_type"], "bit")
        self.assertEqual(result[3]["length"], 1)
        self.assertEqual(result[3]["nullable"], False)
        self.assertEqual(result[3]["default"], "((1))")
    
    def test_index_parser(self):
        """Test the index section parser."""
        sample_text = """Key Name Key Columns Unique Fill Factor
PK_PhysicianOrder485Order Id True 90
UQ_PhysicianOrder485OrderName Name True 80"""
        
        result = parse_index_section(sample_text)
        
        # Basic validations
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["name"], "PK_PhysicianOrder485Order")
        self.assertEqual(result[0]["columns"], "Id")
        self.assertEqual(result[0]["is_unique"], True)
        self.assertEqual(result[0]["fill_factor"], 90)
        
        self.assertEqual(result[1]["name"], "UQ_PhysicianOrder485OrderName")
        self.assertEqual(result[1]["columns"], "Name")
        self.assertEqual(result[1]["is_unique"], True)
        self.assertEqual(result[1]["fill_factor"], 80)
    
    def test_with_real_file(self):
        """Test parsing with real extracted JSON files."""
        # Find a real extracted JSON file in the workspace to test with
        extracted_dir = Path("/home/dale/development/dl-analytics/notes/extracted_inventory_onwards")
        if not extracted_dir.exists():
            self.skipTest("Skipping test_with_real_file as extracted directory not found")
            return
        
        # Find any JSON file in the directory
        json_files = list(extracted_dir.glob("*.json"))
        if not json_files:
            self.skipTest("No JSON files found in extracted directory")
            return
        
        # Use the first JSON file found
        test_file = json_files[0]
        
        with open(test_file, 'r') as f:
            data = json.load(f)
        
        # If the file has a column_section, test parsing it
        if "column_section" in data:
            columns = parse_column_section(data["column_section"])
            self.assertTrue(len(columns) > 0, "Should parse at least one column")
            self.assertIsInstance(columns[0], dict, "Column should be a dictionary")
            print(f"\nParsed {len(columns)} columns from {test_file.name}")
            print(f"First column: {columns[0]}")
        
        # If the file has an index_section, test parsing it
        if "index_section" in data:
            indexes = parse_index_section(data["index_section"])
            if indexes:  # Some tables might not have indexes
                self.assertIsInstance(indexes[0], dict, "Index should be a dictionary")
                print(f"Parsed {len(indexes)} indexes from {test_file.name}")
                print(f"First index: {indexes[0]}")
        
        # If the file has a fk_section, test parsing it
        if "fk_section" in data:
            fks = parse_foreign_key_section(data["fk_section"])
            if fks:  # Some tables might not have foreign keys
                self.assertIsInstance(fks[0], dict, "Foreign key should be a dictionary")
                print(f"Parsed {len(fks)} foreign keys from {test_file.name}")
                print(f"First foreign key: {fks[0]}")


if __name__ == "__main__":
    unittest.main()