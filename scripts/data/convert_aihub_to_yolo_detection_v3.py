import os
import json
import csv
import shutil
from collections import Counter

# =========================
# 경로 설정
# =========================
DATA_ROOT = os.environ["WASTE_DATA_ROOT"]
OUTPUT_ROOT = os.getenv("WASTE_YOLO_OUTPUT_ROOT", "outputs/trash_dataset_yolo_detection_v3")
CLEAR_OUTPUT_ROOT = True

SPLIT_MAP = {
    "1.Training": "train",
    "2.Validation": "val",
}

JSON_EXTS = (".Json", ".json")
IMG_EXTS = (".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")

# YOLO class id 순서
TARGET_CLASSES = [
    "플라스틱류",
    "종이류",
    "음료수곽",
    "유리병류",
    "캔류",
    "비닐류",
    "스티로폼류",
]

TARGET_CLASS_TO_ID = {name: idx for idx, name in enumerate(TARGET_CLASSES)}

SOURCE_FOLDER_CLASS_ALIASES = {
    "유리병": "유리병류",
    "비닐": "비닐류",
    "스티로폼": "스티로폼류",
}


# =========================
# 유틸
# =========================
def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def parse_resolution(resolution_str: str):
    try:
        w, h = resolution_str.strip().split("*")
        return int(w), int(h)
    except Exception:
        return None, None


def find_matching_image(image_root: str, rel_dir: str, base_name: str):
    for ext in IMG_EXTS:
        img_path = os.path.join(image_root, rel_dir, base_name + ext)
        if os.path.exists(img_path):
            return img_path
    return None


def polygon_to_bbox(polygon_points):
    xs = []
    ys = []

    for point_dict in polygon_points:
        if not isinstance(point_dict, dict):
            continue
        for _, value in point_dict.items():
            try:
                x_str, y_str = str(value).split(",")
                x = float(x_str.strip())
                y = float(y_str.strip())
                xs.append(x)
                ys.append(y)
            except Exception:
                continue

    if not xs or not ys:
        return None

    return min(xs), min(ys), max(xs), max(ys)


def box_to_bbox(obj):
    try:
        x1 = float(str(obj.get("x1", "")).strip())
        y1 = float(str(obj.get("y1", "")).strip())
        x2 = float(str(obj.get("x2", "")).strip())
        y2 = float(str(obj.get("y2", "")).strip())

        x_min = min(x1, x2)
        y_min = min(y1, y2)
        x_max = max(x1, x2)
        y_max = max(y1, y2)

        return x_min, y_min, x_max, y_max
    except Exception:
        return None


def get_bbox_from_object(obj):
    """
    우선순위:
    1) Drawing == BOX 이고 x1,y1,x2,y2 존재 -> BOX 사용
    2) PolygonPoint 존재 -> POLYGON bbox 사용
    3) Drawing 값과 무관하게 x1,y1,x2,y2 있으면 BOX 사용
    """
    drawing = str(obj.get("Drawing", "")).strip().upper()

    if drawing == "BOX":
        bbox = box_to_bbox(obj)
        if bbox is not None:
            return bbox, "BOX"

    polygon_points = obj.get("PolygonPoint", [])
    if polygon_points:
        bbox = polygon_to_bbox(polygon_points)
        if bbox is not None:
            return bbox, "POLYGON"

    bbox = box_to_bbox(obj)
    if bbox is not None:
        return bbox, "BOX_FALLBACK"

    return None, "NONE"


def bbox_to_yolo(x_min, y_min, x_max, y_max, img_w, img_h):
    x_center = ((x_min + x_max) / 2.0) / img_w
    y_center = ((y_min + y_max) / 2.0) / img_h
    width = (x_max - x_min) / img_w
    height = (y_max - y_min) / img_h

    x_center = min(max(x_center, 0.0), 1.0)
    y_center = min(max(y_center, 0.0), 1.0)
    width = min(max(width, 0.0), 1.0)
    height = min(max(height, 0.0), 1.0)

    return x_center, y_center, width, height


def safe_output_stem(split_name: str, rel_dir: str, base_name: str):
    rel_dir_safe = rel_dir.replace(os.sep, "__").replace(" ", "_")
    return f"{split_name}__{rel_dir_safe}__{base_name}"


def get_source_folder_class(rel_dir: str):
    if not rel_dir:
        return ""
    source_folder_class = rel_dir.split(os.sep)[0].strip()
    return SOURCE_FOLDER_CLASS_ALIASES.get(source_folder_class, source_folder_class)


