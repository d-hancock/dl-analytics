#!/usr/bin/env python3
"""
Prepares text and HTML artefacts from a source PDF document, using caching.
"""

import hashlib
import subprocess
import sys
from pathlib import Path
from typing import Tuple

import pdfplumber # Assuming pdfplumber is installed

# Define a cache subdirectory name
CACHE_SUBDIR = ".cache"

class DocumentPrep:
    """
    Handles PDF hashing, caching, and conversion to text and HTML formats.
    """
    def __init__(self, pdf_path: Path, output_dir: Path):
        """
        Initialize with the source PDF path and the base output directory.

        Args:
            pdf_path: Path to the source PDF file.
            output_dir: The base directory where outputs (and cache) will be stored.
        """
        if not pdf_path.exists():
            raise FileNotFoundError(f"Source PDF not found: {pdf_path}")
        if not pdf_path.is_file():
            raise ValueError(f"Source path is not a file: {pdf_path}")

        self.pdf_path = pdf_path
        self.output_dir = output_dir
        self.cache_dir = output_dir / CACHE_SUBDIR
        self._pdf_hash = None

    def _get_pdf_hash(self) -> str:
        """Calculate and cache the SHA-256 hash of the PDF file."""
        if self._pdf_hash is None:
            hasher = hashlib.sha256()
            with open(self.pdf_path, 'rb') as f:
                while chunk := f.read(65536):  # Read in 64k chunks
                    hasher.update(chunk)
            self._pdf_hash = hasher.hexdigest()
            print(f"Calculated PDF hash: {self._pdf_hash[:10]}... for {self.pdf_path.name}")
        return self._pdf_hash

    def _ensure_cache_dir(self) -> None:
        """Create the cache directory if it doesn't exist."""
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def _get_cached_path(self, extension: str) -> Path:
        """Get the expected path for a cached file based on PDF hash and extension."""
        pdf_hash = self._get_pdf_hash()
        return self.cache_dir / f"{pdf_hash}{extension}"

    def _extract_text(self, text_path: Path) -> None:
        """Extract text using pdfplumber and save to text_path."""
        print(f"Extracting text from {self.pdf_path.name} to {text_path.name}...")
        try:
            with pdfplumber.open(self.pdf_path) as pdf:
                with open(text_path, 'w', encoding='utf-8') as f:
                    for i, page in enumerate(pdf.pages):
                        # Add a page separator consistent with PdfTextParser expectations
                        f.write(f"--- Page {i + 1} ---\n")
                        try:
                            text = page.extract_text(x_tolerance=3, y_tolerance=3)
                            if text:
                                f.write(text)
                                f.write("\n") # Ensure newline after page text
                        except Exception as e:
                            print(f"  Warning: Error extracting text from page {i + 1}: {e}", file=sys.stderr)
            print(f"Text extraction complete.")
        except Exception as e:
            # Clean up potentially incomplete file on error
            if text_path.exists():
                text_path.unlink()
            raise RuntimeError(f"Failed to extract text from PDF: {e}") from e

    def _extract_html(self, html_path: Path) -> None:
        """Convert PDF to HTML using pdf2htmlEX and save to html_path."""
        print(f"Converting {self.pdf_path.name} to HTML at {html_path.name} using pdf2htmlEX...")
        # Command: pdf2htmlEX --dest-dir <cache_dir> <pdf_path> <output_filename>
        # We need to output to a specific filename based on the hash.
        # pdf2htmlEX might not directly support outputting to a specific *filename* easily,
        # it often uses the PDF name. Let's try specifying the output file directly.
        
        # Check if pdf2htmlEX is available
        try:
            subprocess.run(["pdf2htmlEX", "--version"], check=True, capture_output=True)
        except (FileNotFoundError, subprocess.CalledProcessError) as e:
             raise RuntimeError(f"pdf2htmlEX command not found or failed. Please ensure it is installed and in your PATH. Error: {e}")

        command = [
            "pdf2htmlEX",
            "--zoom", "1.3", # Standard zoom factor
            #"--embed-css", "0", # External CSS might be easier for parsing later? Default is 1 (embed)
            #"--embed-font", "0", # External fonts? Default is 1 (embed)
            #"--embed-image", "0", # External images? Default is 1 (embed)
            #"--embed-javascript", "0", # External JS? Default is 1 (embed)
            # Consider options for better parsing: --decompose-ligature, --optimize-text
            "--process-outline", "0", # Don't create outline file
            str(self.pdf_path), # Input PDF
            str(html_path)      # Explicit output HTML file path
        ]
        
        print(f"Running command: {' '.join(command)}")

        try:
            # Run pdf2htmlEX. It outputs progress to stderr.
            # We capture stdout/stderr to prevent clutter unless there's an error.
            result = subprocess.run(command, check=True, capture_output=True, text=True, encoding='utf-8')
            print(f"pdf2htmlEX completed successfully.")
            # print(f"pdf2htmlEX stdout:\n{result.stdout}") # Usually empty
            # print(f"pdf2htmlEX stderr:\n{result.stderr}") # Contains progress info
        except subprocess.CalledProcessError as e:
            # Clean up potentially incomplete file on error
            if html_path.exists():
                html_path.unlink()
            # Provide detailed error message
            error_message = f"pdf2htmlEX failed with exit code {e.returncode}."
            if e.stderr:
                error_message += f"\nStderr:\n{e.stderr}"
            if e.stdout:
                 error_message += f"\nStdout:\n{e.stdout}"
            raise RuntimeError(error_message) from e
        except Exception as e:
             # Clean up potentially incomplete file on error
            if html_path.exists():
                html_path.unlink()
            raise RuntimeError(f"An unexpected error occurred running pdf2htmlEX: {e}") from e


    def run(self, force_text: bool = False, force_html: bool = False) -> Tuple[Path, Path]:
        """
        Ensure text and HTML versions of the PDF exist in the cache, generating if needed.

        Args:
            force_text: If True, always regenerate the text file even if cached.
            force_html: If True, always regenerate the HTML file even if cached.

        Returns:
            A tuple containing the Path to the cached text file and the cached HTML file.
        """
        self._ensure_cache_dir()
        pdf_hash = self._get_pdf_hash()

        text_path = self.cache_dir / f"{pdf_hash}.txt"
        html_path = self.cache_dir / f"{pdf_hash}.html"

        # Generate text file if forced or not cached
        if force_text or not text_path.exists():
            if force_text and text_path.exists():
                print(f"Force regenerating text file for {self.pdf_path.name}")
            self._extract_text(text_path)
        else:
            print(f"Using cached text file: {text_path.name}")

        # Generate HTML file if forced or not cached
        if force_html or not html_path.exists():
            if force_html and html_path.exists():
                 print(f"Force regenerating HTML file for {self.pdf_path.name}")
            self._extract_html(html_path)
        else:
            print(f"Using cached HTML file: {html_path.name}")

        return text_path, html_path

# Example Usage (can be removed or placed under if __name__ == "__main__")
# if __name__ == "__main__":
#     pdf_file = Path("../notes/CareTend Data Dictionary OLTP DB.pdf") # Adjust path as needed
#     output_directory = Path("../notes/output") # Adjust path as needed
#     
#     if not pdf_file.exists():
#         print(f"Error: Example PDF not found at {pdf_file}")
#     else:
#         try:
#             prep = DocumentPrep(pdf_file, output_directory)
#             txt_path, html_path = prep.run(force_text=False, force_html=False) # Set force=True to test generation
#             print(f"\nText file path: {txt_path}")
#             print(f"HTML file path: {html_path}")
#         except FileNotFoundError as e:
#             print(f"Error: {e}")
#         except ValueError as e:
#             print(f"Error: {e}")
#         except RuntimeError as e:
#             print(f"Error during processing: {e}")