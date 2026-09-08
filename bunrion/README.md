# 분리ON Flutter App

생활폐기물 이미지를 분석해 재활용 품목을 탐지하고 품목별 분리배출 방법을 안내하는 Android 중심 Flutter 앱

## 주요 기능

- 카메라 촬영 이미지 분석
- 갤러리 이미지 불러오기 및 분석
- YOLO 객체 탐지 결과 바운딩 박스 표시
- 7개 생활폐기물 품목 안내
- 분리배출 가이드 카드 제공
- 인식 기록 저장 및 이전 결과 다시 보기
- YOLOView 기반 실시간 탐지
- 모델 신뢰도 임계값 설정

## 앱 구조

```text
lib/
├─ app/                  # 라우터·테마·전역 Provider
├─ core/                 # 품목 상수·이미지 준비 유틸
├─ data/                 # 분리배출 가이드 Repository
├─ features/
│  ├─ camera/            # 사진 촬영
│  ├─ detection/         # 분석·결과 화면
│  ├─ live_detection/    # 실시간 탐지
│  ├─ dictionary/        # 품목 사전
│  ├─ history/           # 인식 기록
│  └─ settings/          # 설정
└─ services/
   ├─ model/             # TFLite/LiteRT 탐지
   └─ storage/           # 로컬 기록 저장
```

## 지원 클래스

| ID | 클래스 |
|---:|---|
| 0 | 플라스틱류 |
| 1 | 종이류 |
| 2 | 음료수곽 |
| 3 | 유리병류 |
| 4 | 캔류 |
| 5 | 비닐류 |
| 6 | 스티로폼류 |

## 모델

```text
assets/models/waste_yolo11s.tflite
```

- YOLO 기반 생활폐기물 탐지 모델
- LiteRT/TFLite 형식의 온디바이스 추론
- 네트워크 연결 없이 기기 내부 분석

## 실시간 탐지 안정화

`third_party/ultralytics_yolo`에 Android 종료 시점 안정화를 위한 로컬 패치 적용

- `YOLOView.dispose()`의 `stop()` 대신 `pause()` 호출
- Android `YOLOPlatformView.dispose()`의 `yoloView.stop()` 대신 `pauseCamera()` 호출
- Flutter `stop` 요청의 Android `pauseCamera()` 처리

## 실행

```bash
flutter pub get
flutter run
```

Android debug APK 빌드:

```bash
flutter build apk --debug
```

## 검증

```bash
flutter analyze
flutter test
flutter build apk --debug
```

- 정적 분석 통과
- 자동화 테스트 통과
- Android debug APK 빌드 통과