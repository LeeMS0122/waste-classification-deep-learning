# 분리ON Flutter App

`분리ON`은 생활폐기물 이미지를 촬영하거나 갤러리에서 불러와 재활용 품목을 탐지하고, 품목별 분리배출 방법을 안내하는 Android 중심 Flutter 앱입니다.

## 주요 기능

- 카메라 촬영 후 이미지 분석
- 갤러리 이미지 분석
- YOLO 객체 탐지 결과 바운딩 박스 표시
- 플라스틱류, 종이류, 음료수곽, 유리병류, 캔류, 비닐류, 스티로폼류 안내
- 분리배출 가이드 카드 제공
- 인식 기록 저장
- 기록 항목 클릭 시 이전 사진과 결과 다시 보기
- YOLOView 기반 실시간 탐지
- 신뢰도 임계값 설정

## 앱 구조

```text
lib/
  app/                  # 라우터, 테마, 전역 provider
  core/                 # 품목 상수, 이미지 준비 유틸
  data/                 # 분리배출 가이드 repository
  features/
    home/               # 홈
    camera/             # 사진 촬영
    detection/          # 분석/결과 화면
    live_detection/     # 실시간 탐지
    dictionary/         # 품목 사전
    history/            # 기록
    settings/           # 설정
  services/
    model/              # TFLite/LiteRT 탐지 서비스
    storage/            # shared_preferences 기반 기록 저장
assets/
  data/disposal_guides_ko.json
  models/waste_yolo11s.tflite
```

## 모델

앱에는 YOLO 기반 생활폐기물 탐지 모델을 LiteRT/TFLite 형식으로 변환한 파일이 포함됩니다.

```text
assets/models/waste_yolo11s.tflite
```

지원 클래스:

| ID | 클래스 |
|---:|---|
| 0 | 플라스틱류 |
| 1 | 종이류 |
| 2 | 음료수곽 |
| 3 | 유리병류 |
| 4 | 캔류 |
| 5 | 비닐류 |
| 6 | 스티로폼류 |

## 실시간 탐지 안정화

실시간 탐지는 속도를 위해 `ultralytics_yolo`의 `YOLOView`를 사용합니다. Android에서 화면을 벗어날 때 일부 기기에서 LiteRT predictor 종료 타이밍으로 앱이 중단되는 문제가 있어, `third_party/ultralytics_yolo`에 로컬 패치를 적용했습니다.

`pubspec.yaml`은 pub.dev 원본 대신 로컬 플러그인을 사용합니다.

```yaml
ultralytics_yolo:
  path: third_party/ultralytics_yolo
```

패치 요약:

- `YOLOView.dispose()`에서 `stop()` 대신 `pause()` 호출
- Android `YOLOPlatformView.dispose()`에서 `yoloView.stop()` 대신 `pauseCamera()` 호출
- Flutter `stop` 요청도 Android에서 `pauseCamera()`로 처리

## 실행

```bash
flutter pub get
flutter run
```

Android debug APK 빌드:

```bash
flutter build apk --debug
```

APK 위치:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 검증

```bash
flutter analyze
flutter test
flutter build apk --debug
```

현재 위 명령들이 통과한 상태입니다.

## 설치 예시

Windows PC에서 원격 서버의 APK를 가져온 뒤 Android 기기에 설치하는 예시입니다.

```bat
scp minsu@210.110.39.121:/home/minsu/disk_a/miniconda3/graduation_work/bunrion/build/app/outputs/flutter-apk/app-debug.apk C:\Users\LMS\Downloads\
adb install -r C:\Users\LMS\Downloads\app-debug.apk
```
