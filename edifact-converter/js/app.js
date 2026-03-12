/**
 * EDIFACT Converter - Application Logic
 * Handles UI interactions, file I/O, and conversion orchestration
 */

// Global state
let currentOutput = '';
let currentOutputFormat = 'json';
let currentTab = 'formatted';
let lastParsedInterchange = null;

// Sample EDIFACT messages (embedded for quick loading)
const EXAMPLES = {
  orders: `UNA:+.? '
UNB+UNOC:3+SENDER:14+RECEIVER:14+260312:1430+00000000000117'
UNH+1+ORDERS:D:96A:UN'
BGM+220+PO-2026-00451+9'
DTM+137:20260312:102'
DTM+2:20260320:102'
RFF+ON:PO-2026-00451'
NAD+BY+4012345000009::9++Mustermann GmbH+Industriestr. 42+Berlin++10115+DE'
NAD+SE+4098765000003::9++Lieferant AG+Hauptstr. 7+Muenchen++80331+DE'
NAD+DP+4012345000016::9++Mustermann GmbH Lager+Lagerweg 5+Hamburg++20095+DE'
CUX+2:EUR:4'
LIN+1++4000862141404:EN'
IMD+F++:::Schreibtischlampe LED 15W'
QTY+21:50:PCE'
PRI+AAA:29.90'
LIN+2++4000862141411:EN'
IMD+F++:::Monitorhalterung Dual 27 Zoll'
QTY+21:25:PCE'
PRI+AAA:79.50'
LIN+3++4000862141428:EN'
IMD+F++:::USB-C Docking Station'
QTY+21:10:PCE'
PRI+AAA:149.00'
UNS+S'
MOA+86:5352.50'
CNT+2:3'
UNT+20+1'
UNZ+1+00000000000117'`,

  invoic: `UNA:+.? '
UNB+UNOC:3+LIEFERANT:14+KUNDE:14+260312:0900+00000000000225'
UNH+1+INVOIC:D:96A:UN'
BGM+380+INV-2026-00789+9'
DTM+137:20260312:102'
DTM+35:20260310:102'
RFF+ON:PO-2026-00451'
RFF+DQ:LS-2026-00312'
NAD+SE+4098765000003::9++Lieferant AG+Hauptstr. 7+Muenchen++80331+DE'
NAD+BY+4012345000009::9++Mustermann GmbH+Industriestr. 42+Berlin++10115+DE'
NAD+IV+4012345000009::9++Mustermann GmbH Buchhaltung+Industriestr. 42+Berlin++10115+DE'
CUX+2:EUR:4'
PAT+1++5:3:D:30'
LIN+1++4000862141404:EN'
IMD+F++:::Schreibtischlampe LED 15W'
QTY+47:50:PCE'
MOA+203:1495.00'
PRI+AAA:29.90'
TAX+7+VAT+++:::19'
MOA+128:284.05'
LIN+2++4000862141411:EN'
IMD+F++:::Monitorhalterung Dual 27 Zoll'
QTY+47:25:PCE'
MOA+203:1987.50'
PRI+AAA:79.50'
TAX+7+VAT+++:::19'
MOA+128:377.63'
LIN+3++4000862141428:EN'
IMD+F++:::USB-C Docking Station'
QTY+47:10:PCE'
MOA+203:1490.00'
PRI+AAA:149.00'
TAX+7+VAT+++:::19'
MOA+128:283.10'
UNS+S'
MOA+79:4972.50'
MOA+128:944.78'
MOA+86:5917.28'
UNT+31+1'
UNZ+1+00000000000225'`,

  desadv: `UNA:+.? '
UNB+UNOC:3+LIEFERANT:14+KUNDE:14+260312:0800+00000000000330'
UNH+1+DESADV:D:96A:UN'
BGM+351+LS-2026-00312+9'
DTM+137:20260310:102'
DTM+11:20260312:102'
RFF+ON:PO-2026-00451'
NAD+SE+4098765000003::9++Lieferant AG+Hauptstr. 7+Muenchen++80331+DE'
NAD+BY+4012345000009::9++Mustermann GmbH+Industriestr. 42+Berlin++10115+DE'
NAD+DP+4012345000016::9++Mustermann GmbH Lager+Lagerweg 5+Hamburg++20095+DE'
TDT+20+1+++:::DHL Express'
CPS+1'
PAC+3++CT'
CPS+2+1'
PAC+1++CT'
PCI+33E'
LIN+1++4000862141404:EN'
IMD+F++:::Schreibtischlampe LED 15W'
QTY+12:50:PCE'
CPS+3+1'
PAC+1++CT'
PCI+33E'
LIN+2++4000862141411:EN'
IMD+F++:::Monitorhalterung Dual 27 Zoll'
QTY+12:25:PCE'
CPS+4+1'
PAC+1++BX'
PCI+33E'
LIN+3++4000862141428:EN'
IMD+F++:::USB-C Docking Station'
QTY+12:10:PCE'
CNT+2:3'
UNT+26+1'
UNZ+1+00000000000330'`
};

