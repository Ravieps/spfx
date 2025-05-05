import os
import requests
from requests_ntlm import HttpNtlmAuth

# SharePoint 2016 config
sharepoint_site = "http://your-sharepoint-site"
document_library = "Shared Documents"
username = "DOMAIN\\your_username"
password = "your_password"
local_folder_path = "C:/path/to/excel/files"

# List of keywords to check in file and folder names (case-insensitive)
keywords = ["data lineage", "metrics", "inventory", "summary"]

# Setup NTLM authentication
auth = HttpNtlmAuth(username, password)

# Fetch all folder names from the SharePoint document library
folders_api_url = f"{sharepoint_site}/_api/web/GetFolderByServerRelativeUrl('{document_library}')/Folders"
headers = {"Accept": "application/json;odata=verbose"}

response = requests.get(folders_api_url, auth=auth, headers=headers)

if response.status_code != 200:
    print("Failed to fetch folders:", response.text)
    exit()

folder_data = response.json()
sharepoint_folders = [f["Name"] for f in folder_data["d"]["results"] if not f["Name"].startswith("Forms")]

# Track files that could not be uploaded
not_uploaded_files = []

# Process each file in the local folder
for file_name in os.listdir(local_folder_path):
    if not file_name.lower().endswith((".xlsx", ".xls")):
        continue

    matched = False
    for keyword in keywords:
        if keyword.lower() in file_name.lower():
            # Find a folder that contains this keyword
            target_folders = [f for f in sharepoint_folders if keyword.lower() in f.lower()]
            if target_folders:
                file_path = os.path.join(local_folder_path, file_name)
                with open(file_path, 'rb') as file_data:
                    upload_url = f"{sharepoint_site}/_api/web/GetFolderByServerRelativeUrl('{document_library}/{target_folders[0]}')/Files/add(url='{file_name}',overwrite=true)"
                    upload_response = requests.post(upload_url, data=file_data, auth=auth, headers={
                        "Accept": "application/json;odata=verbose",
                        "Content-Type": "application/octet-stream"
                    })

                    if upload_response.status_code == 200:
                        print(f"Uploaded: {file_name} to folder: {target_folders[0]}")
                        matched = True
                        break
                    else:
                        print(f"Failed to upload {file_name} to folder {target_folders[0]}: {upload_response.text}")
                        matched = True
                        break
            else:
                # Folder not found for keyword
                matched = True
                not_uploaded_files.append((file_name, keyword))
                break

    if not matched:
        not_uploaded_files.append((file_name, "No matching keyword"))

# Summary of files not uploaded
if not_uploaded_files:
    print("\nFiles NOT uploaded:")
    for fname, reason in not_uploaded_files:
        print(f"- {fname} (Reason: {reason})")
else:
    print("\nAll matching files uploaded successfully.")
