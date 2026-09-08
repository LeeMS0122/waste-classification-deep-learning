import os
import wandb
from ultralytics import YOLO

RUN_ID = os.environ["WANDB_RUN_ID"]
WANDB_ENTITY = os.environ["WANDB_ENTITY"]
LAST_PT = os.environ["WASTE_LAST_PT"]

wandb.init(
    entity=WANDB_ENTITY,
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