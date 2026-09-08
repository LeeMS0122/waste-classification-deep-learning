import os
import random
from PIL import Image, ImageDraw, ImageFont

DATA_ROOT = "/home/minsu/disk_c/trash_dataset_yolo_details_v2"
OUT_DIR = os.path.join(DATA_ROOT, "sample_checks")
os.makedirs(OUT_DIR, exist_ok=True)

IMG_EXTS = (".jpg", ".jpeg", ".png")

def load_classes(path):
    with open(path, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]

def yolo_to_xyxy(line, w, h):
    parts = line.strip().split()
    if len(parts) != 5:
        return None
    cls_id = int(float(parts[0]))
    xc, yc, bw, bh = map(float, parts[1:])
    x1 = (xc - bw / 2) * w
    y1 = (yc - bh / 2) * h
    x2 = (xc + bw / 2) * w
    y2 = (yc + bh / 2) * h
    return cls_id, x1, y1, x2, y2

classes = load_classes(os.path.join(DATA_ROOT, "classes.txt"))

pairs = []
for split in ["train", "val"]:
    img_dir = os.path.join(DATA_ROOT, "images", split)
    lbl_dir = os.path.join(DATA_ROOT, "labels", split)

    for fname in os.listdir(img_dir):
        stem, ext = os.path.splitext(fname)
        if ext.lower() not in IMG_EXTS:
            continue
        img_path = os.path.join(img_dir, fname)
        lbl_path = os.path.join(lbl_dir, stem + ".txt")
        if os.path.exists(lbl_path):
            pairs.append((split, img_path, lbl_path))

print(f"총 매칭 pair 수: {len(pairs)}")

random.seed(42)
samples = random.sample(pairs, min(6, len(pairs)))

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20)
except:
    font = ImageFont.load_default()

for i, (split, img_path, lbl_path) in enumerate(samples, start=1):
    img = Image.open(img_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    w, h = img.size

    with open(lbl_path, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f if ln.strip()]

    for ln in lines:
        item = yolo_to_xyxy(ln, w, h)
        if item is None:
            continue
        cls_id, x1, y1, x2, y2 = item
        label = classes[cls_id] if 0 <= cls_id < len(classes) else f"id:{cls_id}"

        draw.rectangle([x1, y1, x2, y2], outline="red", width=3)

        text = label
        try:
            bbox = draw.textbbox((x1, y1), text, font=font)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
        except:
            tw, th = draw.textsize(text, font=font)

        tx1 = x1
        ty1 = max(0, y1 - th - 6)
        tx2 = x1 + tw + 8
        ty2 = ty1 + th + 4

        draw.rectangle([tx1, ty1, tx2, ty2], fill="red")
        draw.text((tx1 + 4, ty1 + 2), text, fill="white", font=font)

    out_path = os.path.join(OUT_DIR, f"sample_{i}_{split}.jpg")
    img.save(out_path, quality=95)
    print(f"저장 완료: {out_path}")