# 🚀 AI Sales Trainer - Mac App

Eine native macOS-Anwendung zum Trainieren von KI-gestützten Sales-Strategien.

## Features

- **Persona-basierte Strategien**: CTO, CFO oder Endanwender
- **Verkaufsphasen**: Kaltakquise, Einwandbehandlung, Closing
- **KI-Prompt-Generator**: Perfekte Prompts für ChatGPT/Claude
- **One-Click Kopieren**: Prompt direkt in die Zwischenablage
- **Tastaturkürzel**: ⌘+Enter zum Generieren
- **Native macOS-Integration**: Menüleiste, Fenster-Management

## Installation & Entwicklung

### Voraussetzungen

- Node.js 18+ installiert
- npm oder yarn

### Starten in Entwicklungsmodus

```bash
# Abhängigkeiten installieren
npm install

# App starten
npm start
```

### Mac App bauen

```bash
# DMG für macOS erstellen
npm run build

# Oder spezifisch als DMG
npm run build:dmg
```

Die fertige App befindet sich dann unter `dist/`.

## App-Icon erstellen

Für ein korrektes macOS-Icon:

1. Erstelle ein 1024x1024 PNG-Bild
2. Konvertiere zu `.icns`:

```bash
# Mit iconutil (macOS)
mkdir icon.iconset
sips -z 16 16   icon.png --out icon.iconset/icon_16x16.png
sips -z 32 32   icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32   icon.png --out icon.iconset/icon_32x32.png
sips -z 64 64   icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128 icon.png --out icon.iconset/icon_128x128.png
sips -z 256 256 icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256 icon.png --out icon.iconset/icon_256x256.png
sips -z 512 512 icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512 icon.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png
iconutil -c icns icon.iconset
mv icon.icns assets/
```

3. Oder nutze ein Online-Tool wie [CloudConvert](https://cloudconvert.com/png-to-icns)

## Projektstruktur

```
sales-trainer/
├── assets/           # Icons und Bilder
│   └── icon.icns     # macOS App-Icon
├── dist/             # Build-Output
├── index.html        # Haupt-UI
├── main.js           # Electron Main-Prozess
├── preload.js        # Sicherer Bridge zum Renderer
├── package.json      # Projektconfig & Scripts
└── README.md
```

## Tastaturkürzel

| Kürzel | Aktion |
|--------|--------|
| ⌘+Enter | Strategie generieren |
| ⌘+C | Kopieren (nach Auswahl) |
| ⌘+Q | App beenden |
| ⌘+, | Einstellungen (macOS) |

## Lizenz

MIT