// ============================================================
// Initialization
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
  setupDragAndDrop();
  updatePanelTitles();
});

// ============================================================
// Core Conversion
// ============================================================

function convertInput() {
  const input = document.getElementById('inputEditor').value.trim();
  const inputFormat = document.getElementById('inputFormat').value;
  const outputFormat = document.getElementById('outputFormat').value;

  if (!input) {
    showToast('Bitte Eingabedaten eingeben oder Datei laden.', 'error');
    return;
  }

  try {
    setStatus('converting', 'Konvertiere...');

    let interchange;

    // Step 1: Parse input to intermediate JSON representation
    switch (inputFormat) {
      case 'edifact':
        const parser = new EdifactParser();
        interchange = parser.parse(input);
        break;
      case 'json':
        interchange = JSON.parse(input);
        break;
      case 'xml':
        interchange = XmlConverter.xmlToJson(input);
        break;
      default:
        throw new Error('Unbekanntes Eingabeformat: ' + inputFormat);
    }

    lastParsedInterchange = interchange;

    // Step 2: Convert to output format
    let output;
    switch (outputFormat) {
      case 'json':
        output = JSON.stringify(interchange, null, 2);
        currentOutputFormat = 'json';
        break;
      case 'xml':
        output = XmlConverter.jsonToXml(interchange);
        currentOutputFormat = 'xml';
        break;
      case 'edifact':
        const generator = new EdifactGenerator();
        output = generator.generate(interchange);
        currentOutputFormat = 'edifact';
        break;
      default:
        throw new Error('Unbekanntes Ausgabeformat: ' + outputFormat);
    }

    currentOutput = output;
    displayOutput(output);
    updateAnalysisView(interchange);
    updateStats(interchange, inputFormat, outputFormat);
    setStatus('success', 'Konvertierung erfolgreich');
    showToast('Konvertierung erfolgreich!', 'success');

  } catch (err) {
    setStatus('error', 'Fehler: ' + err.message);
    document.getElementById('outputEditor').value = '';
    document.getElementById('treeView').innerHTML =
      `<div class="error-box">${escapeHtml(err.message)}</div>`;
    showToast('Fehler: ' + err.message, 'error');
  }
}

// ============================================================
// Display Functions
// ============================================================

function displayOutput(output) {
  const textarea = document.getElementById('outputEditor');
  textarea.value = output;

  // Show correct view based on current tab
  if (currentTab === 'tree') {
    textarea.style.display = 'none';
    document.getElementById('treeView').style.display = 'block';
  } else {
    textarea.style.display = 'block';
    document.getElementById('treeView').style.display = 'none';
  }
}

