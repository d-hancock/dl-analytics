#!/usr/bin/env python3
"""
Command-line interface for PDF schema extraction.
Provides the main entry point for the extraction pipeline.
"""

import argparse
import json
import sys
import os
from pathlib import Path
from typing import Optional, Dict, Any

from .core import get_file_hash
from .doc_prep import DocumentPrep
from .pdf_parser import PdfTextParser
from .html_parser import HtmlDomParser
from .merger import SchemaMerger


def extract_schema(pdf_path: Optional[Path] = None, out_path: Optional[Path] = None, force: bool = False) -> Dict[str, Any]:
    """
    Extract schema information from a PDF file.
    
    Args:
        pdf_path: Path to the PDF file to process (defaults to finding CareTend Data Dictionary in notes folder)
        out_path: Path where output JSON should be saved (defaults to PDF name with .json extension)
        force: If True, bypass cache and regenerate results
        
    Returns:
        Dictionary with extracted schema information
    """
    # Set default PDF path if not provided
    if pdf_path is None:
        # Look for the CareTend PDF in well-known locations
        potential_paths = [
            Path("notes/CareTend Data Dictionary OLTP DB.pdf"),
            Path("../notes/CareTend Data Dictionary OLTP DB.pdf"),
            Path(os.path.expanduser("~/development/dl-analytics/notes/CareTend Data Dictionary OLTP DB.pdf"))
        ]
        
        for p in potential_paths:
            if p.exists():
                pdf_path = p
                print(f"Using default PDF path: {pdf_path}")
                break
        
        if pdf_path is None:
            raise FileNotFoundError("No PDF path provided and default PDF not found. Please specify a PDF path.")
    
    # Validate input
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF file not found: {pdf_path}")
        
    # Set up paths
    pdf_path = pdf_path.resolve()
    
    # Set default output path if not provided
    if out_path is None:
        # Default to same directory as PDF with .json extension
        out_path = pdf_path.with_suffix('.json')
        print(f"Using default output path: {out_path}")
    
    out_path = out_path.resolve()
    
    # Ensure output directory exists
    out_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Create cache directory
    cache_dir = out_path.parent / ".cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if we should use cached result
    result_cache_path = cache_dir / f"{get_file_hash(pdf_path)}_result.json"
    if result_cache_path.exists() and not force:
        print(f"Using cached result from: {result_cache_path}")
        try:
            with open(result_cache_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except json.JSONDecodeError:
            print("Cache file is corrupted. Will regenerate.")
    
    print("-" * 50)
    print(f"Starting schema extraction for: {pdf_path}")
    print("-" * 50)
    
    # Step 1: Document preparation - extract text and HTML from PDF
    doc_prep = DocumentPrep(pdf_path, cache_dir)
    txt_path, html_path = doc_prep.run()
    
    # Step 2: Parse the text version with the PDF parser
    pdf_parser = PdfTextParser(txt_path)
    pdf_results = pdf_parser.parse()
    print(f"PDF parser extracted {len(pdf_results)} tables")
    
    # Step 3: Parse the HTML version with the HTML parser
    html_parser = HtmlDomParser(html_path)
    html_results = html_parser.parse()
    print(f"HTML parser extracted {len(html_results)} tables")
    
    # Step 4: Merge the results with SchemaMerger
    merger = SchemaMerger(prefer_html=True)
    final_result = merger.merge(pdf_results, html_results)
    
    # Save the result
    print(f"Saving output to: {out_path}")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(final_result, f, indent=2)
        
    # Cache the result
    print(f"Caching result to: {result_cache_path}")
    with open(result_cache_path, 'w', encoding='utf-8') as f:
        json.dump(final_result, f, indent=2)
    
    print("-" * 50)
    print(f"Extraction complete.")
    print(f"Found {final_result['metadata']['total_tables']} tables:")
    print(f"  - {final_result['metadata']['pdf_only_tables']} from PDF only")
    print(f"  - {final_result['metadata']['html_only_tables']} from HTML only")
    print(f"  - {final_result['metadata']['merged_tables']} from both sources")
    if final_result["metadata"].get("warnings"):
        print(f"  - {len(final_result['metadata']['warnings'])} warnings")
    print("-" * 50)
    
    return final_result


def main():
    """
    Command line entry point for the schema extractor.
    Parses arguments and runs the extraction pipeline.
    """
    parser = argparse.ArgumentParser(
        description='Extract database schema definitions from a PDF data dictionary.'
    )
    parser.add_argument('pdf_path', 
                        type=Path, 
                        nargs='?',  # Make it optional
                        default=None,
                        help='Path to the PDF file to process (defaults to looking for CareTend Data Dictionary)')
    parser.add_argument('--output', '-o',
                        type=Path,
                        help='Path for the output JSON file (default: same as PDF with .json extension)')
    parser.add_argument('--force', '-f',
                        action='store_true',
                        help='Force regeneration of results, ignoring cache')
    parser.add_argument('--prefer-pdf',
                        action='store_true',
                        help='Prefer PDF data over HTML data when conflicts occur')
    
    args = parser.parse_args()
    
    try:
        # Set up schema merger preferences
        prefer_html = not args.prefer_pdf
        
        # Run extraction
        extract_schema(
            pdf_path=args.pdf_path,
            out_path=args.output,
            force=args.force
        )
        
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error during extraction: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(2)


if __name__ == "__main__":
    main()