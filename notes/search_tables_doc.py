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
        with open(json_file_path, 'r', encoding='utf-8') as f: # Added encoding
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{json_file_path}' not found.")
        sys.exit(1)
    except json.JSONDecodeError as e: # Added specific error
        print(f"Error: File '{json_file_path}' contains invalid JSON: {e}")
        sys.exit(1)


def list_schemas(tables_data: Dict) -> List[str]:
    """List all schemas in the documentation."""
    return sorted(list(tables_data.keys())) # Added sorting


def list_tables_in_schema(tables_data: Dict, schema_name: str) -> List[str]:
    """List all tables in a specific schema."""
    # Case-insensitive schema check
    schema_key = next((k for k in tables_data if k.lower() == schema_name.lower()), None)
    if not schema_key:
        print(f"Error: Schema '{schema_name}' not found.")
        return []
    
    return sorted(list(tables_data[schema_key].keys())) # Added sorting


def find_table(tables_data: Dict, table_name: str, schema_name: Optional[str] = None) -> List[Dict]:
    """Find tables matching the given name, optionally filtered by schema (case-insensitive)."""
    results = []
    schemas_to_search = []

    if schema_name:
        # Find the actual schema key case-insensitively
        schema_key = next((k for k in tables_data if k.lower() == schema_name.lower()), None)
        if schema_key:
            schemas_to_search = [schema_key]
        else:
             # If schema specified but not found, return empty
             return []
    else:
        schemas_to_search = list(tables_data.keys())

    for schema in schemas_to_search:
        for table, table_data in tables_data[schema].items():
            if table.lower() == table_name.lower():
                # Ensure essential keys exist before adding
                if table_data and isinstance(table_data, dict):
                     # Add schema and table name explicitly if missing in data
                     table_data.setdefault('schema', schema)
                     table_data.setdefault('table_name', table)
                     results.append(table_data)

    return results


def find_table_by_contains(tables_data: Dict, search_text: str, schema_name: Optional[str] = None) -> List[Dict]:
    """Find tables where schema, table, or column names contain the search text (case-insensitive)."""
    results = []
    search_lower = search_text.lower()
    schemas_to_search = []

    if schema_name:
        # Find the actual schema key case-insensitively
        schema_key = next((k for k in tables_data if k.lower() == schema_name.lower()), None)
        if schema_key:
            schemas_to_search = [schema_key]
        else:
            # If schema specified but not found, return empty
            return []
    else:
        schemas_to_search = list(tables_data.keys())

    for schema in schemas_to_search:
        for table, table_data in tables_data[schema].items():
            match = False
            if search_lower in table.lower() or search_lower in schema.lower():
                match = True
            elif "columns" in table_data and isinstance(table_data["columns"], list):
                for column in table_data["columns"]:
                    if isinstance(column, dict) and "name" in column and search_lower in column["name"].lower():
                        match = True
                        break # Found a match in columns, no need to check further for this table

            if match and table_data and isinstance(table_data, dict):
                # Add schema and table name explicitly if missing in data
                table_data.setdefault('schema', schema)
                table_data.setdefault('table_name', table)
                results.append(table_data)

    return results


def find_column(tables_data: Dict, column_name: str, schema_name: Optional[str] = None) -> List[Dict]:
    """Find tables with columns matching the given name (case-insensitive), optionally filtered by schema."""
    results = []
    column_lower = column_name.lower()
    schemas_to_search = []

    if schema_name:
        # Find the actual schema key case-insensitively
        schema_key = next((k for k in tables_data if k.lower() == schema_name.lower()), None)
        if schema_key:
            schemas_to_search = [schema_key]
        else:
            # If schema specified but not found, return empty
            return []
    else:
        schemas_to_search = list(tables_data.keys())

    for schema in schemas_to_search:
        for table, table_data in tables_data[schema].items():
            if table_data and "columns" in table_data and isinstance(table_data["columns"], list):
                for column in table_data["columns"]:
                    if isinstance(column, dict) and "name" in column and column["name"].lower() == column_lower:
                        # Add schema and table name explicitly if missing in data
                        table_data.setdefault('schema', schema)
                        table_data.setdefault('table_name', table)
                        results.append({
                            "table": table_data,
                            "column": column
                        })
                        # Assuming column names are unique per table, break inner loop
                        break

    return results