function updateAnalysisView(interchange) {
  const treeView = document.getElementById('treeView');
  let html = '';

  // Interchange info
  if (interchange.header) {
    html += '<div style="margin-bottom:16px;">';
    html += '<strong style="font-size:14px;">Interchange</strong><br>';
    html += `<span class="seg-tag">UNB</span>`;
    html += `Sender: <strong>${escapeHtml(interchange.header.sender?.id || '?')}</strong>`;
    html += ` &rarr; Empfaenger: <strong>${escapeHtml(interchange.header.recipient?.id || '?')}</strong>`;
    html += `<br>Datum: ${escapeHtml(interchange.header.dateTime?.date || '?')} ${escapeHtml(interchange.header.dateTime?.time || '')}`;
    html += `<br>Referenz: ${escapeHtml(interchange.header.controlReference || '?')}`;
    html += '</div>';
  }

  // Messages
  const allMessages = [
    ...(interchange.messages || []),
    ...(interchange.groups || []).flatMap(g => g.messages || [])
  ];

  for (const msg of allMessages) {
    const msgType = msg.header?.messageIdentifier?.type || 'UNKNOWN';
    const schema = EdifactSchemas.getMessageSchema(msgType);

    html += '<div style="margin-bottom:16px; padding:12px; background:var(--gray-50); border-radius:8px; border:1px solid var(--gray-200);">';
    html += `<strong style="font-size:13px;">${escapeHtml(msgType)}</strong>`;
    if (schema) {
      html += ` <span class="seg-name">${escapeHtml(schema.description)}</span>`;
    }
    html += `<br><span style="font-size:11px; color:var(--gray-500);">Ref: ${escapeHtml(msg.header?.referenceNumber || '?')} | Version: ${escapeHtml(msg.header?.messageIdentifier?.version || '')} ${escapeHtml(msg.header?.messageIdentifier?.release || '')}</span>`;

    // Segments
    if (msg.segments && msg.segments.length > 0) {
      html += '<div style="margin-top:10px;">';
      for (const seg of msg.segments) {
        const segName = EdifactSchemas.getSegmentName(seg.tag);
        html += '<div style="margin:4px 0; padding:4px 8px; background:white; border-radius:4px; font-size:12px;">';
        html += `<span class="seg-tag">${escapeHtml(seg.tag)}</span>`;
        html += `<span class="seg-name">${escapeHtml(segName)}</span> `;

        // Show element values inline
        if (seg.elements && seg.elements.length > 0) {
          const values = seg.elements.map(el => {
            if (Array.isArray(el)) {
              return el.filter(c => c).join(':');
            }
            return String(el);
          }).filter(v => v);
          html += `<span style="color:var(--gray-600);">${escapeHtml(values.join(' | '))}</span>`;
        }

        html += '</div>';
      }
      html += '</div>';
    }

    html += '</div>';
  }

  if (!html) {
    html = '<div style="color:var(--gray-400); text-align:center; padding:40px;">Keine Analysedaten verfuegbar. Bitte zuerst konvertieren.</div>';
  }

  treeView.innerHTML = html;
}

function updateStats(interchange, inputFormat, outputFormat) {
  const allMessages = [
    ...(interchange.messages || []),
    ...(interchange.groups || []).flatMap(g => g.messages || [])
  ];

  const totalSegments = allMessages.reduce((sum, m) => sum + (m.segments?.length || 0), 0);
  const msgTypes = [...new Set(allMessages.map(m => m.header?.messageIdentifier?.type || '?'))];

  document.getElementById('statsText').textContent =
    `${inputFormat.toUpperCase()} -> ${outputFormat.toUpperCase()} | ${allMessages.length} Nachricht(en) | ${totalSegments} Segmente | Typ(en): ${msgTypes.join(', ')}`;
}

// ============================================================
// Tab Switching
// ============================================================

function switchTab(tabEl, tabName) {
  currentTab = tabName;

  // Update tab styles
  document.querySelectorAll('.panel-tab').forEach(t => t.classList.remove('active'));
  tabEl.classList.add('active');

  const textarea = document.getElementById('outputEditor');
  const treeView = document.getElementById('treeView');

  if (tabName === 'tree') {
    textarea.style.display = 'none';
    treeView.style.display = 'block';
  } else {
    textarea.style.display = 'block';
    treeView.style.display = 'none';

    if (tabName === 'raw' && currentOutput) {
      // Show minified/raw version
      if (currentOutputFormat === 'json') {
        try {
          textarea.value = JSON.stringify(JSON.parse(currentOutput));
        } catch {
          textarea.value = currentOutput;
        }
      } else {
        textarea.value = currentOutput.replace(/\n/g, '');
      }
    } else if (tabName === 'formatted' && currentOutput) {
      textarea.value = currentOutput;
    }
  }
}

// ============================================================
// UI Actions
// ============================================================

function swapPanels() {
  const inputEditor = document.getElementById('inputEditor');
  const outputEditor = document.getElementById('outputEditor');
  const inputFormat = document.getElementById('inputFormat');
  const outputFormat = document.getElementById('outputFormat');

  // Swap content
  const outputContent = currentOutput || outputEditor.value;
  inputEditor.value = outputContent;

  // Swap formats
  const tmpFormat = inputFormat.value;
  inputFormat.value = outputFormat.value;
  outputFormat.value = tmpFormat;

  // Clear output
  outputEditor.value = '';
  currentOutput = '';
  document.getElementById('treeView').innerHTML = '';

  updatePanelTitles();
  showToast('Eingabe und Ausgabe getauscht', 'info');
}

function clearInput() {
  document.getElementById('inputEditor').value = '';
  document.getElementById('outputEditor').value = '';
  document.getElementById('treeView').innerHTML = '';
  currentOutput = '';
  lastParsedInterchange = null;
  setStatus('ready', 'Bereit');
  document.getElementById('statsText').textContent = 'Keine Daten';
}

