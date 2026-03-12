/**
 * EDIFACT Message Type Schema Definitions
 * Provides human-readable labels and structure for common message types
 */
const EdifactSchemas = {

  // Segment tag descriptions
  segmentNames: {
    // Service segments
    UNA: 'Service String Advice',
    UNB: 'Interchange Header',
    UNZ: 'Interchange Trailer',
    UNG: 'Functional Group Header',
    UNE: 'Functional Group Trailer',
    UNH: 'Message Header',
    UNT: 'Message Trailer',
    UNS: 'Section Control',

    // Common segments
    BGM: 'Beginning of Message',
    DTM: 'Date/Time/Period',
    PAI: 'Payment Instructions',
    ALI: 'Additional Information',
    FTX: 'Free Text',
    RFF: 'Reference',
    NAD: 'Name and Address',
    CTA: 'Contact Information',
    COM: 'Communication Contact',
    TAX: 'Duty/Tax/Fee Details',
    CUX: 'Currencies',
    PAT: 'Payment Terms Basis',
    TDT: 'Transport Information',
    TOD: 'Terms of Delivery',
    LOC: 'Place/Location Identification',
    MOA: 'Monetary Amount',
    LIN: 'Line Item',
    PIA: 'Additional Product Id',
    IMD: 'Item Description',
    QTY: 'Quantity',
    MEA: 'Measurements',
    GIR: 'Related Identification Numbers',
    PRI: 'Price Details',
    ALC: 'Allowance or Charge',
    PCD: 'Percentage Details',
    RTE: 'Rate Details',
    CNT: 'Control Total',
    CPS: 'Consignment Packing Sequence',
    PAC: 'Package',
    PCI: 'Package Identification',
    GIN: 'Goods Identity Number',
    SCC: 'Scheduling Conditions',
    QVR: 'Quantity Variances',
    EQD: 'Equipment Details',
    SEL: 'Seal Number',
    DOC: 'Document/Message Details',
    STS: 'Status',
    IDE: 'Identity',
    GIS: 'General Indicator',
    PYT: 'Payment Terms',
    IRQ: 'Information Required',
    HAN: 'Handling Instructions'
  },

  // Message type definitions
  messageTypes: {
    ORDERS: {
      name: 'Purchase Order',
      description: 'Bestellung / Purchase Order Message',
      segments: {
        BGM: {
          label: 'Bestellkopf',
          elements: [
            { name: 'documentCode', label: 'Dokumentencode', codes: { '220': 'Order', '221': 'Blanket Order', '224': 'Rush Order', '226': 'Call Off Order', '228': 'Consignment Order', '245': 'Release Order' } },
            { name: 'documentNumber', label: 'Bestellnummer' },
            { name: 'messageFunction', label: 'Nachrichtenfunktion', codes: { '9': 'Original', '1': 'Cancellation', '5': 'Replacement', '31': 'Copy' } }
          ]
        },
        DTM: {
          label: 'Datum/Zeit',
          elements: [
            { name: 'qualifier', label: 'Qualifier', codes: { '137': 'Document date', '2': 'Delivery date requested', '63': 'Delivery latest', '64': 'Delivery earliest', '171': 'Reference date' } },
            { name: 'value', label: 'Datum' },
            { name: 'format', label: 'Format', codes: { '102': 'CCYYMMDD', '203': 'CCYYMMDDHHMM', '718': 'CCYYMMDD-CCYYMMDD' } }
          ]
        },
        NAD: {
          label: 'Name und Adresse',
          elements: [
            { name: 'qualifier', label: 'Parteiqualifier', codes: { 'BY': 'Buyer', 'SE': 'Seller', 'SU': 'Supplier', 'DP': 'Delivery party', 'IV': 'Invoicee', 'ST': 'Ship to', 'SF': 'Ship from' } },
            { name: 'partyId', label: 'Partei-ID' },
            { name: 'codeListQualifier', label: 'Code-Liste' },
            { name: 'codeListAgency', label: 'Agentur' },
            { name: 'name', label: 'Name' },
            { name: 'street', label: 'Strasse' },
            { name: 'city', label: 'Stadt' },
            { name: 'region', label: 'Region' },
            { name: 'postalCode', label: 'PLZ' },
            { name: 'country', label: 'Land' }
          ]
        },
        LIN: {
          label: 'Positionszeile',
          elements: [
            { name: 'lineNumber', label: 'Positionsnummer' },
            { name: 'actionCode', label: 'Aktionscode' },
            { name: 'itemNumber', label: 'Artikelnummer' },
            { name: 'itemNumberType', label: 'Nummerntyp', codes: { 'EN': 'EAN', 'SA': 'Supplier article', 'BP': 'Buyer product', 'SRV': 'Service code', 'UP': 'UPC' } }
          ]
        },
        QTY: {
          label: 'Menge',
          elements: [
            { name: 'qualifier', label: 'Qualifier', codes: { '21': 'Ordered quantity', '47': 'Invoiced quantity', '12': 'Despatch quantity', '192': 'Free goods' } },
            { name: 'quantity', label: 'Menge' },
            { name: 'unit', label: 'Einheit', codes: { 'PCE': 'Piece', 'KGM': 'Kilogram', 'MTR': 'Metre', 'LTR': 'Litre', 'EA': 'Each', 'SET': 'Set', 'CT': 'Carton' } }
          ]
        },
        PRI: {
          label: 'Preis',
          elements: [
            { name: 'qualifier', label: 'Preisqualifier', codes: { 'AAA': 'Calculation net', 'AAB': 'Calculation gross', 'AAE': 'Information price' } },
            { name: 'price', label: 'Preis' },
            { name: 'priceType', label: 'Preistyp' },
            { name: 'priceBase', label: 'Preisbasis' },
            { name: 'unitOfMeasure', label: 'Einheit' }
          ]
        },
        MOA: {
          label: 'Geldbetrag',
          elements: [
            { name: 'qualifier', label: 'Qualifier', codes: { '9': 'Order amount', '66': 'Goods item total', '79': 'Total line amount', '86': 'Message total', '128': 'Tax amount', '203': 'Line item amount' } },
            { name: 'amount', label: 'Betrag' },
            { name: 'currency', label: 'Waehrung' }
          ]
        },
        TAX: {
          label: 'Steuer',
          elements: [
            { name: 'functionQualifier', label: 'Funktion', codes: { '7': 'Tax' } },
            { name: 'taxType', label: 'Steuertyp', codes: { 'VAT': 'Value Added Tax' } },
            { name: 'taxCategory', label: 'Kategorie' },
            { name: 'taxRate', label: 'Steuersatz' }
          ]
        },
        RFF: {
          label: 'Referenz',
          elements: [
            { name: 'qualifier', label: 'Qualifier', codes: { 'ON': 'Order number', 'CT': 'Contract number', 'IV': 'Invoice number', 'DQ': 'Delivery note', 'VN': 'Vendor number', 'ACD': 'Additional reference', 'CR': 'Customer reference', 'AAK': 'Despatch advice number' } },
            { name: 'referenceNumber', label: 'Referenznummer' }
          ]
        }
      }
    },

    INVOIC: {
      name: 'Invoice',
      description: 'Rechnung / Invoice Message',
      segments: {
        BGM: {
          label: 'Rechnungskopf',
          elements: [
            { name: 'documentCode', label: 'Dokumentencode', codes: { '380': 'Commercial invoice', '381': 'Credit note', '383': 'Debit note', '386': 'Prepayment invoice', '389': 'Self-billed invoice' } },
            { name: 'documentNumber', label: 'Rechnungsnummer' },
            { name: 'messageFunction', label: 'Nachrichtenfunktion', codes: { '9': 'Original', '1': 'Cancellation', '31': 'Copy' } }
          ]
        },
        DTM: {
          label: 'Datum/Zeit',
          elements: [
            { name: 'qualifier', label: 'Qualifier', codes: { '137': 'Document date', '35': 'Delivery date', '131': 'Tax point date', '140': 'Payment due date', '171': 'Reference date' } },
            { name: 'value', label: 'Datum' },
            { name: 'format', label: 'Format' }
          ]
        }
      }
    },

    DESADV: {
      name: 'Despatch Advice',
      description: 'Lieferavis / Despatch Advice Message',
      segments: {
        BGM: {
          label: 'Lieferavis-Kopf',
          elements: [
            { name: 'documentCode', label: 'Dokumentencode', codes: { '351': 'Despatch advice' } },
            { name: 'documentNumber', label: 'Lieferavisnummer' },
            { name: 'messageFunction', label: 'Nachrichtenfunktion', codes: { '9': 'Original' } }
          ]
        },
        CPS: {
          label: 'Packsequenz',
          elements: [
            { name: 'hierarchyId', label: 'Hierarchie-ID' },
            { name: 'parentId', label: 'Parent-ID' },
            { name: 'packagingLevel', label: 'Verpackungsebene', codes: { '1': 'Inner', '2': 'Intermediate', '3': 'Outer', '4': 'No packaging hierarchy' } }
          ]
        },
        PAC: {
          label: 'Verpackung',
          elements: [
            { name: 'numberOfPackages', label: 'Anzahl Packstücke' },
            { name: 'packagingDetails', label: 'Verpackungsdetails' },
            { name: 'packageType', label: 'Verpackungsart', codes: { 'CT': 'Carton', 'PK': 'Package', 'PX': 'Pallet', 'BX': 'Box' } }
          ]
        }
      }
    },

    PRICAT: {
      name: 'Price/Sales Catalogue',
      description: 'Preis-/Verkaufskatalog / Price Catalogue Message',
      segments: {
        BGM: {
          label: 'Katalogkopf',
          elements: [
            { name: 'documentCode', label: 'Dokumentencode', codes: { '9': 'Price/sales catalogue' } },
            { name: 'documentNumber', label: 'Katalognummer' },
            { name: 'messageFunction', label: 'Nachrichtenfunktion' }
          ]
        }
      }
    },

    ORDRSP: {
      name: 'Purchase Order Response',
      description: 'Bestellbestätigung / Order Response Message',
      segments: {
        BGM: {
          label: 'Bestellbestätigungskopf',
          elements: [
            { name: 'documentCode', label: 'Dokumentencode', codes: { '231': 'Order response' } },
            { name: 'documentNumber', label: 'Bestätigungsnummer' },
            { name: 'messageFunction', label: 'Nachrichtenfunktion', codes: { '9': 'Original', '4': 'Change', '27': 'Not accepted', '29': 'Accepted with amendment' } }
          ]
        }
      }
    }
  },

  /**
   * Get human-readable name for a segment tag
   */
  getSegmentName(tag) {
    return this.segmentNames[tag] || tag;
  },

  /**
   * Get schema for a specific message type
   */
  getMessageSchema(type) {
    return this.messageTypes[type.toUpperCase()] || null;
  },

  /**
   * Resolve a code value to its description
   */
  resolveCode(messageType, segmentTag, elementIdx, code) {
    const schema = this.getMessageSchema(messageType);
    if (!schema || !schema.segments[segmentTag]) return code;
    const elementDef = schema.segments[segmentTag].elements[elementIdx];
    if (!elementDef || !elementDef.codes) return code;
    return elementDef.codes[code] || code;
  },

  /**
   * Get all supported message types
   */
  getSupportedTypes() {
    return Object.keys(this.messageTypes).map(key => ({
      code: key,
      name: this.messageTypes[key].name,
      description: this.messageTypes[key].description
    }));
  }
};

// Export for Node.js / module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { EdifactSchemas };
}
