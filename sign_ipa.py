import requests
import subprocess
import os
import shutil

# --- Configuration ---
GITHUB_REPO_OWNER = "BDGHubNoKey"  # Your GitHub username
GITHUB_REPO_NAME = "Backdoor"  # Your repo name
P12_PATH = "./certificates/your_certificate.p12"  # Updated path to your .p12 certificate
P12_PASSWORD = "BDG"  # Hardcoded password for your .p12 certificate
MOBILEPROVISION_PATH = "./certificates/your_provision.mobileprovision"  # Updated path to your mobileprovision file
IPA_OUTPUT_DIR = "signed_ipas"  # Directory to store signed IPAs
TEMP_DIR = "temp_files"  # Temporary work directory

# --- Helper Functions ---

def download_latest_release(owner, repo, download_dir):
    """Downloads the latest release from a GitHub repository."""
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    response = requests.get(url)
    response.raise_for_status()
    release_data = response.json()
    
    assets = release_data.get('assets', [])
    if not assets:
        raise ValueError("No assets found in the latest release.")
    
    asset = assets[0]  # Assuming the first asset is the IPA file
    download_url = asset['browser_download_url']
    ipa_name = asset['name']
    
    ipa_path = os.path.join(download_dir, ipa_name)
    with requests.get(download_url, stream=True) as r:
        r.raise_for_status()
        with open(ipa_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    
    return ipa_path

def sign_ipa(ipa_path, p12_path, p12_password, mobileprovision_path, output_dir):
    """Signs an IPA file using DaiSign-API and returns the install link."""
    os.makedirs(output_dir, exist_ok=True)
    ipa_filename = os.path.basename(ipa_path)
    output_ipa_path = os.path.join(output_dir, f"signed_{ipa_filename}")

    command = [
        "DaiSign-API",
        "-i", ipa_path,
        "-o", output_ipa_path,
        "-c", p12_path,
        "-p", p12_password,
        "-m", mobileprovision_path,
    ]

    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        install_link = result.stdout.strip()  # Gets the output from the command
        return install_link
    except subprocess.CalledProcessError as e:
        print(f"Error signing IPA: {e}")
        return None

def cleanup(temp_dir):
    """Cleans up temporary files."""
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)

# --- Main Workflow ---

def main():
    try:
        os.makedirs(TEMP_DIR, exist_ok=True)
        ipa_path = download_latest_release(GITHUB_REPO_OWNER, GITHUB_REPO_NAME, TEMP_DIR)
        print(f"Downloaded latest release: {ipa_path}")

        install_link = sign_ipa(ipa_path, P12_PATH, P12_PASSWORD, MOBILEPROVISION_PATH, IPA_OUTPUT_DIR)
        if install_link:
            print(f"Installation Link: {install_link}")
            print("Open this link on your iOS device's Safari browser to install the app.")

    except requests.exceptions.RequestException as e:
        print(f"Error during API request: {e}")
    except ValueError as e:
        print(f"Error: {e}")
    except FileNotFoundError as e:
        print(f"File not found: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        cleanup(TEMP_DIR)

if __name__ == "__main__":
    main()