def get_target_class(obj, rel_dir: str):
    source_folder_class = get_source_folder_class(rel_dir)
    cls = str(obj.get("CLASS", "")).strip()
    details = str(obj.get("DETAILS", "")).strip()

    if source_folder_class not in TARGET_CLASS_TO_ID:
        return None
    if source_folder_class != cls:
        return None

    if source_folder_class == "종이류" and details == "음료수곽":
        return "음료수곽"
    if source_folder_class == "종이류":
        return "종이류"
    if source_folder_class in TARGET_CLASS_TO_ID:
        return source_folder_class
    return None


# =========================
# 1차 스캔: 대상 JSON 수집 및 클래스 집계
# =========================
json_files = []
source_counter = Counter()
target_counter = Counter()

for src_split in SPLIT_MAP.keys():
    label_root = os.path.join(DATA_ROOT, src_split, "라벨링데이터")
    image_root = os.path.join(DATA_ROOT, src_split, "원천데이터")

    for root, _, files in os.walk(label_root):
        for file in files:
            if not file.endswith(JSON_EXTS):
                continue

            json_path = os.path.join(root, file)
            rel_path = os.path.relpath(json_path, label_root)
            rel_dir = os.path.dirname(rel_path)
            base_name = os.path.splitext(os.path.basename(json_path))[0]

            json_files.append((src_split, image_root, json_path, rel_dir, base_name))

            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                for obj in data.get("Bounding", []):
                    cls = str(obj.get("CLASS", "")).strip()
                    details = str(obj.get("DETAILS", "")).strip()
                    target_class = get_target_class(obj, rel_dir)

                    if target_class is None:
                        continue

                    source_counter[(cls, details, target_class)] += 1
                    target_counter[target_class] += 1
            except Exception:
                continue

print("=" * 70)
print("사용할 YOLO 클래스")
print("=" * 70)
for idx, name in enumerate(TARGET_CLASSES):
    print(f"{idx}: {name} ({target_counter[name]} objects)")

# =========================
# 출력 폴더 생성
# =========================
if CLEAR_OUTPUT_ROOT and os.path.isdir(OUTPUT_ROOT):
    if os.path.basename(OUTPUT_ROOT) != "trash_dataset_yolo_detection_v3":
        raise RuntimeError(f"Unexpected OUTPUT_ROOT for deletion: {OUTPUT_ROOT}")
    shutil.rmtree(OUTPUT_ROOT)

for split in ["train", "val"]:
    ensure_dir(os.path.join(OUTPUT_ROOT, "images", split))
    ensure_dir(os.path.join(OUTPUT_ROOT, "labels", split))

# =========================
# 2차 스캔: 변환
# =========================
stats = Counter()
missing_images = []
error_files = []
failed_bbox_logs = []

for src_split, image_root, json_path, rel_dir, base_name in json_files:
    yolo_split = SPLIT_MAP[src_split]

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        img_w, img_h = parse_resolution(str(data.get("RESOLUTION", "")))
        if not img_w or not img_h:
            stats["no_resolution"] += 1
            continue

        image_path = find_matching_image(image_root, rel_dir, base_name)
        if image_path is None:
            missing_images.append(json_path)
            stats["missing_image"] += 1
            continue

        yolo_lines = []
        bounding_list = data.get("Bounding", [])

        for idx, obj in enumerate(bounding_list):
            cls = str(obj.get("CLASS", "")).strip()
            details = str(obj.get("DETAILS", "")).strip()
            drawing = str(obj.get("Drawing", "")).strip()
            target_class = get_target_class(obj, rel_dir)

            if target_class is None:
                stats["unselected_object"] += 1
                continue

            bbox, bbox_source = get_bbox_from_object(obj)
            if bbox is None:
                stats["bbox_failed"] += 1
                failed_bbox_logs.append([
                    json_path,
                    idx,
                    cls,
                    details,
                    target_class,
                    drawing,
                    str(obj)[:500],
                ])
                continue

            x_min, y_min, x_max, y_max = bbox

            if x_max <= x_min or y_max <= y_min:
                stats["invalid_bbox"] += 1
                failed_bbox_logs.append([
                    json_path,
                    idx,
                    cls,
                    details,
                    target_class,
                    drawing,
                    f"INVALID_BBOX: {(x_min, y_min, x_max, y_max)}",
                ])
                continue

            x_center, y_center, width, height = bbox_to_yolo(
                x_min, y_min, x_max, y_max, img_w, img_h
            )

            if width <= 0 or height <= 0:
                stats["zero_sized_bbox"] += 1
                failed_bbox_logs.append([
                    json_path,
                    idx,
                    cls,
                    details,
                    target_class,
                    drawing,
                    f"ZERO_SIZE: {(x_min, y_min, x_max, y_max)}",
                ])
                continue

            class_id = TARGET_CLASS_TO_ID[target_class]
            yolo_lines.append(
                f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}"
            )

            stats[f"bbox_source_{bbox_source}"] += 1
            stats["total_objects"] += 1
            stats[f"class_{target_class}"] += 1

        if not yolo_lines:
            stats["empty_label_files"] += 1
            continue

        output_stem = safe_output_stem(yolo_split, rel_dir, base_name)
        img_ext = os.path.splitext(image_path)[1].lower()

        out_img_path = os.path.join(OUTPUT_ROOT, "images", yolo_split, output_stem + img_ext)
        out_lbl_path = os.path.join(OUTPUT_ROOT, "labels", yolo_split, output_stem + ".txt")

        shutil.copy2(image_path, out_img_path)

        with open(out_lbl_path, "w", encoding="utf-8") as f:
            f.write("\n".join(yolo_lines) + "\n")

        stats[f"{yolo_split}_images"] += 1
        stats[f"{yolo_split}_labels"] += 1

    except Exception as e:
        error_files.append((json_path, str(e)))
        stats["json_error"] += 1

