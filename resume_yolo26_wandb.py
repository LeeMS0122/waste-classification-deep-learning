import wandb
from ultralytics import YOLO

RUN_ID = "m2vv3xw3"
LAST_PT = "/home/minsu/disk_a/miniconda3/graduation_work/runs/v26s_b128_e50/weights/last.pt"

wandb.init(
    entity="minsujang22-seokyeong-university",
    project="waste-details",
    id=RUN_ID,
    resume="must",
    name="v26s_b128_e50",
)

model = YOLO(LAST_PT)

results = model.train(
    resume=True,
    device=0,
)

wandb.finish()