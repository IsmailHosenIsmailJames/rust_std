import os

def get_all_files_with_extension(directory):
    file_list = []
    for root, _, files in os.walk(directory):
        for file_name in files:
            full_path = os.path.join(root, file_name)
            file_list.append(full_path)
    return file_list

# Replace 'your_directory_path' with the path of the folder you want to scan
directory_path = "assets"

all_files = get_all_files_with_extension(directory_path)

print("List of files with full paths and extensions:")
for file in all_files:
    print(file)

with open("all_files.txt", "w") as file:
    for text in all_files:
        file.write('"'+text + '",'+ "\n")