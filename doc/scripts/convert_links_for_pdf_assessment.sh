#!/bin/bash

# Same conversion as convert_links_for_pdf.sh, applied to the CMTAT equivalency
# assessment (doc/cmtat-assessment/README.md) instead of doc/README.md.
#
# It differs only in its default input, so it delegates rather than duplicating:
#   - input : doc/cmtat-assessment/README.md
# The output follows the input's directory, which the other script already does,
# so it needs no default here. Link rewriting, image handling and the base-URL
# derivation all stay there too; change behaviour there and every entry point
# follows.
#
# Note on the base URL: the assessment sits two directories below the repository
# root, so the delegate derives ".../doc/cmtat-assessment" for its "./" links and
# ".../doc" for its "../" ones. A link to a repository-root sibling would need
# "../../", which the delegate does not rewrite; the assessment has none today,
# and check_markdown_links.py reports one if that changes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT="$SCRIPT_DIR/convert_links_for_pdf.sh"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))"

if [ -z "$1" ]; then
    echo "Usage: $0 <github-release-link> [input-file] [output-file]"
    echo ""
    echo "Converts doc/cmtat-assessment/README.md. For doc/README.md use"
    echo "convert_links_for_pdf.sh, and for the root README convert_links_for_pdf_root.sh."
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/CMTA/private-CMTAT-aztec/blob/v0.4.0"
    exit 1
fi

if [ ! -x "$CONVERT" ]; then
    echo "Error: '$CONVERT' not found or not executable"
    exit 1
fi

exec "$CONVERT" "$1" "${2:-$REPO_ROOT/doc/cmtat-assessment/README.md}" "${3:-}"
