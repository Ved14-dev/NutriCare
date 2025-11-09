This directory is for bundled font files required for offline glyph coverage.

Place the following font files in this folder (download links shown):

- Noto Sans Regular
  - File name expected: NotoSans-Regular.ttf
  - Download: https://github.com/googlefonts/noto-fonts/blob/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf?raw=true

- Noto Sans Bold
  - File name expected: NotoSans-Bold.ttf
  - Download: https://github.com/googlefonts/noto-fonts/blob/main/hinted/ttf/NotoSans/NotoSans-Bold.ttf?raw=true

- Noto Color Emoji (optional, covers emoji glyphs on some platforms)
  - File name expected: NotoColorEmoji.ttf
  - Download: https://github.com/googlefonts/noto-emoji/blob/main/fonts/NotoColorEmoji.ttf?raw=true

Instructions:
1. Download the `.ttf` files from the links above.
2. Save them into this folder using the exact file names listed.
3. Run:
   flutter pub get
4. Rebuild the app:
   flutter clean
   flutter run -d chrome

If you want me to download and add these files for you, tell me and I'll fetch them and add them into `assets/fonts/`.
