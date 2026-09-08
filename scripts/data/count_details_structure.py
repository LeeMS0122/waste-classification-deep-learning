import os
import json
import csv
from collections import Counter, defaultdict

DATA_ROOT = os.environ["WASTE_DATA_ROOT"]

splits = ["1.Training", "2.Validation"]
json_exts = (".Json", ".json")
img_exts = (".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")

details_counter = Counter()
class_counter = Counter()
split_counter = Counter()
class_details_counter = defaultdict(Counter)
folder_mismatch_counter = Counter()

json_file_count = 0
matched_image_count = 0
missing_image_files = []
error_files = []
folder_mismatch_objects = []

source_folder_class_aliases = {
    "나무": "나무류",
    "비닐": "비닐류",
    "스티로폼": "스티로폼류",
    "유리병": "유리병류",
    "페트병": "페트병류",
}


def get_source_folder_class(rel_dir):
    if not rel_dir:
        return ""
    source_folder_class = rel_dir.split(os.sep)[0].strip()
    return source_folder_class_aliases.get(source_folder_class, source_folder_class)

for split in splits:
    label_root = os.path.join(DATA_ROOT, split, "라벨링데이터")
    image_root = os.path.join(DATA_ROOT, split, "원천데이터")

    for root, dirs, files in os.walk(label_root):
        for file in files:
            if not file.endswith(json_exts):
                continue

            json_file_count += 1
            json_path = os.path.join(root, file)

            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                split_counter[split] += 1

                rel_path = os.path.relpath(json_path, label_root)
                rel_dir = os.path.dirname(rel_path)
                source_folder_class = get_source_folder_class(rel_dir)

                bounding_list = data.get("Bounding", [])
                for idx, obj in enumerate(bounding_list):
                    cls = obj.get("CLASS", "").strip()
                    details = obj.get("DETAILS", "").strip()

                    if source_folder_class != cls:
                        folder_mismatch_counter[(source_folder_class, cls, details)] += 1
                        folder_mismatch_objects.append([
                            json_path,
                            idx,
                            source_folder_class,
                            cls,
                            details,
                        ])
                        continue

                    if cls:
                        class_counter[cls] += 1
                    if details:
                        details_counter[details] += 1
                    if cls and details:
                        class_details_counter[cls][details] += 1

                json_name = os.path.splitext(os.path.basename(json_path))[0]

                found_img = False
                for ext in img_exts:
                    img_path = os.path.join(image_root, rel_dir, json_name + ext)
                    if os.path.exists(img_path):
                        matched_image_count += 1
                        found_img = True
                        break

                if not found_img:
                    missing_image_files.append(json_path)

            except Exception as e:
                error_files.append((json_path, str(e)))

with open("details_counts.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["DETAILS", "count"])
    for details, cnt in details_counter.most_common():
        writer.writerow([details, cnt])

with open("class_counts.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["CLASS", "count"])
    for cls, cnt in class_counter.most_common():
        writer.writerow([cls, cnt])

with open("class_details_counts.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["CLASS", "DETAILS", "count"])
    for cls in sorted(class_details_counter.keys()):
        for details, cnt in class_details_counter[cls].most_common():
            writer.writerow([cls, details, cnt])

with open("split_counts.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["split", "json_count"])
    for split, cnt in split_counter.items():
        writer.writerow([split, cnt])

with open("missing_images.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["json_path"])
    for path in missing_image_files:
        writer.writerow([path])

with open("folder_mismatch_objects.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["json_path", "object_index", "source_folder_class", "json_class", "json_details"])
    writer.writerows(folder_mismatch_objects)

with open("folder_mismatch_counts.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["source_folder_class", "json_class", "json_details", "count"])
    for (source_folder_class, cls, details), cnt in folder_mismatch_counter.most_common():
        writer.writerow([source_folder_class, cls, details, cnt])

print("완료")
print(f"전체 JSON 파일 수: {json_file_count}")
print(f"매칭된 이미지 수: {matched_image_count}")
print(f"이미지 매칭 실패 수: {len(missing_image_files)}")
print(f"에러 파일 수: {len(error_files)}")
print(f"폴더/CLASS 불일치 객체 수: {sum(folder_mismatch_counter.values())}")
print(f"CLASS 종류 수: {len(class_counter)}")
print(f"DETAILS 종류 수: {len(details_counter)}")
print("생성 파일:")
print("- details_counts.csv")
print("- class_counts.csv")
print("- class_details_counts.csv")
print("- split_counts.csv")
print("- missing_images.csv")
print("- folder_mismatch_objects.csv")
print("- folder_mismatch_counts.csv")