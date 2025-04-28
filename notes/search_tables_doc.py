#!/usr/bin/env python3
"""
Search Tool for OLTP Database Documentation

This script helps search through the cleaned_tables.json file to find relevant
table and column documentation for the CareTend OLTP database.

Usage:
  python search_tables_doc.py [options]

Options:
  --table TABLE_NAME      Search for a specific table
  --schema SCHEMA_NAME    Filter by schema name
  --column COLUMN_NAME    Search for a specific column
  --contains TEXT         Search for text in table or column names
  --list-schemas          List all available schemas
  --list-tables SCHEMA    List all tables in a specific schema
  --details               Show detailed information (columns, indexes, foreign keys)
  --output OUTPUT_FILE    Save results to a file

Examples:
  python search_tables_doc.py --table Carrier
  python search_tables_doc.py --schema Insurance --list-tables
  python search_tables_doc.py --schema Insurance --table Carrier --details
  python search_tables_doc.py --column Id --schema Insurance
  python search_tables_doc.py --contains carrier --details
"""

import json
import argparse
import os
import sys
from typing import Dict, List, Any, Optional


def load_tables_doc(json_file_path: str) -> Dict:
    """Load the cleaned_tables.json file."""
    try:
        with open(json_file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{json_file_path}' not found.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: File '{json_file_path}' contains invalid JSON.")
        sys.exit(1)


def list_schemas(tables_data: Dict) -> List[str]:
    """List all schemas in the documentation."""
    return list(tables_data.keys())


def list_tables_in_schema(tables_data: Dict, schema_name: str) -> List[str]:
    """List all tables in a specific schema."""
    if schema_name not in tables_data:
        print(f"Error: Schema '{schema_name}' not found.")
        return []
    
    return list(tables_data[schema_name].keys())


def find_table(tables_data: Dict, table_name: str, schema_name: Optional[str] = None) -> List[Dict]:
    """Find tables matching the given name, optionally filtered by schema."""
    results = []
    
    # If schema is specified, only search in that schema
    if schema_name:
        if schema_name not in tables_data:
            return []
        
        schemas_to_search = [schema_name]
    else:
        schemas_to_search = list(tables_data.keys())
    
    # Search for the table in each schema
    for schema in schemas_to_search:
        for table, table_data in tables_data[schema].items():
            if table.lower() == table_name.lower():
                results.append(table_data)
    
    return results


def find_table_by_contains(tables_data: Dict, search_text: str) -> List[Dict]:
    """Find tables that contain the search text in their name."""
    results = []
    
    for schema in tables_data:
        for table, table_data in tables_data[schema].items():
            if search_text.lower() in table.lower() or search_text.lower() in schema.lower():
                results.append(table_data)
    
    return results


def find_column(tables_data: Dict, column_name: str, schema_name: Optional[str] = None) -> List[Dict]:
    """Find tables with columns matching the given name, optionally filtered by schema."""
    results = []
    
    # If schema is specified, only search in that schema
    if schema_name:
        if schema_name not in tables_data:
            return []
        
        schemas_to_search = [schema_name]
    else:
        schemas_to_search = list(tables_data.keys())
    
    # Search for the column in each table in each schema
    for schema in schemas_to_search:
        for table, table_data in tables_data[schema].items():
            if "columns" in table_data and isinstance(table_data["columns"], list):
                for column in table_data["columns"]:
                    if isinstance(column, dict) and "name" in column and column["name"].lower() == column_name.lower():
                        results.append({
                            "table": table_data,
                            "column": column
                        })
    
    return results


def format_table_info(table_data: Dict, show_details: bool = False) -> str:
    """Format table information for display."""
    output = []

    # Add table name explicitly at the top of the output
    table_name = table_data.get('table_name', 'Unknown')
    schema_name = table_data.get('schema', 'Unknown')
    output.append(f"=== Table: {schema_name}.{table_name} ===")

    # Basic table information
    output.append(f"Schema: {schema_name}")
    output.append(f"Documentation Page: {table_data.get('doc_page', 'Unknown')}")
    output.append(f"PDF Page: {table_data.get('pdf_page', 'Unknown')}")

    # Add detailed information if requested
    if show_details:
        # Columns
        if "columns" in table_data and table_data["columns"]:
            output.append("\nColumns:")
            for column in table_data["columns"]:
                if isinstance(column, dict):
                    nullable_str = "NULL" if column.get("nullable", True) else "NOT NULL"
                    default_str = f" DEFAULT {column.get('default', '')}" if "default" in column else ""
                    output.append(f"  {column.get('name', 'Unknown')}: {column.get('data_type', 'Unknown')} {nullable_str}{default_str}")

        # Indexes
        if "indexes" in table_data and table_data["indexes"]:
            output.append("\nIndexes:")
            for index in table_data["indexes"]:
                if isinstance(index, dict):
                    unique_str = "UNIQUE " if index.get("is_unique", False) else ""
                    output.append(f"  {index.get('name', 'Unknown')}: {unique_str}({index.get('columns', 'Unknown')})")

        # Foreign Keys
        if "foreign_keys" in table_data and table_data["foreign_keys"]:
            output.append("\nForeign Keys:")
            for fk in table_data["foreign_keys"]:
                if isinstance(fk, dict):
                    output.append(f"  {fk.get('name', 'Unknown')}")

    return "\n".join(output)


def format_column_info(result: Dict) -> str:
    """Format column information for display."""
    table_data = result["table"]
    column_data = result["column"]
    
    output = []
    
    # Table information
    output.append(f"Table: {table_data.get('table_name', 'Unknown')}")
    
    # Column information
    output.append(f"Column: {column_data.get('name', 'Unknown')}")
    output.append(f"Data Type: {column_data.get('data_type', 'Unknown')}")
    output.append(f"Nullable: {'Yes' if column_data.get('nullable', True) else 'No'}")
    
    if "default" in column_data:
        output.append(f"Default: {column_data.get('default', '')}")
    
    if "length" in column_data:
        output.append(f"Length: {column_data.get('length', '')}")
    
    return "\n".join(output)


def main():
    # Define command line arguments
    parser = argparse.ArgumentParser(description="Search tool for OLTP DB documentation")
    parser.add_argument("--table", help="Search for a specific table")
    parser.add_argument("--schema", help="Filter by schema name")
    parser.add_argument("--column", help="Search for a specific column")
    parser.add_argument("--contains", help="Search for text in table or column names")
    parser.add_argument("--list-schemas", action="store_true", help="List all available schemas")
    parser.add_argument("--list-tables", help="List all tables in a specific schema")
    parser.add_argument("--details", action="store_true", help="Show detailed information (used with --table or --list-tables)") # Modified help text
    parser.add_argument("--output", help="Save results to a file")
    parser.add_argument("--json-file", default="cleaned_tables.json", help="Path to the cleaned_tables.json file")
    
    args = parser.parse_args()
    
    # Load the tables documentation
    current_dir = os.path.dirname(os.path.abspath(__file__))
    json_file_path = os.path.join(current_dir, args.json_file)
    tables_data = load_tables_doc(json_file_path)
    
    # Initialize output
    output = []
    
    # Process commands
    if args.list_schemas:
        schemas = list_schemas(tables_data)
        output.append("Available Schemas:")
        output.extend([f"  {schema}" for schema in schemas])
    
    elif args.list_tables:
        schema_to_list = args.list_tables
        tables = list_tables_in_schema(tables_data, schema_to_list)
        
        if not tables: # Handle case where schema might be invalid or empty
             output.append(f"No tables found in schema '{schema_to_list}' or schema does not exist.")
        elif args.details:
            # If --details is used with --list-tables, show details for all tables in the schema
            output.append(f"Detailed information for tables in Schema '{schema_to_list}':")
            for i, table_name in enumerate(tables):
                # Find the specific table data
                table_results = find_table(tables_data, table_name, schema_to_list)
                if table_results:
                    # Format and append the detailed info
                    output.append(format_table_info(table_results[0], show_details=True))
                    if i < len(tables) - 1:
                        output.append("\\n" + "=" * 70 + "\\n") # Separator between tables
                else:
                     # This case should ideally not happen if list_tables_in_schema worked correctly
                     output.append(f"\\n-- Error retrieving details for table: {table_name} --\\n")
        else:
            # Original behavior: just list table names
            output.append(f"Tables in Schema '{schema_to_list}':")
            output.extend([f"  {table}" for table in tables])
            
    elif args.table:
        results = find_table(tables_data, args.table, args.schema)
        if results:
            for i, result in enumerate(results):
                output.append(format_table_info(result, args.details))
                if i < len(results) - 1:
                    output.append("\\n" + "-" * 50 + "\\n")
        else:
            output.append(f"No tables found matching '{args.table}'" + (f" in schema '{args.schema}'." if args.schema else "."))

    elif args.column:
        results = find_column(tables_data, args.column, args.schema)
        if results:
            for i, result in enumerate(results):
                output.append(format_column_info(result))
                if i < len(results) - 1:
                    output.append("\\n" + "-" * 50 + "\\n")
        else:
            output.append(f"No columns found matching '{args.column}'" + (f" in schema '{args.schema}'." if args.schema else "."))
    
    elif args.contains:
        results = find_table_by_contains(tables_data, args.contains)
        if results:
            for i, result in enumerate(results):
                output.append(format_table_info(result, args.details))
                if i < len(results) - 1:
                    output.append("\\n" + "-" * 50 + "\\n")
        else:
            output.append(f"No tables found containing '{args.contains}'.")
    
    else:
        # No commands specified, show help
        parser.print_help()
        return
    
    # Format output as a single string
    output_str = "\\n".join(output)
    
    # Write to file or print to console
    if args.output:
        with open(args.output, "w") as f:
            f.write(output_str)
        print(f"Results saved to {args.output}")
    else:
        print(output_str)


if __name__ == "__main__":
    main()