# Setup iOS untuk File Picker

Tambahkan permission berikut ke file `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi membutuhkan akses ke foto untuk upload lampiran catatan.</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>Aplikasi membutuhkan akses ke dokumen untuk upload file catatan.</string>
```
