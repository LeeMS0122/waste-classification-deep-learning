# Waste Classification Deep Learning

생활폐기물 이미지를 재활용 품목별로 탐지하고 분리배출 방법을 안내하는 딥러닝 기반 프로젝트입니다. AI Hub 생활폐기물 데이터를 YOLO 객체 탐지 형식으로 변환하고, 학습된 YOLO 모델을 Flutter Android 앱 `분리ON`에 탑재해 모바일에서 사진 분석과 실시간 탐지를 수행합니다.

## 프로젝트 개요

- 목표: 생활폐기물 사진에서 재활용 품목을 탐지하고 올바른 분리배출 정보를 제공
- 모델: YOLO 계열 객체 탐지 모델
- 모바일 배포: Flutter Android 앱 + LiteRT/TFLite 모델
- 주요 품목: 플라스틱류, 종이류, 음료수곽, 유리병류, 캔류, 비닐류, 스티로폼류

## 주요 기능

- 카메라 촬영 후 폐기물 객체 탐지
- 갤러리 이미지 불러오기 및 분석
- 탐지 결과 바운딩 박스 표시
- 품목별 분리배출 가이드 제공
- 인식 기록 저장 및 결과 다시 보기
- YOLOView 기반 실시간 탐지 화면
- 모델 신뢰도 임계값 설정

## 모바일 앱

Flutter 앱은 `bunrion/` 폴더에 있습니다.

```text
bunrion/
  lib/
    features/
      camera/          # 사진 촬영
      detection/       # 분석/결과 화면
      live_detection/  # 실시간 탐지 화면
      history/         # 인식 기록
      dictionary/      # 품목 사전
      settings/        # 설정
    services/
      model/           # LiteRT/TFLite 탐지 서비스
      storage/         # 로컬 기록 저장
  assets/
    data/              # 분리배출 가이드 JSON
    models/            # 앱 내장 TFLite 모델
```

자세한 앱 실행 방법은 [bunrion/README.md](bunrion/README.md)를 참고하세요.

## 모델 및 데이터 처리

이 저장소에는 AI Hub 데이터를 YOLO 탐지 데이터셋으로 변환하고 학습 결과를 비교하기 위한 스크립트가 포함되어 있습니다.

- `convert_aihub_to_yolo_detection_v2.py`
- `convert_aihub_to_yolo_detection_v3.py`
- `count_details_structure.py`
- `model_compare_from_results.py`
- `train_yolo_wandb.py`
- `train_yolo_wandb2.py`

학습 산출물과 대용량 원본 모델 파일은 GitHub 업로드 대상에서 제외하는 것을 권장합니다.

## Android APK 빌드

```bash
cd bunrion
flutter pub get
flutter build apk --debug
```

빌드 결과:

```text
bunrion/build/app/outputs/flutter-apk/app-debug.apk
```

Windows PC에서 APK를 가져와 설치하는 예시:

```bat
scp minsu@210.110.39.121:/home/minsu/disk_a/miniconda3/graduation_work/bunrion/build/app/outputs/flutter-apk/app-debug.apk C:\Users\LMS\Downloads\
adb install -r C:\Users\LMS\Downloads\app-debug.apk
```

## 기술 스택

- Flutter
- Android
- LiteRT/TFLite
- Ultralytics YOLO
- Riverpod
- go_router
- camera
- image_picker
- shared_preferences

## 현재 상태

- Android debug APK 빌드 성공
- 사진 촬영/갤러리 분석 기능 구현
- 바운딩 박스 보정 적용
- 인식 기록 다시 보기 구현
- 실시간 탐지 화면 구현
- `flutter analyze`, `flutter test`, `flutter build apk --debug` 통과
