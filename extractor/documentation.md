# PDF Schema Extractor Documentation

## Overview

This module provides a clean, modular implementation of a PDF schema extraction tool. It parses PDF data dictionary documents to extract structured information about database tables, including columns, indexes, foreign keys, and computed columns. The extractor supports both text-based parsing from the PDF content and HTML-based parsing for improved accuracy.

## Architecture

The code has been refactored into a proper Python package structure with single-responsibility classes, pure parsing functions, and explicit data flow:

```
extractor/
├── __init__.py
├── core.py          # Core data structures and utilities
├── doc_prep.py      # DocumentPrep class for text/HTML extraction
├── pdf_parser.py    # PdfTextParser for text parsing
├── html_parser.py   # HtmlDomParser for HTML parsing
├── merger.py        # SchemaMerger for reconciling data
└── cli.py           # CLI interface with extract_schema function
tests/
└── test_parsers.py  # Unit tests
```

## Components

### Core (`core.py`)

Contains fundamental data structures and utility functions used across the module:

- `ParsedSection`: A dataclass for storing table schema components
- `ParsedResult`: Type definition for mapping table names to their `ParsedSection`s
- Utility functions: `get_file_hash()`, `clean_table_name()`, `parse_boolean()`

### Document Preparation (`doc_prep.py`)

The `DocumentPrep` class handles the conversion of PDF files to text and HTML formats for subsequent parsing:

- Uses `pdfplumber` for text extraction
- Invokes `pdf2htmlEX` command-line tool for HTML conversion
- Implements caching to avoid redundant processing
- Returns paths to both text and HTML versions of the document

### PDF Text Parser (`pdf_parser.py`)

The `PdfTextParser` class processes the text dump of a PDF to extract structured table information:

- Locates and parses the Table of Contents
- Identifies table definitions in the text
- Uses regex and position-based parsing to extract:
  - Columns (name, data type, nullability, etc.)
  - Indexes (name, uniqueness, key columns, etc.)
  - Foreign keys (name, columns, referenced tables, etc.)
  - Computed columns (name, formula, etc.)
- Works exclusively on the text file, never accessing the original PDF

### HTML DOM Parser (`html_parser.py`)

The `HtmlDomParser` class parses the HTML version of the document using BeautifulSoup:

- Finds table definitions by searching headings
- Identifies and classifies HTML tables based on their content
- Extracts structured information from tables
- Normalizes extracted data to match the core data structures
- Never refers back to the original PDF

### Schema Merger (`merger.py`)

The `SchemaMerger` class reconciles data from both PDF and HTML parsing:

- Configurable source precedence (HTML or PDF)
- Detects and logs conflicts between sources
- Produces a unified JSON-serializable result
- Includes metadata and warnings

### CLI Interface (`cli.py`)

Provides the entry point and command-line interface for the extractor:

- `extract_schema()` function orchestrates the extraction pipeline
- Command-line argument parsing via `argparse`
- Error handling and user-friendly output
- Caching support

## Usage

### Basic Usage

```bash
python -m extractor.cli
```

### Notes
- The PDF file location and output JSON file location are now hardcoded in the script. Ensure these paths are correctly set in the code before running the command.
- The `force` flag is preserved to allow overwriting cached results if necessary.

## Key Features

1. **Caching**: Results are cached based on the SHA-256 hash of the PDF file to avoid redundant processing.
2. **Dual Parsing Strategy**: Combines text-based and HTML-based parsing for improved accuracy.
3. **Clean Architecture**: Each component has a single responsibility with explicit interfaces.
4. **Conflict Resolution**: Configurable preference between PDF and HTML sources with warning logs for conflicts.
5. **Type Safety**: Comprehensive type hints throughout the codebase.
6. **Error Handling**: Robust error handling with informative error messages.

## Data Structures

The primary output structure follows this schema:

```json
{
  "metadata": {
    "extraction_date": "2025-04-28T12:34:56.789012",
    "total_tables": 42,
    "pdf_only_tables": 5,
    "html_only_tables": 3,
    "merged_tables": 34,
    "warnings": ["Conflict: column 'ID' in dbo.User has different 'data_type' values..."]
  },
  "tables": {
    "schema.table_name": {
      "schema": "schema",
      "table_name": "table_name",
      "columns": [
        {
          "name": "ColumnName",
          "data_type": "varchar(50)",
          "max_length": "50",
          "allow_nulls": false,
          "identity": false,
          "key": "PK"
        }
      ],
      "indexes": [
        {
          "name": "PK_TableName",
          "key_columns": "ColumnName",
          "is_unique": true,
          "is_primary": true
        }
      ],
      "foreign_keys": [
        {
          "name": "FK_TableName_RefTable",
          "columns": "ColumnName",
          "referenced_table": "RefTable",
          "referenced_columns": "RefColumn",
          "update_rule": "CASCADE",
          "delete_rule": "NO ACTION"
        }
      ],
      "computed_columns": [
        {
          "name": "ComputedCol",
          "formula": "Col1 + Col2",
          "data_type": "int",
          "is_persisted": true
        }
      ],
      "extraction_source": "merged",
      "warnings": []
    }
  }
}
```

## Testing

Basic unit tests are provided in `tests/test_parsers.py` and can be run with pytest:

```bash
pytest tests/
```

## Limitations and Future Improvements

1. **OCR Support**: Currently lacks OCR capabilities for scanned PDFs.
2. **Configurable Parsing Rules**: Could benefit from customizable parsing rules for different PDF formats.
3. **Progress Reporting**: No progress callbacks for long-running operations.
4. **Parallel Processing**: Could implement parallel table processing for large documents.
5. **Schema Validation**: Could add JSON schema validation for the output.