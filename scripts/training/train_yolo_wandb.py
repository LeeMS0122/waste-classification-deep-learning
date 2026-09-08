import os
import wandb
from ultralytics import YOLO

DATA_YAML = os.environ["WASTE_DATA_YAML"]
MODEL_NAME = "yolo26s.pt"

run = wandb.init(
    project="waste-details",
    name="v26s_b128_e50",
    config={
        "model": MODEL_NAME,
        "data": DATA_YAML,
        "epochs": 50,
        "patience": 20,
        "imgsz": 640,
        "batch": 128,
        "device": 1,
        "workers": 16,
        "max_det": 50, #이미지 한 장에서 YOLO가 최종적으로 남길 수 있는 박스 개수의 최대값
    }
)

model = YOLO(MODEL_NAME)

results = model.train(
    data=DATA_YAML,
    epochs=50,
    patience=20,
    imgsz=640,
    batch=128,
    device=1,
    workers=16,
    max_det=50,
    project=os.getenv("WASTE_RUNS_DIR", "runs"),
    name="v26s_b128_e50",
    plots=True,
    save=True,
)

wandb.finish()
