"""Bulk-download a reviewed (Swiss-Prot) UniProt subset as a gzipped flat file.

Uses UniProt's /stream endpoint, which returns the entire query result set in
one streamed response (no cursor/pagination needed) - much better suited to
pulling thousands of records than the paginated /search endpoint.

Usage:
    python -m ingest.fetch_uniprot
    python -m ingest.fetch_uniprot --query "reviewed:true AND organism_id:9606"
"""
import argparse
from pathlib import Path

import requests

UNIPROT_STREAM_URL = "https://rest.uniprot.org/uniprotkb/stream"
DEFAULT_QUERY = "reviewed:true AND organism_id:9606"  # human, ~20k reviewed entries
DATA_DIR = Path(__file__).parent.parent / "data"
OUTPUT_PATH = DATA_DIR / "uniprot_subset.dat.gz"

# UniProt asks bulk API consumers to identify themselves.
HEADERS = {"User-Agent": "RAG-based-Protein-database/1.0 (personal project)"}


def fetch(query: str = DEFAULT_QUERY, output_path: Path = OUTPUT_PATH) -> Path:
    params = {"query": query, "format": "txt", "compressed": "true"}

    DATA_DIR.mkdir(exist_ok=True)
    print(f"Fetching UniProt entries for query: {query!r}")

    with requests.get(
        UNIPROT_STREAM_URL, params=params, headers=HEADERS, stream=True, timeout=120
    ) as response:
        response.raise_for_status()
        total_bytes = 0
        with open(output_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                f.write(chunk)
                total_bytes += len(chunk)
                print(f"\rDownloaded {total_bytes / 1024 / 1024:.1f} MB", end="", flush=True)

    print(f"\nSaved to {output_path}")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default=DEFAULT_QUERY, help="UniProt query string")
    parser.add_argument("--output", default=str(OUTPUT_PATH), help="Output .dat.gz path")
    args = parser.parse_args()
    fetch(query=args.query, output_path=Path(args.output))


if __name__ == "__main__":
    main()
