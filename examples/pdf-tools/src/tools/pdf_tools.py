import base64
import io

from PyPDF2 import PdfReader


def _decode_pdf(pdf_base64: str) -> PdfReader:
    """Decode a base64-encoded PDF string and return a PdfReader instance."""
    raw = base64.b64decode(pdf_base64)
    return PdfReader(io.BytesIO(raw))


def register(mcp):
    """Register all PDF tools with the MCP server."""

    @mcp.tool()
    def extract_text_from_pdf(pdf_base64: str) -> dict:
        """Extract all text from a base64-encoded PDF.

        Args:
            pdf_base64: The PDF file contents encoded as a base64 string.

        Returns:
            A dict with keys 'text', 'page_count', and 'character_count'.
        """
        try:
            reader = _decode_pdf(pdf_base64)
            pages_text = []
            for page in reader.pages:
                pages_text.append(page.extract_text() or "")
            full_text = "\n".join(pages_text)
            return {
                "text": full_text,
                "page_count": len(reader.pages),
                "character_count": len(full_text),
            }
        except Exception as e:
            return {"error": f"Failed to extract text from PDF: {str(e)}"}

    @mcp.tool()
    def get_pdf_metadata(pdf_base64: str) -> dict:
        """Extract metadata from a base64-encoded PDF.

        Args:
            pdf_base64: The PDF file contents encoded as a base64 string.

        Returns:
            A dict containing title, author, subject, creator, producer,
            creation_date, modification_date, and page_count.
        """
        try:
            reader = _decode_pdf(pdf_base64)
            meta = reader.metadata

            def _safe(val):
                return str(val) if val else None

            return {
                "title": _safe(meta.title) if meta else None,
                "author": _safe(meta.author) if meta else None,
                "subject": _safe(meta.subject) if meta else None,
                "creator": _safe(meta.creator) if meta else None,
                "producer": _safe(meta.producer) if meta else None,
                "creation_date": _safe(meta.creation_date) if meta else None,
                "modification_date": _safe(meta.modification_date) if meta else None,
                "page_count": len(reader.pages),
            }
        except Exception as e:
            return {"error": f"Failed to extract PDF metadata: {str(e)}"}

    @mcp.tool()
    def count_pdf_pages(pdf_base64: str) -> int:
        """Return the number of pages in a base64-encoded PDF.

        Args:
            pdf_base64: The PDF file contents encoded as a base64 string.

        Returns:
            The number of pages, or -1 on error.
        """
        try:
            reader = _decode_pdf(pdf_base64)
            return len(reader.pages)
        except Exception as e:
            return -1

    @mcp.tool()
    def extract_text_from_page(pdf_base64: str, page_number: int) -> dict:
        """Extract text from a specific page of a base64-encoded PDF.

        Args:
            pdf_base64: The PDF file contents encoded as a base64 string.
            page_number: Zero-indexed page number to extract text from.

        Returns:
            A dict with keys 'page_number', 'text', and 'character_count'.
        """
        try:
            reader = _decode_pdf(pdf_base64)
            total_pages = len(reader.pages)

            if page_number < 0 or page_number >= total_pages:
                return {
                    "error": (
                        f"Invalid page number {page_number}. "
                        f"PDF has {total_pages} pages (0-indexed: 0 to {total_pages - 1})."
                    )
                }

            text = reader.pages[page_number].extract_text() or ""
            return {
                "page_number": page_number,
                "text": text,
                "character_count": len(text),
            }
        except Exception as e:
            return {"error": f"Failed to extract text from page: {str(e)}"}

    @mcp.tool()
    def merge_pdfs_info(pdf_count: int) -> dict:
        """Provide guidance on merging multiple PDFs.

        Since actual PDF merging requires file I/O that may not be available
        in all deployment environments, this tool returns step-by-step
        instructions for merging PDFs using PyPDF2.

        Args:
            pdf_count: The number of PDFs you intend to merge.

        Returns:
            A dict with merging instructions and a sample code snippet.
        """
        if pdf_count < 2:
            return {"error": "You need at least 2 PDFs to merge."}

        return {
            "description": f"Instructions for merging {pdf_count} PDFs using PyPDF2.",
            "steps": [
                "1. Decode each base64-encoded PDF into a bytes buffer.",
                "2. Create a PdfReader for each buffer.",
                "3. Create a PdfWriter instance.",
                "4. Iterate over each reader and add all pages to the writer.",
                "5. Write the merged output to a new bytes buffer.",
                "6. Base64-encode the result for transport.",
            ],
            "sample_code": (
                "from PyPDF2 import PdfReader, PdfWriter\n"
                "import base64, io\n\n"
                "writer = PdfWriter()\n"
                "for pdf_b64 in pdf_base64_list:\n"
                "    reader = PdfReader(io.BytesIO(base64.b64decode(pdf_b64)))\n"
                "    for page in reader.pages:\n"
                "        writer.add_page(page)\n\n"
                "output = io.BytesIO()\n"
                "writer.write(output)\n"
                "merged_b64 = base64.b64encode(output.getvalue()).decode()\n"
            ),
            "pdf_count": pdf_count,
        }
