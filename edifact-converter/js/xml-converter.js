/**
 * XML Converter - Bidirectional conversion between JSON and XML
 * for EDIFACT interchange data
 */
class XmlConverter {

  /**
   * Convert parsed EDIFACT JSON to XML string
   * @param {object} interchange - Parsed interchange object
   * @param {object} options - Formatting options
   * @returns {string} XML string
   */
  static jsonToXml(interchange, options = {}) {
    const indent = options.indent || '  ';
    const lines = [];

    lines.push('<?xml version="1.0" encoding="UTF-8"?>');
    lines.push('<EDIFACT_Interchange>');

    // Delimiters
    if (interchange.delimiters) {
      lines.push(`${indent}<Delimiters>`);
      for (const [key, val] of Object.entries(interchange.delimiters)) {
        lines.push(`${indent}${indent}<${key}>${XmlConverter.escapeXml(val)}</${key}>`);
      }
      lines.push(`${indent}</Delimiters>`);
    }

    // Header (UNB)
    if (interchange.header) {
      lines.push(`${indent}<InterchangeHeader>`);
      lines.push(...XmlConverter.objectToXmlLines(interchange.header, indent, 2));
      lines.push(`${indent}</InterchangeHeader>`);
    }

    // Functional Groups
    if (interchange.groups && interchange.groups.length > 0) {
      lines.push(`${indent}<FunctionalGroups>`);
      for (const group of interchange.groups) {
        lines.push(`${indent}${indent}<Group>`);
        if (group.header) {
          lines.push(`${indent}${indent}${indent}<GroupHeader>`);
          lines.push(...XmlConverter.objectToXmlLines(group.header, indent, 4));
          lines.push(`${indent}${indent}${indent}</GroupHeader>`);
        }
        if (group.messages) {
          for (const msg of group.messages) {
            lines.push(...XmlConverter.messageToXml(msg, indent, 3));
          }
        }
        if (group.trailer) {
          lines.push(`${indent}${indent}${indent}<GroupTrailer>`);
          lines.push(...XmlConverter.objectToXmlLines(group.trailer, indent, 4));
          lines.push(`${indent}${indent}${indent}</GroupTrailer>`);
        }
        lines.push(`${indent}${indent}</Group>`);
      }
      lines.push(`${indent}</FunctionalGroups>`);
    }

    // Messages (outside groups)
    if (interchange.messages && interchange.messages.length > 0) {
      lines.push(`${indent}<Messages>`);
      for (const msg of interchange.messages) {
        lines.push(...XmlConverter.messageToXml(msg, indent, 2));
      }
      lines.push(`${indent}</Messages>`);
    }

    // Trailer (UNZ)
    if (interchange.trailer) {
      lines.push(`${indent}<InterchangeTrailer>`);
      lines.push(...XmlConverter.objectToXmlLines(interchange.trailer, indent, 2));
      lines.push(`${indent}</InterchangeTrailer>`);
    }

    lines.push('</EDIFACT_Interchange>');
    return lines.join('\n');
  }

  /**
   * Convert a message to XML lines
   */
  static messageToXml(message, indent, depth) {
    const prefix = indent.repeat(depth);
    const lines = [];

    lines.push(`${prefix}<Message>`);

    // Header
    if (message.header) {
      lines.push(`${prefix}${indent}<MessageHeader>`);
      lines.push(...XmlConverter.objectToXmlLines(message.header, indent, depth + 2));
      lines.push(`${prefix}${indent}</MessageHeader>`);
    }

    // Segments
    if (message.segments && message.segments.length > 0) {
      lines.push(`${prefix}${indent}<Segments>`);
      for (const seg of message.segments) {
        const segName = EdifactSchemas ? EdifactSchemas.getSegmentName(seg.tag) : seg.tag;
        lines.push(`${prefix}${indent}${indent}<Segment tag="${XmlConverter.escapeXml(seg.tag)}" name="${XmlConverter.escapeXml(segName)}">`);
        if (seg.elements) {
          for (let i = 0; i < seg.elements.length; i++) {
            const element = seg.elements[i];
            lines.push(`${prefix}${indent}${indent}${indent}<Element index="${i}">`);
            if (Array.isArray(element)) {
              for (let j = 0; j < element.length; j++) {
                if (element[j]) {
                  lines.push(`${prefix}${indent}${indent}${indent}${indent}<Component index="${j}">${XmlConverter.escapeXml(element[j])}</Component>`);
                }
              }
            } else {
              lines.push(`${prefix}${indent}${indent}${indent}${indent}<Value>${XmlConverter.escapeXml(String(element))}</Value>`);
            }
            lines.push(`${prefix}${indent}${indent}${indent}</Element>`);
          }
        }
        lines.push(`${prefix}${indent}${indent}</Segment>`);
      }
      lines.push(`${prefix}${indent}</Segments>`);
    }

    // Trailer
    if (message.trailer) {
      lines.push(`${prefix}${indent}<MessageTrailer>`);
      lines.push(...XmlConverter.objectToXmlLines(message.trailer, indent, depth + 2));
      lines.push(`${prefix}${indent}</MessageTrailer>`);
    }

    lines.push(`${prefix}</Message>`);
    return lines;
  }

