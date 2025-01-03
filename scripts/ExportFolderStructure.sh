#!/usr/bin/env sh

# Function to display the help page
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message and exit"
    echo "  -a, --all           Include all directories (do not exclude .git and node_modules)"
    echo ""
    echo "This script generates a folder structure for a given directory."
    echo "You can choose to display the structure in the terminal, save it to a file,"
    echo "or do both. By default, .git and node_modules directories are excluded."
    echo ""
    echo "Examples:"
    echo "  $0                 Start the script with default exclusions"
    echo "  $0 --all           Include all directories in the output"
    echo "  $0 -h              Display this help message"
    exit 0
}

# Function to generate folder structure
generate_folder_structure() {
    local target_dir="$1"
    local output_file="$2"
    local exclude_filters="$3"

    if [[ "$output_file" != "" ]]; then
        find "$target_dir" -type d $exclude_filters > "$output_file"
        echo "Folder structure saved to: $output_file"
    fi

    if [[ "$output_file" == "" || "$show_terminal" == "yes" ]]; then
        find "$target_dir" -type d $exclude_filters
    fi
}

# Default exclusion filters
exclude_filters='! -path "*/.git*" ! -path "*/node_modules*"'

# Check for --help or -h option
for arg in "$@"; do
    case $arg in
        -h|--help)
            show_help
            ;;
        -a|--all)
            exclude_filters=""
            ;;
    esac
done

# User input
echo "Choose an option for exporting folder structure:"
echo "1) Display in terminal only"
echo "2) Save as a .txt file"
echo "3) Both (terminal and .txt file)"
read -p "Enter your choice (1, 2, or 3): " choice

# Select target directory
read -p "Enter the target directory: " target_dir
if [[ ! -d "$target_dir" ]]; then
    echo "Invalid directory: $target_dir"
    exit 1
fi

# Process user choice
case $choice in
    1)
        # Display in terminal only
        show_terminal="yes"
        output_file=""
        ;;
    2)
        # Save to file only
        read -p "Enter the output file path (default: folder_structure.txt in target directory): " output_file
        output_file=${output_file:-"$target_dir/folder_structure.txt"}
        show_terminal="no"
        ;;
    3)
        # Both display and save
        read -p "Enter the output file path (default: folder_structure.txt in target directory): " output_file
        output_file=${output_file:-"$target_dir/folder_structure.txt"}
        show_terminal="yes"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Generate folder structure
generate_folder_structure "$target_dir" "$output_file" "$exclude_filters"
