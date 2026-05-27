# Thử Kính AR (glasses_tryon)

App Flutter: nhập link cửa hàng → quét/đồng bộ mẫu kính → thử trực tiếp lên khuôn mặt **real-time** bằng camera (AR overlay, Google ML Kit Face Detection), **chụp – lưu – chia sẻ** kết quả, **đo PD gợi ý size gọng**, và **kết nối backend** để cửa hàng tự đăng sản phẩm.

## Tính năng
1. **Quét cửa hàng** (`store_scraper.dart`) – best-effort qua JSON-LD/OpenGraph/heuristic; fallback catalog mẫu.
2. **AR try-on real-time** (`tryon_screen.dart` + `glasses_painter.dart`) – vẽ kính bám theo mắt; hỗ trợ **2.5D** (kính co theo `headEulerAngleY` khi quay đầu); overlay **ảnh PNG** nếu có.
3. **Chụp + lưu + chia sẻ** (`capture_service.dart`, `result_composer.dart`, `result_screen.dart`) – chụp ảnh, ghép kính lên ảnh, lưu vào thư viện (`gal`) và chia sẻ (`share_plus`).
4. **Đo PD** (`pd_estimator.dart`, `pd_screen.dart`) – hiệu chuẩn bằng thẻ ID-1 (85.6mm), suy ra PD (mm) + gợi ý size gọng.
5. **Backend cửa hàng** (`backend/` FastAPI + `api_service.dart`) – cửa hàng upload PNG kính tách nền, app tải về overlay đẹp.

```
lib/
├── main.dart
├── models/glasses.dart
├── services/
│   ├── store_scraper.dart      # scrape web (best-effort)
│   ├── api_service.dart        # tải catalog từ backend
│   ├── face_detector_service.dart
│   ├── capture_service.dart    # chụp + bake orientation + detect
│   ├── result_composer.dart    # ghép kính lên ảnh -> PNG
│   └── pd_estimator.dart       # tính PD + gợi ý size
├── utils/
│   ├── coordinate_translator.dart
│   └── image_loader.dart       # nạp PNG overlay -> ui.Image
├── widgets/
│   ├── glasses_drawing.dart    # hàm vẽ kính dùng chung (vector/PNG, 2.5D)
│   └── glasses_painter.dart    # painter cho live preview
└── screens/  (home, catalog, tryon, result, pd, capture_for_pd)
backend/  (FastAPI: upload & list sản phẩm)
```

## Chạy app

```bash
cd glasses_tryon
flutter create .        # sinh android/ ios/ (giữ nguyên lib/)
flutter pub get
flutter run             # CHẠY TRÊN ĐIỆN THOẠI THẬT
```

## Cấu hình native bắt buộc

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<!-- Backend demo chạy HTTP (không TLS) -> cho phép cleartext khi DEV: -->
<application android:usesCleartextTraffic="true" ... >
```
`android/app/build.gradle`: `minSdkVersion 21`.

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>App cần camera để thử kính lên khuôn mặt.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>App cần lưu ảnh kết quả vào thư viện.</string>
```
`ios/Podfile`: `platform :ios, '15.5'`.

## Chạy backend (tuỳ chọn)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
- Cửa hàng upload qua trình duyệt: `http://<IP>:8000/stores/demo/upload`
- Trong app, nút **Kết nối backend cửa hàng**:
  - Emulator Android → Base URL `http://10.0.2.2:8000`
  - Điện thoại thật → `http://<IP-máy-tính-trong-LAN>:8000`
  - Store ID: `demo`

## Cách dùng từng tính năng
- **Thử kính**: Trang chủ → quét/backend/catalog mẫu → chọn mẫu → màn camera. Đổi mẫu ở thanh dưới.
- **Chụp kết quả**: ở màn camera bấm nút chụp tròn → màn kết quả có **Lưu / Chia sẻ / Đo PD**.
- **Đo PD**: Trang chủ → "Đo PD" (cầm thẻ ngân hàng ngang dưới mắt, chụp) → kéo 2 chấm xanh vào đồng tử, 2 chấm vàng trùng mép thẻ → đọc PD + gợi ý size.

## Giới hạn (đọc kỹ)
- **Scrape**: không chạy đúng mọi site (SPA/JS trả HTML rỗng) → fallback mẫu. Backend là cách bền vững hơn.
- **Đo PD**: là **ước lượng** dựa trên hiệu chuẩn thẻ; sai số phụ thuộc thao tác căn chấm. KHÔNG thay thế đo khám.
- **AR 2.5D**: kính co/giãn theo góc quay đầu để giả lập 3D, nhưng **chưa phải 3D thật**. Muốn 3D bám mặt chuẩn cần ARKit (iOS) / ARCore (Android) Augmented Faces — là phần native riêng, ngoài phạm vi bản này.

## Hướng phát triển tiếp
- Native 3D Augmented Faces (ARKit/ARCore) hoặc MediaPipe Face Mesh để bám sát phối cảnh.
- Iris detection để đo PD tự động không cần thẻ.
- DB thật + lưu trữ ảnh (S3) cho backend; xác thực cửa hàng.