def format_table_info(table_data: Dict, show_details: bool = False) -> str:
    """Format table information for display."""
    output = []

    # Use .get with defaults for safer access
    schema_name = table_data.get('schema', 'UnknownSchema')
    table_name = table_data.get('table_name', 'UnknownTable').split('.')[-1]  # Extract only the table name
    output.append(f"=== Table: {schema_name}.{table_name} ===")

    output.append(f"Schema: {schema_name}")
    output.append(f"Documentation Page: {table_data.get('doc_page', 'N/A')}")
    output.append(f"PDF Page: {table_data.get('pdf_page', 'N/A')}")

    if show_details:
        # Columns
        columns = table_data.get("columns", [])
        if columns and isinstance(columns, list):
            output.append("\nColumns:")
            for column in columns:
                if isinstance(column, dict):
                    col_name = column.get('name', 'UnknownColumn')
                    col_type = column.get('data_type', 'UnknownType')
                    nullable_str = "NULL" if column.get("nullable", True) else "NOT NULL"
                    default_val = column.get('default')
                    default_str = f" DEFAULT ({default_val})" if default_val is not None else ""
                    output.append(f"  {col_name}: {col_type} {nullable_str}{default_str}")
                else:
                    output.append(f"  - Invalid column data format: {column}") # Log unexpected format
        elif columns: # Log if 'columns' exists but isn't a list
             output.append(f"\nColumns: [Warning: Expected list, got {type(columns).__name__}]")


        # Indexes
        indexes = table_data.get("indexes", [])
        if indexes and isinstance(indexes, list):
            output.append("\nIndexes:")
            for index in indexes:
                if isinstance(index, dict):
                    index_name = index.get('name', 'UnknownIndex')
                    unique_str = "UNIQUE " if index.get("is_unique", False) else ""
                    index_cols = index.get('columns', 'Unknown')
                    output.append(f"  {index_name}: {unique_str}({index_cols})")
                else:
                     output.append(f"  - Invalid index data format: {index}")
        elif indexes:
             output.append(f"\nIndexes: [Warning: Expected list, got {type(indexes).__name__}]")


        # Foreign Keys
        foreign_keys = table_data.get("foreign_keys", [])
        if foreign_keys and isinstance(foreign_keys, list):
            output.append("\nForeign Keys:")
            for fk in foreign_keys:
                if isinstance(fk, dict):
                    fk_name = fk.get('name', 'UnknownFK')
                    # Future enhancement: Could add referenced table/columns if available in JSON
                    output.append(f"  {fk_name}")
                else:
                     output.append(f"  - Invalid FK data format: {fk}")
        elif foreign_keys:
             output.append(f"\nForeign Keys: [Warning: Expected list, got {type(foreign_keys).__name__}]")


    return "\n".join(output)


def format_column_info(result: Dict) -> str:
    """Format column information for display."""
    table_data = result.get("table", {})
    column_data = result.get("column", {})

    # Use .get with defaults for safer access
    schema_name = table_data.get('schema', 'UnknownSchema')
    table_name = table_data.get('table_name', 'UnknownTable')
    col_name = column_data.get('name', 'UnknownColumn')

    output = [
        f"=== Column Found: {schema_name}.{table_name}.{col_name} ===",
        f"Table: {schema_name}.{table_name}",
        f"Column: {col_name}",
        f"Data Type: {column_data.get('data_type', 'UnknownType')}",
        f"Nullable: {'Yes' if column_data.get('nullable', True) else 'No'}"
    ]

    default_val = column_data.get('default')
    if default_val is not None:
        output.append(f"Default: {default_val}")

    length = column_data.get('length')
    if length is not None:
        output.append(f"Length: {length}")

    return "\n".join(output)


