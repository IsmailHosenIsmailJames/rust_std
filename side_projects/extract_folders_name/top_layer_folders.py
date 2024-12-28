import os

def get_all_folders(directory):
    folder_list = []
    for root, dirs, _ in os.walk(directory):
        for dir_name in dirs:
            folder_list.append(os.path.join(root, dir_name))
    return folder_list

# Replace 'your_directory_path' with the path of the folder you want to scan
directory_path = "assets/std"

all_folders = get_all_folders(directory_path)

print("List of folders:")
for folder in all_folders:
    print(folder)