# =========================
# 메타 파일 저장
# =========================
classes_txt_path = os.path.join(OUTPUT_ROOT, "classes.txt")
with open(classes_txt_path, "w", encoding="utf-8") as f:
    for class_name in TARGET_CLASSES:
        f.write(class_name + "\n")

mapping_csv_path = os.path.join(OUTPUT_ROOT, "class_mapping.csv")
with open(mapping_csv_path, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["class_id", "target_class", "source_class", "source_details", "count"])
    for source_key, count in sorted(source_counter.items(), key=lambda item: (TARGET_CLASS_TO_ID[item[0][2]], item[0][0], item[0][1])):
        source_class, source_details, target_class = source_key
        writer.writerow([
            TARGET_CLASS_TO_ID[target_class],
            target_class,
            source_class,
            source_details,
            count,
        ])

yaml_path = os.path.join(OUTPUT_ROOT, "data.yaml")
with open(yaml_path, "w", encoding="utf-8") as f:
    f.write(f"path: {OUTPUT_ROOT}\n")
    f.write("train: images/train\n")
    f.write("val: images/val\n")
    f.write(f"nc: {len(TARGET_CLASSES)}\n")
    f.write("names:\n")
    for idx, class_name in enumerate(TARGET_CLASSES):
        f.write(f"  {idx}: {class_name}\n")

failed_bbox_csv = os.path.join(OUTPUT_ROOT, "failed_bbox_logs.csv")
with open(failed_bbox_csv, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow([
        "json_path",
        "object_index",
        "source_class",
        "source_details",
        "target_class",
        "drawing",
        "snippet",
    ])
    writer.writerows(failed_bbox_logs)

error_csv = os.path.join(OUTPUT_ROOT, "json_errors.csv")
with open(error_csv, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["json_path", "error"])
    writer.writerows(error_files)

# =========================
# 요약 출력
# =========================
print("\n" + "=" * 70)
print("변환 완료")
print("=" * 70)
print(f"train 이미지 수: {stats['train_images']}")
print(f"val 이미지 수: {stats['val_images']}")
print(f"총 객체 수: {stats['total_objects']}")
print(f"empty label 파일 수: {stats['empty_label_files']}")
print(f"선택하지 않은 객체 수: {stats['unselected_object']}")
print(f"이미지 매칭 실패 수: {len(missing_images)}")
print(f"RESOLUTION 없음/파싱 실패 수: {stats['no_resolution']}")
print(f"bbox 생성 실패 수: {stats['bbox_failed']}")
print(f"invalid bbox 수: {stats['invalid_bbox']}")
print(f"zero sized bbox 수: {stats['zero_sized_bbox']}")
print(f"변환 에러 수: {len(error_files)}")
print(f"사용 클래스 수: {len(TARGET_CLASSES)}")
print("-" * 70)
print("클래스별 변환 객체 수")
print("-" * 70)
for idx, class_name in enumerate(TARGET_CLASSES):
    print(f"{idx} {class_name}: {stats[f'class_{class_name}']}개")
print("-" * 70)
print(f"BOX 사용 수: {stats['bbox_source_BOX']}")
print(f"POLYGON 사용 수: {stats['bbox_source_POLYGON']}")
print(f"BOX_FALLBACK 사용 수: {stats['bbox_source_BOX_FALLBACK']}")
print("-" * 70)
print(f"출력 폴더: {OUTPUT_ROOT}")
print(f"data.yaml: {yaml_path}")
print(f"classes.txt: {classes_txt_path}")
print(f"class_mapping.csv: {mapping_csv_path}")
print(f"failed_bbox_logs.csv: {failed_bbox_csv}")
print(f"json_errors.csv: {error_csv}")