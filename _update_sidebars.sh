#!/bin/bash

# This script updates the sidebar navigation in all relevant HTML files.
# It can be run in two ways:
# 1. With a filename argument to update a single file: ./update_sidebars.sh path/to/file.html
# 2. Without arguments to update all HTML files in the project.

TEMPLATE_ROOT="_templates/sidebar_root.html"
TEMPLATE_SUB="_templates/sidebar_sub.html"

# Define a function to process a single file
process_file() {
    local file="$1"

    # --- SAFETY CHECK ---
    # Check if both markers exist before proceeding.
    if ! grep -q "<!-- SIDEBAR-START -->" "$file" || ! grep -q "<!-- SIDEBAR-END -->" "$file"; then
        echo "Skipping $file: Markers not found."
        return
    fi
    # --- END SAFETY CHECK ---

    echo "Processing $file..."

    # Determine which template to use based on directory path
    local dir_name
    dir_name=$(dirname "$file")
    
    local template_file
    local active_filename

    if [[ "$dir_name" == "." ]]; then
        template_file="$TEMPLATE_ROOT"
        active_filename=$(basename "$file")
    else
        template_file="$TEMPLATE_SUB"
        # For sub-page files, the href in the template is e.g., ../fbms/genus_zero.html
        # We construct this path from the file variable.
        active_filename="../${file#./}" # <-- THIS IS THE CORRECTED LINE
    fi

    # Read the content of the correct template
    local sidebar_content
    sidebar_content=$(cat "$template_file")
    
    # Inject 'class="active"' into the correct link
    local placeholder="<a href=\"$active_filename\""
    local replacement="<a href=\"$active_filename\" class=\"active\""
    
    local active_sidebar_content
    active_sidebar_content=$(echo "$sidebar_content" | sed "s|$placeholder|$replacement|")

    # Prepare the final content for injection
    local final_content
    final_content="<!-- SIDEBAR-START -->\n<div class=\"sidebar\">\n${active_sidebar_content}\n</div>\n<!-- SIDEBAR-END -->"

    # Use awk for a safe, multiline replacement between the markers
    awk -v replacement="$final_content" '
        BEGIN {p=1}
        /<!-- SIDEBAR-START -->/ {
            print replacement;
            p=0;
            next;
        }
        /<!-- SIDEBAR-END -->/ {
            p=1;
            next;
        }
        p {print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}


# --- Main script execution ---

if [ -n "$1" ]; then
    # If an argument is provided, process only that file
    if [ -f "$1" ]; then
        process_file "$1"
        echo -e "\nSingle file updated."
    else
        echo "Error: File '$1' not found."
        exit 1
    fi
else
    # If no arguments, find and process all relevant HTML files
    find . -type f -name "*.html" ! -path "./_templates/*" -print0 | while IFS= read -r -d $'\0' file; do
        process_file "$file"
    done
    echo -e "\nAll sidebars updated successfully."
fi