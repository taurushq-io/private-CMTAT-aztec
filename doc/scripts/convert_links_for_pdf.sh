#!/bin/bash

# Script to replace relative markdown links with GitHub links for PDF generation
# Preserves image links (they render in PDF) and external links

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <github-release-link> [input-file] [output-file]"
    echo ""
    echo "The release link may point at the repository root or at the input file's"
    echo "own directory; the missing part is derived from where the file sits."
    echo "The output defaults to README_UPDATE.md beside the input file, so the"
    echo "image links it keeps relative still resolve."
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/CMTA/CMTAT/blob/v3.0.0"
    echo "  $0 https://github.com/CMTA/CMTAT/blob/v3.0.0/doc"
    echo "  $0 https://github.com/CMTA/CMTAT/blob/v3.0.0 ../README.md README_UPDATE.md"
    exit 1
fi

GITHUB_LINK="${1%/}"  # Remove trailing slash if present

INPUT_FILE="${2:-../README.md}"   # doc/README.md, the full reference (the root README is a short summary)

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# The links in the input file are relative to the file, so the base URL has to be
# too. Accept either form -- the repository root (".../blob/<ref>") or the file's
# own directory (".../blob/<ref>/doc") -- and derive whichever half is missing
# from the file's path inside the repository. Passing the root form used to
# rewrite every "./" link one directory too high, silently: doc/README.md's
# "./technical/x.md" became ".../blob/<ref>/technical/x.md", a 404 in the PDF.
INPUT_DIR=$(cd "$(dirname "$INPUT_FILE")" && pwd)
REPO_ROOT=$(git -C "$INPUT_DIR" rev-parse --show-toplevel 2>/dev/null || true)
REL_DIR=""
if [ -n "$REPO_ROOT" ]; then
    REL_DIR="${INPUT_DIR#"$REPO_ROOT"}"
    REL_DIR="${REL_DIR#/}"        # "doc", or "" when the input file is at the root
fi

if [ -n "$REL_DIR" ] && [ "${GITHUB_LINK%/$REL_DIR}" = "$GITHUB_LINK" ]; then
    GITHUB_LINK="$GITHUB_LINK/$REL_DIR"
fi

# Base URL for the parent of the input file's directory, used by Step 0 to
# rewrite "../path" links -- how doc/README.md must reference repository-root
# siblings such as test/ and src/. Empty when the input file is itself at the
# root, where "../" points outside the repository and cannot be expressed.
GITHUB_LINK_PARENT=""
if [ -n "$REL_DIR" ]; then
    GITHUB_LINK_PARENT="${GITHUB_LINK%/*}"
fi

# Default the output to the input file's own directory, not the caller's working
# directory. The conversion leaves image links relative on purpose, so the
# converted file only renders correctly from where the original sits: written
# anywhere else, doc/README.md's "./schema/x.png" points at nothing.
OUTPUT_FILE="${3:-$INPUT_DIR/README_UPDATE.md}"

# Create a temporary file
TMP_FILE=$(mktemp)
cp "$INPUT_FILE" "$TMP_FILE"

# Use a placeholder to avoid sed escaping issues
PLACEHOLDER="__GITHUB_LINK__"
PLACEHOLDER_PARENT="__GITHUB_LINK_PARENT__"

# Step 0: convert parent-relative links [text](../...) before Step 1, which only
# recognizes the "./" form and would leave these relative and dead in the PDF.
if grep -qE '\]\(\.\./[^)]+\)' "$TMP_FILE"; then
    if [ -z "$GITHUB_LINK_PARENT" ]; then
        echo "Error: '$INPUT_FILE' contains '../' links, which point outside the repository from this location." >&2
        echo "Rewrite them as absolute URLs, or generate the PDF from a file in a subdirectory such as doc/." >&2
        rm -f "$TMP_FILE"
        exit 1
    fi
    sed -i -E "s|\[([^]]+)\]\(\.\./([^)]+)\)|[\1]($PLACEHOLDER_PARENT/\2)|g" "$TMP_FILE"
fi

# Step 1: Convert ALL relative links [text](./...) to placeholder
sed -i -E "s|\[([^]]+)\]\(\./([^)]+)\)|[\1]($PLACEHOLDER/\2)|g" "$TMP_FILE"

# Step 2: Restore image links back to relative (images render inline in PDF)
for ext in png jpg jpeg gif svg ico webp bmp tiff; do
    sed -i -E "s|\[([^]]+)\]\($PLACEHOLDER/([^)]+\.$ext)\)|[\1](./\2)|gi" "$TMP_FILE"
    sed -i -E "s|\[([^]]+)\]\($PLACEHOLDER_PARENT/([^)]+\.$ext)\)|[\1](../\2)|gi" "$TMP_FILE"
done

# Step 3: Replace placeholders with actual GitHub links (parent first)
sed -i "s|$PLACEHOLDER_PARENT|$GITHUB_LINK_PARENT|g" "$TMP_FILE"
sed -i "s|$PLACEHOLDER|$GITHUB_LINK|g" "$TMP_FILE"

mv "$TMP_FILE" "$OUTPUT_FILE"

echo "Created '$OUTPUT_FILE' with GitHub links pointing to:"
echo "  $GITHUB_LINK"