def main():
    # Define command line arguments
    parser = argparse.ArgumentParser(
        description="Search tool for OLTP DB documentation (from cleaned_tables.json)",
        formatter_class=argparse.RawTextHelpFormatter # Keep help text formatting
    )
    parser.add_argument("--table", help="Search for a specific table (case-insensitive)")
    parser.add_argument("--schema", help="Filter by schema name (case-insensitive)")
    parser.add_argument("--column", help="Search for a specific column (case-insensitive)")
    parser.add_argument("--contains", help="Search text in schema, table, or column names (case-insensitive)")
    parser.add_argument("--list-schemas", action="store_true", help="List all available schemas (sorted)")
    parser.add_argument("--list-tables", metavar='SCHEMA_NAME', help="List all tables in a specific schema (case-insensitive, sorted)")
    parser.add_argument("--details", action="store_true", help="Show detailed info (columns, indexes, FKs) for found items")
    parser.add_argument("--output", help="Save results to a file")
    parser.add_argument("--json-file", default="cleaned_tables.json", help="Path to the JSON documentation file (default: notes/cleaned_tables.json)")

    args = parser.parse_args()

    # Determine the correct path to the JSON file relative to the script's location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_file_path = os.path.join(script_dir, args.json_file)

    # Load the tables documentation
    tables_data = load_tables_doc(json_file_path)

    # Initialize output list
    output_lines = []
    results_found = False # Flag to track if any command yielded results

    # --- Command Processing Logic ---
    if args.list_schemas:
        schemas = list_schemas(tables_data)
        if schemas:
            output_lines.append("Available Schemas:")
            output_lines.extend([f"  {schema}" for schema in schemas])
            results_found = True
        else:
            output_lines.append("No schemas found in the documentation file.")

    elif args.list_tables:
        schema_to_list = args.list_tables
        tables = list_tables_in_schema(tables_data, schema_to_list)

        if not tables:
            # Error message already printed by list_tables_in_schema if schema not found
            output_lines.append(f"No tables found in schema '{schema_to_list}'.")
        elif args.details:
            output_lines.append(f"Detailed information for tables in Schema '{schema_to_list}':")
            schema_key = next((k for k in tables_data if k.lower() == schema_to_list.lower()), None) # Find actual schema key
            if schema_key:
                for i, table_name in enumerate(tables):
                    # find_table expects exact match, so we use it here
                    table_results = find_table(tables_data, table_name, schema_key)
                    if table_results:
                        output_lines.append(format_table_info(table_results[0], show_details=True))
                        if i < len(tables) - 1:
                            output_lines.append("\n" + "=" * 70 + "\n") # Separator
                        results_found = True
                    else:
                        output_lines.append(f"\n-- Error retrieving details for table: {schema_key}.{table_name} --\n")
            else: # Should not happen if list_tables_in_schema worked
                 output_lines.append(f"Error: Could not re-find schema '{schema_to_list}' for details.")

        else:
            output_lines.append(f"Tables in Schema '{schema_to_list}':")
            output_lines.extend([f"  {table}" for table in tables])
            results_found = True

    elif args.table:
        results = find_table(tables_data, args.table, args.schema)
        if results:
            for i, result in enumerate(results):
                output_lines.append(format_table_info(result, args.details))
                if i < len(results) - 1:
                    output_lines.append("\n" + "-" * 50 + "\n")
            results_found = True
        else:
            schema_msg = f" in schema '{args.schema}'" if args.schema else ""
            output_lines.append(f"No tables found matching '{args.table}'{schema_msg}.")
            output_lines.append("Suggestion: Try using --contains for a broader search or check schema spelling.")


    elif args.column:
        results = find_column(tables_data, args.column, args.schema)
        if results:
            for i, result in enumerate(results):
                output_lines.append(format_column_info(result)) # Details are implicit for column search
                if i < len(results) - 1:
                    output_lines.append("\n" + "-" * 50 + "\n")
            results_found = True
        else:
            schema_msg = f" in schema '{args.schema}'" if args.schema else ""
            output_lines.append(f"No columns found matching '{args.column}'{schema_msg}.")
            output_lines.append("Suggestion: Remove --schema filter or try --contains.")


    elif args.contains:
        # Pass schema filter to contains search if provided
        results = find_table_by_contains(tables_data, args.contains, args.schema)
        if results:
            schema_msg = f" in schema '{args.schema}'" if args.schema else ""
            output_lines.append(f"Tables/Columns containing '{args.contains}'{schema_msg}:")
            for i, result in enumerate(results):
                output_lines.append(format_table_info(result, args.details))
                if i < len(results) - 1:
                    output_lines.append("\n" + "-" * 50 + "\n")
            results_found = True
        else:
            schema_msg = f" in schema '{args.schema}'" if args.schema else ""
            output_lines.append(f"No tables or columns found containing '{args.contains}'{schema_msg}.")
            output_lines.append("Suggestion: Broaden search term or check spelling.")


    else:
        # No specific action requested, show help
        parser.print_help()
        return # Exit early

    # --- Output Handling ---
    output_str = "\n".join(output_lines)

    if args.output:
        try:
            with open(args.output, "w", encoding='utf-8') as f: # Added encoding
                f.write(output_str)
            print(f"Results saved to {args.output}")
        except IOError as e:
            print(f"Error writing to output file '{args.output}': {e}")
    elif results_found or args.list_schemas: # Only print if something was actually done or listed
        print(output_str)
    elif not results_found and not args.list_schemas: # Print the "no results" messages if applicable
         print(output_str)


if __name__ == "__main__":
    main()