function formatInput() {
  const input = document.getElementById('inputEditor').value.trim();
  const format = document.getElementById('inputFormat').value;

  if (!input) return;

  try {
    if (format === 'json') {
      document.getElementById('inputEditor').value = JSON.stringify(JSON.parse(input), null, 2);
    } else if (format === 'xml') {
      // Basic XML formatting
      document.getElementById('inputEditor').value = formatXml(input);
    } else if (format === 'edifact') {
      // Ensure each segment is on its own line
      document.getElementById('inputEditor').value = input.replace(/'/g, "'\n").trim();
    }
    showToast('Eingabe formatiert', 'info');
  } catch (err) {
    showToast('Formatierungsfehler: ' + err.message, 'error');
  }
}

function onFormatChange() {
  updatePanelTitles();
}

function updatePanelTitles() {
  const inputFormat = document.getElementById('inputFormat').value.toUpperCase();
  const outputFormat = document.getElementById('outputFormat').value.toUpperCase();
  document.getElementById('inputPanelTitle').innerHTML = `&#x1F4E5; Eingabe (${inputFormat})`;
  document.getElementById('outputPanelTitle').innerHTML = `&#x1F4E4; Ausgabe (${outputFormat})`;
}

// ============================================================
// File Operations
// ============================================================

function handleFileUpload(event) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (e) => {
    const content = e.target.result;
    document.getElementById('inputEditor').value = content;

    // Auto-detect format
    const trimmed = content.trim();
    if (trimmed.startsWith('UNA') || trimmed.startsWith('UNB')) {
      document.getElementById('inputFormat').value = 'edifact';
    } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      document.getElementById('inputFormat').value = 'json';
    } else if (trimmed.startsWith('<?xml') || trimmed.startsWith('<')) {
      document.getElementById('inputFormat').value = 'xml';
    }

    updatePanelTitles();
    showToast(`Datei "${file.name}" geladen`, 'success');
    setStatus('ready', `Datei geladen: ${file.name}`);
  };
  reader.readAsText(file);

  // Reset file input
  event.target.value = '';
}

