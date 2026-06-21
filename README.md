# justOCR - Accessibility-First Document Reader

A Flutter application designed specifically for **visually impaired and blind users** to scan, read, and listen to documents in Persian (Farsi), Arabic, and English.

## 🎯 Mission

Provide complete accessibility for users who cannot see the screen, with full TalkBack/VoiceOver support, audio feedback, and intuitive navigation.

## ✨ Key Features

### Core Functionality
- **OCR Scanning**: Extract text from PDFs, images (JPG/PNG), and EPUB files
- **Text-to-Speech**: Read extracted text aloud with adjustable speed
- **Offline Support**: PaddleOCR OCR works without internet; Gemini fallback for better Persian accuracy
- **Reading Position**: Automatically saves and restores your place

### Accessibility Features
- ✅ **Full Screen Reader Support**: Every UI element has proper semantic labels
- ✅ **Live Region Announcements**: Progress updates announced automatically
- ✅ **Large Touch Targets**: All buttons are 48×48 minimum (WCAG AAA)
- ✅ **High Contrast Mode**: Dedicated theme for low vision users
- ✅ **RTL Support**: Full right-to-left layout for Persian/Arabic
- ✅ **Keyboard Navigation**: Works with external keyboards and switches
- ✅ **No Visual Dependencies**: All actions possible without seeing the screen

### Simple Three-Tab Interface
1. **کتاب‌ها (Books)**: View and read your scanned documents
2. **اسکن (Scan)**: Import new documents for OCR processing
3. **تنظیمات (Settings)**: Customize TTS, accessibility, and app preferences

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point with accessibility config
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── main_dashboard.dart    # Tab-based navigation
│   │       ├── library_screen.dart    # Books list & reader
│   │       ├── scan_tab.dart          # Document import
│   │       └── settings_tab.dart      # App settings
│   └── reader/
│       ├── book_state.dart            # State machine (sealed classes)
│       └── book_notifier.dart         # Business logic
├── services/
│   ├── ocr_service_impl.dart          # OCR pipeline (Gemini + PaddleOCR)
│   └── file_import_service_impl.dart  # File picker
└── data/
    ├── models/                        # Isar database models
    └── database/                      # Local storage
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.12+
- Android Studio / VS Code
- Android device or emulator (API 21+)
- **Gemini API Key** (for cloud OCR)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd just_ocr
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Gemini API Key** (optional but recommended for Persian OCR)
   
   Create a `.env` file or pass via command line:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini API key for cloud OCR | No* |

*Without API key, app falls back to PaddleOCR (offline, less accurate for Persian)

### Android Permissions

The app automatically requests these permissions at runtime:
- `READ_EXTERNAL_STORAGE`: Access PDF/image files
- `INTERNET`: Cloud OCR (Gemini)

## 📱 Usage Guide

### For Screen Reader Users

1. **Opening the App**
   - Launch app; TalkBack announces "justOCR - دستیار خواندن برای نابینایان"
   - You land on the Books tab by default

2. **Scanning a Document**
   - Swipe right to reach the "اسکن" (Scan) tab
   - Double-tap the large circular button
   - Use system file picker to select PDF or image
   - Progress is announced automatically ("در حال پردازش صفحه ۱ از ۵...")
   - When complete, swipe to Settings or Books tab

3. **Reading a Document**
   - Navigate to Books tab
   - Select your document
   - Use bottom navigation buttons:
     - صفحه قبل (Previous Page)
     - بند قبل (Previous Paragraph)
     - بند بعد (Next Paragraph)  
     - صفحه بعد (Next Page)
   - Each paragraph announces its position: "بند ۳ از ۱۲، بند فعال"

4. **Adjusting Settings**
   - Navigate to Settings tab
   - Toggle options:
     - TTS activation
     - Reading speed (0.5x - 2.0x)
     - High contrast mode
     - Large text mode

## 🛠️ Development

### Build Order (Recommended)

Following the spec's phased approach:

1. ✅ **Phase 1**: Auth & storage foundation
2. ✅ **Phase 2**: Image import + OCR service
3. ✅ **Phase 3**: Reader UI + TTS integration
4. 🔄 **Phase 4**: PDF support (implemented, needs testing)
5. ⏳ **Phase 5**: EPUB support (placeholder)
6. ⏳ **Phase 6**: Audio export (future)

### Running Tests
```bash
flutter test
```

### Code Generation (Isar)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## ♿ Accessibility Checklist

This app follows WCAG 2.1 AAA guidelines:

- [x] All interactive elements have semantic labels
- [x] Touch targets minimum 48×48 dp
- [x] Color contrast ratio ≥ 7:1 (normal text)
- [x] No information conveyed by color alone
- [x] Live regions for dynamic content
- [x] Focus management for state changes
- [x] RTL layout support
- [x] Text scaling up to 200% without overflow
- [x] Works with TalkBack, VoiceOver, Switch Access

## 📄 Supported Formats

| Format | Support Level | Notes |
|--------|--------------|-------|
| PDF | ✅ Full | Up to 10 pages (configurable) |
| JPG/PNG | ✅ Full | Single images |
| EPUB | ⏳ Coming Soon | Placeholder implemented |

## 🔮 Roadmap

### Phase 1 (Current)
- ✅ Basic OCR pipeline
- ✅ Three-tab dashboard
- ✅ Accessibility foundation
- ✅ TTS settings

### Phase 2 (Next)
- [ ] Full EPUB parsing
- [ ] Document library management (save/delete)
- [ ] Bookmark system
- [ ] Search within documents

### Phase 3 (Future)
- [ ] Audio export (MP3)
- [ ] Cloud sync
- [ ] Multiple language support
- [ ] Advanced TTS voice selection

## 🤝 Contributing

Contributions welcome! Please focus on:
1. Accessibility improvements
2. Persian/Arabic OCR accuracy
3. Performance optimizations
4. Bug fixes

## 📝 License

[Your License Here]

## 🙏 Acknowledgments

Built with:
- Flutter & Dart
- Riverpod (state management)
- Google Gemini AI (cloud OCR)
- PaddleOCR (offline OCR)
- Isar (local database)
- flutter_tts (text-to-speech)

---

**Made with ❤️ for accessibility**

For issues or questions, please open an issue on GitHub.
