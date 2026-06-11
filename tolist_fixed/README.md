# ToList - Flutter Mobile App

Versi mobile dari aplikasi web ToList, dengan desain yang sama persis:
- Background gelap `#0B0F1A`
- Aksen warna **Indigo** (`#6366F1`)
- Kartu dengan rounded corner dan efek blur
- Bottom navigation bar (pengganti sidebar web)

---

## 📱 Fitur

| Halaman | Deskripsi |
|---|---|
| **Login / Register** | Autentikasi dengan tampilan dua-panel seperti web |
| **Home (Catatan)** | Grid 2 kolom kartu catatan dengan bookmark toggle |
| **To-Do List** | Kanban 3 kolom: To Do, In Progress, Done (pakai TabBar di mobile) |
| **Bookmarked** | Catatan yang disimpan + fitur pencarian |
| **Upload / Tambah** | Form tambah catatan baru dengan tag suggestions |

---

## 🚀 Cara Menjalankan

### 1. Install Flutter
```
https://flutter.dev/docs/get-started/install
```

### 2. Clone / Extract project
```bash
cd tolist_flutter
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Jalankan di emulator atau device
```bash
flutter run
```

### 5. Build APK (Android)
```bash
flutter build apk --release
```
File APK ada di: `build/app/outputs/flutter-apk/app-release.apk`

### 6. Build iOS (butuh Mac + Xcode)
```bash
flutter build ios --release
```

---

## 👤 Akun Demo (Login)

| Username | Password |
|---|---|
| admin | 123 |
| nopal | 1234 |
| amsal | 000 |
| tes | tes |
| ilham | ilham123 |

---

## 🎨 Warna Desain

| Token | Hex | Kegunaan |
|---|---|---|
| bgPrimary | `#0B0F1A` | Background utama |
| bgSecondary | `#111827` | Bottom nav |
| bgCard | `#161B22` | Kartu / surface |
| indigo | `#6366F1` | Aksen utama |
| amber | `#F59E0B` | Bookmark |
| emerald | `#10B981` | Status done / sukses |
| rose | `#F43F5E` | Hapus / error |

---

## 📦 Dependencies

```yaml
shared_preferences: ^2.2.2   # Simpan data lokal
intl: ^0.19.0                 # Format tanggal
google_fonts: ^6.1.0          # Font Inter
flutter_staggered_grid_view   # Grid layout
```

> **Catatan**: Data disimpan secara lokal di device (SharedPreferences).
> Untuk koneksi ke backend PHP asli, ganti `StorageService` dengan HTTP calls ke API.
