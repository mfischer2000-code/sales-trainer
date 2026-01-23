const { app, BrowserWindow, Menu, shell, clipboard, dialog } = require('electron');
const path = require('path');

// Halte eine globale Referenz auf das Fenster-Objekt
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1000,
    height: 800,
    minWidth: 600,
    minHeight: 500,
    titleBarStyle: 'hiddenInset', // Native macOS Look
    trafficLightPosition: { x: 15, y: 15 },
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#f0f2f5',
    show: false // Zeige Fenster erst wenn geladen
  });

  mainWindow.loadFile('index.html');

  // Zeige Fenster wenn bereit (vermeidet weißen Blitz)
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Öffne externe Links im Standard-Browser
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

// Native macOS Menüleiste
function createMenu() {
  const isMac = process.platform === 'darwin';

  const template = [
    // App Menu (nur macOS)
    ...(isMac ? [{
      label: app.name,
      submenu: [
        { role: 'about', label: 'Über AI Sales Trainer' },
        { type: 'separator' },
        { role: 'services', label: 'Dienste' },
        { type: 'separator' },
        { role: 'hide', label: 'AI Sales Trainer ausblenden' },
        { role: 'hideOthers', label: 'Andere ausblenden' },
        { role: 'unhide', label: 'Alle einblenden' },
        { type: 'separator' },
        { role: 'quit', label: 'AI Sales Trainer beenden' }
      ]
    }] : []),

    // Bearbeiten Menu
    {
      label: 'Bearbeiten',
      submenu: [
        { role: 'undo', label: 'Widerrufen' },
        { role: 'redo', label: 'Wiederholen' },
        { type: 'separator' },
        { role: 'cut', label: 'Ausschneiden' },
        { role: 'copy', label: 'Kopieren' },
        { role: 'paste', label: 'Einsetzen' },
        { role: 'selectAll', label: 'Alles auswählen' }
      ]
    },

    // Ansicht Menu
    {
      label: 'Ansicht',
      submenu: [
        { role: 'reload', label: 'Neu laden' },
        { role: 'forceReload', label: 'Erzwungenes Neuladen' },
        { type: 'separator' },
        { role: 'resetZoom', label: 'Originalgröße' },
        { role: 'zoomIn', label: 'Vergrößern' },
        { role: 'zoomOut', label: 'Verkleinern' },
        { type: 'separator' },
        { role: 'togglefullscreen', label: 'Vollbild' }
      ]
    },

    // Fenster Menu
    {
      label: 'Fenster',
      submenu: [
        { role: 'minimize', label: 'Minimieren' },
        { role: 'zoom', label: 'Zoom' },
        ...(isMac ? [
          { type: 'separator' },
          { role: 'front', label: 'Alles nach vorne bringen' }
        ] : [
          { role: 'close', label: 'Schließen' }
        ])
      ]
    },

    // Hilfe Menu
    {
      label: 'Hilfe',
      submenu: [
        {
          label: 'Über LACE-Methode',
          click: async () => {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'LACE-Methode',
              message: 'LACE-Methode für Einwandbehandlung',
              detail: 'L - Listen (Zuhören)\nA - Accept (Akzeptieren)\nC - Commit (Verpflichten)\nE - Explore (Erkunden)\n\nValidiere erst das Gefühl des Kunden, bevor du argumentierst.'
            });
          }
        },
        {
          label: 'Sales-Tipps',
          click: async () => {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'Sales-Tipps',
              message: 'Wichtige Sales-Prinzipien',
              detail: '• Techniker: Kein Fluff, Fokus auf Integration & APIs\n• Manager: Business Case & ROI aufzeigen\n• Endanwender: Zeitersparnis & Einfachheit\n\nKaltakquise: Problem ansprechen, nicht Features\nClosing: Klarer Next Step, keine neuen Features!'
            });
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// App ist bereit
app.whenReady().then(() => {
  createWindow();
  createMenu();

  // macOS: Fenster neu erstellen wenn Dock-Icon geklickt wird
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// Beende App wenn alle Fenster geschlossen sind (außer auf macOS)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Sicherheit: Verhindere neue WebContents
app.on('web-contents-created', (event, contents) => {
  contents.on('will-navigate', (event, navigationUrl) => {
    const parsedUrl = new URL(navigationUrl);
    if (parsedUrl.origin !== 'file://') {
      event.preventDefault();
    }
  });
});
