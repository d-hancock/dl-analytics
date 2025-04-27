#!/usr/bin/env python3
import PyPDF2
import os
import re

PDF_PATH = "CareTend Data Dictionary OLTP DB.pdf"

def find_table_of_contents(reader):
    """Search for the Table of Contents in the PDF and return its location"""
    print("\nSearching for Table of Contents...")
    
    for i in range(min(20, len(reader.pages))):  # Check first 20 pages
        page = reader.pages[i]
        text = page.extract_text() or ""
        
        if "Table of Contents" in text:
            print(f"Found 'Table of Contents' on PDF page {i+1}")
            # Extract a section of text around the TOC header
            toc_section = text[:1000]  # Show first 1000 chars of TOC
            print("\n--- Table of Contents Preview ---")
            print(toc_section)
            print("...")
            
            # Extract page number if available
            page_num_match = re.search(r'page\s+(\d+)\s+of\s+(\d+)', text, re.IGNORECASE)
            if page_num_match:
                doc_page = page_num_match.group(1)
                total_pages = page_num_match.group(2)
                print(f"\nDocument page numbering: Page {doc_page} of {total_pages}")
                print(f"Page offset: {i+1-int(doc_page)} (PDF page number minus document page number)")
            
            return i
    
    print("Table of Contents not found in first 20 pages")
    return None

def main():
    if not os.path.exists(PDF_PATH):
        print(f"Error: PDF file '{PDF_PATH}' not found in {os.getcwd()}")
        return
    
    try:
        print(f"Opening PDF file: {PDF_PATH}")
        reader = PyPDF2.PdfReader(open(PDF_PATH, "rb"))
        print(f"PDF loaded successfully with {len(reader.pages)} pages")
        
        # Print content of the first 2 pages for debugging
        for i in range(min(2, len(reader.pages))):
            page = reader.pages[i]
            text = page.extract_text() or ""
            print(f"\n--- Page {i+1} Content (first 500 chars) ---")
            print(text[:500])
            print("..." if len(text) > 500 else "")
        
        # Find the Table of Contents
        toc_page = find_table_of_contents(reader)
        
        # Explain page numbering
        print("\n--- Page Numbering Information ---")
        print("PDF page 3 corresponds to document page 1 (offset of 2 pages)")
        print("This is likely due to cover page and another preliminary page")
        
        # Look at a specific document page
        if toc_page is not None:
            doc_page = 10  # Try to view document page 10
            pdf_page = doc_page + 2  # Add offset
            
            if pdf_page < len(reader.pages):
                page_text = reader.pages[pdf_page].extract_text() or ""
                print(f"\n--- Document Page {doc_page} (PDF Page {pdf_page+1}) Preview ---")
                print(page_text[:500])
                print("...")
        
    except Exception as e:
        print(f"Error processing PDF: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()