function downloadOutput() {
  if (!currentOutput) {
    showToast('Keine Ausgabe zum Speichern vorhanden.', 'error');
    return;
  }

  const format = document.getElementById('outputFormat').value;
  let filename, mimeType;

  switch (format) {
    case 'edifact':
      filename = 'output.edi';
      mimeType = 'application/edifact';
      break;
    case 'json':
      filename = 'output.json';
      mimeType = 'application/json';
      break;
    case 'xml':
      filename = 'output.xml';
      mimeType = 'application/xml';
      break;
    default:
      filename = 'output.txt';
      mimeType = 'text/plain';
  }

  const blob = new Blob([currentOutput], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
  showToast(`Datei "${filename}" gespeichert`, 'success');
}

function copyOutput() {
  if (!currentOutput) {
    showToast('Keine Ausgabe zum Kopieren vorhanden.', 'error');
    return;
  }

  navigator.clipboard.writeText(currentOutput).then(() => {
    showToast('In Zwischenablage kopiert!', 'success');
  }).catch(() => {
    // Fallback
    const textarea = document.getElementById('outputEditor');
    textarea.select();
    document.execCommand('copy');
    showToast('In Zwischenablage kopiert!', 'success');
  });
}

// ============================================================
// Example Loading
// ============================================================

function loadExample() {
  const select = document.getElementById('exampleSelect');
  const key = select.value;
  if (!key || !EXAMPLES[key]) return;

  document.getElementById('inputEditor').value = EXAMPLES[key];
  document.getElementById('inputFormat').value = 'edifact';
  document.getElementById('outputFormat').value = 'json';
  updatePanelTitles();

  select.value = '';
  showToast(`Beispiel "${key.toUpperCase()}" geladen`, 'info');
  setStatus('ready', `Beispiel geladen: ${key.toUpperCase()}`);
}

// ============================================================
// Drag & Drop
// ============================================================

function setupDragAndDrop() {
  const dropZone = document.getElementById('inputDropZone');
  const overlay = document.getElementById('dropOverlay');

  if (!dropZone) return;

  ['dragenter', 'dragover'].forEach(evt => {
    dropZone.addEventListener(evt, (e) => {
      e.preventDefault();
      e.stopPropagation();
      overlay.classList.add('active');
    });
  });

  ['dragleave', 'drop'].forEach(evt => {
    dropZone.addEventListener(evt, (e) => {
      e.preventDefault();
      e.stopPropagation();
      overlay.classList.remove('active');
    });
  });

  dropZone.addEventListener('drop', (e) => {
    const file = e.dataTransfer.files[0];
    if (file) {
      const fakeEvent = { target: { files: [file], value: '' } };
      handleFileUpload(fakeEvent);
    }
  });
}

// ============================================================
// Utilities
// ============================================================

function setStatus(type, message) {
  const dot = document.getElementById('statusDot');
  const text = document.getElementById('statusText');

  dot.className = 'status-dot';
  if (type === 'error') dot.classList.add('error');
  text.textContent = message;
}

function showToast(message, type = 'info') {
  // Remove existing toasts
  document.querySelectorAll('.toast').forEach(t => t.remove());

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  document.body.appendChild(toast);

  setTimeout(() => toast.remove(), 3000);
}

function escapeHtml(str) {
  if (!str) return '';
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

function formatXml(xml) {
  let formatted = '';
  let indent = '';
  const tab = '  ';

  xml.split(/>\s*</).forEach(node => {
    if (node.match(/^\/\w/)) {
      indent = indent.substring(tab.length);
    }
    formatted += indent + '<' + node + '>\n';
    if (node.match(/^<?\w[^>]*[^/]$/) && !node.startsWith('?')) {
      indent += tab;
    }
  });

  return formatted.substring(1, formatted.length - 2);
}

// ============================================================
// Programmatic API (for CLI / external usage)
// ============================================================

/**
 * Global API object for programmatic access
 *
 * Usage from console or other scripts:
 *   EdifactAPI.edifactToJson(edifactString)
 *   EdifactAPI.edifactToXml(edifactString)
 *   EdifactAPI.jsonToEdifact(jsonObject)
 *   EdifactAPI.xmlToJson(xmlString)
 */
const EdifactAPI = {
  /**
   * Convert EDIFACT string to JSON object
   */
  edifactToJson(edifactStr) {
    const parser = new EdifactParser();
    return parser.parse(edifactStr);
  },

  /**
   * Convert EDIFACT string to JSON string
   */
  edifactToJsonString(edifactStr, indent = 2) {
    return JSON.stringify(this.edifactToJson(edifactStr), null, indent);
  },

  /**
   * Convert EDIFACT string to XML string
   */
  edifactToXml(edifactStr) {
    const json = this.edifactToJson(edifactStr);
    return XmlConverter.jsonToXml(json);
  },

  /**
   * Convert JSON object to EDIFACT string
   */
  jsonToEdifact(jsonObj, options = {}) {
    const generator = new EdifactGenerator(options);
    return generator.generate(jsonObj);
  },

  /**
   * Convert JSON string to EDIFACT string
   */
  jsonStringToEdifact(jsonStr, options = {}) {
    const obj = JSON.parse(jsonStr);
    return this.jsonToEdifact(obj, options);
  },

  /**
   * Convert XML string to JSON object
   */
  xmlToJson(xmlStr) {
    return XmlConverter.xmlToJson(xmlStr);
  },

  /**
   * Convert XML string to EDIFACT string
   */
  xmlToEdifact(xmlStr, options = {}) {
    const json = this.xmlToJson(xmlStr);
    return this.jsonToEdifact(json, options);
  },

  /**
   * Convert JSON object to XML string
   */
  jsonToXml(jsonObj) {
    return XmlConverter.jsonToXml(jsonObj);
  },

  /**
   * Generate EDIFACT from a simplified template
   */
  generateFromTemplate(template) {
    const generator = new EdifactGenerator();
    return generator.generateFromTemplate(template);
  },

  /**
   * Get available message type schemas
   */
  getSchemas() {
    return EdifactSchemas.getSupportedTypes();
  },

  /**
   * Validate an EDIFACT string (parse and check for errors)
   */
  validate(edifactStr) {
    try {
      const parser = new EdifactParser({ strictMode: true });
      const result = parser.parse(edifactStr);
      const messages = [
        ...(result.messages || []),
        ...(result.groups || []).flatMap(g => g.messages || [])
      ];
      return {
        valid: true,
        messageCount: messages.length,
        messageTypes: messages.map(m => m.header?.messageIdentifier?.type),
        segmentCount: messages.reduce((sum, m) => sum + (m.segments?.length || 0), 0)
      };
    } catch (err) {
      return { valid: false, error: err.message };
    }
  }
};

// Make API globally available
if (typeof window !== 'undefined') {
  window.EdifactAPI = EdifactAPI;
}