  /**
   * Convert a plain object to XML lines
   */
  static objectToXmlLines(obj, indent, depth) {
    const prefix = indent.repeat(depth);
    const lines = [];

    for (const [key, val] of Object.entries(obj)) {
      if (val === null || val === undefined || val === '') continue;

      if (typeof val === 'object' && !Array.isArray(val)) {
        lines.push(`${prefix}<${key}>`);
        lines.push(...XmlConverter.objectToXmlLines(val, indent, depth + 1));
        lines.push(`${prefix}</${key}>`);
      } else if (Array.isArray(val)) {
        lines.push(`${prefix}<${key}>`);
        for (let i = 0; i < val.length; i++) {
          if (typeof val[i] === 'object') {
            lines.push(`${prefix}${indent}<Item index="${i}">`);
            lines.push(...XmlConverter.objectToXmlLines(val[i], indent, depth + 2));
            lines.push(`${prefix}${indent}</Item>`);
          } else {
            lines.push(`${prefix}${indent}<Item index="${i}">${XmlConverter.escapeXml(String(val[i]))}</Item>`);
          }
        }
        lines.push(`${prefix}</${key}>`);
      } else {
        lines.push(`${prefix}<${key}>${XmlConverter.escapeXml(String(val))}</${key}>`);
      }
    }

    return lines;
  }

  /**
   * Parse XML string back to EDIFACT JSON structure
   * @param {string} xmlString - XML string
   * @returns {object} Parsed interchange object
   */
  static xmlToJson(xmlString) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(xmlString, 'text/xml');

    const errorNode = doc.querySelector('parsererror');
    if (errorNode) {
      throw new Error('XML Parse Error: ' + errorNode.textContent);
    }

    const root = doc.documentElement;
    if (root.tagName !== 'EDIFACT_Interchange') {
      throw new Error('Root element must be EDIFACT_Interchange');
    }

    const interchange = {
      delimiters: null,
      header: null,
      groups: [],
      messages: [],
      trailer: null
    };

    // Parse Delimiters
    const delimNode = root.querySelector(':scope > Delimiters');
    if (delimNode) {
      interchange.delimiters = {};
      for (const child of delimNode.children) {
        interchange.delimiters[child.tagName] = child.textContent;
      }
    }

    // Parse InterchangeHeader
    const headerNode = root.querySelector(':scope > InterchangeHeader');
    if (headerNode) {
      interchange.header = XmlConverter.xmlNodeToObject(headerNode);
    }

    // Parse Messages
    const messagesNode = root.querySelector(':scope > Messages');
    if (messagesNode) {
      for (const msgNode of messagesNode.querySelectorAll(':scope > Message')) {
        interchange.messages.push(XmlConverter.xmlMessageToJson(msgNode));
      }
    }

    // Parse FunctionalGroups
    const groupsNode = root.querySelector(':scope > FunctionalGroups');
    if (groupsNode) {
      for (const groupNode of groupsNode.querySelectorAll(':scope > Group')) {
        const group = { header: null, messages: [], trailer: null };
        const gh = groupNode.querySelector(':scope > GroupHeader');
        if (gh) group.header = XmlConverter.xmlNodeToObject(gh);
        for (const msgNode of groupNode.querySelectorAll(':scope > Message')) {
          group.messages.push(XmlConverter.xmlMessageToJson(msgNode));
        }
        const gt = groupNode.querySelector(':scope > GroupTrailer');
        if (gt) group.trailer = XmlConverter.xmlNodeToObject(gt);
        interchange.groups.push(group);
      }
    }

    // Parse InterchangeTrailer
    const trailerNode = root.querySelector(':scope > InterchangeTrailer');
    if (trailerNode) {
      interchange.trailer = XmlConverter.xmlNodeToObject(trailerNode);
    }

    return interchange;
  }

  /**
   * Convert an XML Message node back to JSON message
   */
  static xmlMessageToJson(msgNode) {
    const message = { header: null, segments: [], trailer: null };

    const headerNode = msgNode.querySelector(':scope > MessageHeader');
    if (headerNode) {
      message.header = XmlConverter.xmlNodeToObject(headerNode);
    }

    const segmentsNode = msgNode.querySelector(':scope > Segments');
    if (segmentsNode) {
      for (const segNode of segmentsNode.querySelectorAll(':scope > Segment')) {
        const tag = segNode.getAttribute('tag');
        const elements = [];

        for (const elNode of segNode.querySelectorAll(':scope > Element')) {
          const components = [];
          const valueNode = elNode.querySelector(':scope > Value');
          if (valueNode) {
            components.push(valueNode.textContent);
          } else {
            for (const compNode of elNode.querySelectorAll(':scope > Component')) {
              const idx = parseInt(compNode.getAttribute('index') || '0');
              while (components.length <= idx) components.push('');
              components[idx] = compNode.textContent;
            }
          }
          elements.push(components);
        }

        message.segments.push({ tag, elements });
      }
    }

    const trailerNode = msgNode.querySelector(':scope > MessageTrailer');
    if (trailerNode) {
      message.trailer = XmlConverter.xmlNodeToObject(trailerNode);
    }

    return message;
  }

  /**
   * Generic XML node to object conversion
   */
  static xmlNodeToObject(node) {
    const obj = {};
    for (const child of node.children) {
      if (child.children.length > 0 && !child.querySelector(':scope > Item')) {
        obj[child.tagName] = XmlConverter.xmlNodeToObject(child);
      } else if (child.querySelector(':scope > Item')) {
        obj[child.tagName] = [];
        for (const item of child.querySelectorAll(':scope > Item')) {
          if (item.children.length > 0) {
            obj[child.tagName].push(XmlConverter.xmlNodeToObject(item));
          } else {
            obj[child.tagName].push(item.textContent);
          }
        }
      } else {
        obj[child.tagName] = child.textContent;
      }
    }
    return obj;
  }

  /**
   * Escape special XML characters
   */
  static escapeXml(str) {
    if (!str) return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}

// Export for Node.js / module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { XmlConverter };
}
