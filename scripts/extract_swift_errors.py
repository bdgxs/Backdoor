import sys
import re

def extract_swift_build_errors(log_file_path):
    """
    Extracts error and warning messages from a Swift build log.

    Args:
        log_file_path (str): The path to the Swift build log file.

    Returns:
        list: A list of error and warning messages.
    """
    try:
        with open(log_file_path, 'r', encoding='utf-8') as f:
            log_content = f.read()
    except FileNotFoundError:
        print(f"Error: Log file not found at {log_file_path}")
        return []
    except Exception as e:
        print(f"An error occurred while reading the log file: {e}")
        return []

    # Regular expression to capture error and warning lines.
    # This regex is designed to catch Xcode's standard error/warning output.
    error_pattern = re.compile(r'^(.*?)(error|warning):\s*(.*)$', re.MULTILINE | re.IGNORECASE)

    matches = error_pattern.findall(log_content)

    extracted_messages = []
    for filepath, level, message in matches:
        extracted_messages.append(f"{filepath.strip()}: {level.strip()}: {message.strip()}")

    return extracted_messages

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_swift_errors.py <log_file_path>")
        sys.exit(1)

    log_file_path = sys.argv[1]
    errors = extract_swift_build_errors(log_file_path)

    if errors:
        print("Swift Build Errors and Warnings:")
        for error in errors:
            print(error)
    else:
        print("No Swift build errors or warnings found.")