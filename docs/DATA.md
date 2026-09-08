# 데이터 안내

## 출처

- 데이터셋: [AI Hub 생활 폐기물 이미지](https://aihub.or.kr/aihubdata/data/view.do?dataSetSn=140)
- 제공 기관: AI Hub
- 활용 목적: 생활폐기물 객체 탐지 모델 학습 및 모바일 분리배출 안내 서비스 구현

## 저장소 포함 범위

- 데이터 분석·YOLO 형식 변환 스크립트
- 클래스 및 분할 집계 결과
- 누락 이미지·폴더 불일치 점검 결과
- 학습된 모바일 추론용 TFLite 모델

## 저장소 제외 범위

- AI Hub 원본 이미지
- AI Hub 원본 라벨 파일
- 대용량 학습 중간 산출물

원본 데이터의 외부 공유·재배포 없이 AI Hub 이용정책에 따라 활용

## 스크립트 경로 설정

개인 장비의 절대경로 대신 아래 환경변수 사용

| 환경변수 | 용도 |
|---|---|
| `WASTE_DATA_ROOT` | AI Hub 원본 데이터 루트 |
| `WASTE_YOLO_OUTPUT_ROOT` | 변환된 YOLO 데이터 출력 경로 |
| `WASTE_DATA_YAML` | 학습용 `data.yaml` 경로 |
| `WASTE_RUNS_DIR` | 모델 학습 결과 저장 경로 |
| `WASTE_LAST_PT` | 재개할 체크포인트 경로 |
| `WANDB_ENTITY` | W&B 사용자 또는 팀 이름 |
| `WANDB_RUN_ID` | 재개할 W&B 실행 ID |