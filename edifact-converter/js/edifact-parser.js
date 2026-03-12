/**
 * EDIFACT Parser - Parses EDIFACT messages into structured JSON
 * Supports UN/EDIFACT syntax versions 3 and 4
 *
 * Usage:
 *   const parser = new EdifactParser();
 *   const result = parser.parse(edifactString);
 */
class EdifactParser {
  constructor(options = {}) {
    this.options = {
      strictMode: options.strictMode || false,
      charset: options.charset || 'UNOC',
      ...options
    };

    // Default EDIFACT delimiters (can be overridden by UNA segment)
    this.delimiters = {
      componentSeparator: ':',
      dataSeparator: '+',
      decimalNotation: '.',
      escapeCharacter: '?',
      reserved: ' ',
      segmentTerminator: "'"
    };
  }

  /**
   * Parse a complete EDIFACT interchange
   * @param {string} raw - Raw EDIFACT string
   * @returns {object} Parsed interchange object
   */
  parse(raw) {
    if (!raw || typeof raw !== 'string') {
      throw new EdifactParseError('Input must be a non-empty string');
    }

    // Normalize line endings
    let input = raw.replace(/\r\n/g, '').replace(/\r/g, '').replace(/\n/g, '');

    // Check for and parse UNA segment (Service String Advice)
    if (input.startsWith('UNA')) {
      this.parseUNA(input.substring(3, 9));
      input = input.substring(9).trim();
    }

    const segments = this.tokenizeSegments(input);

    if (segments.length === 0) {
      throw new EdifactParseError('No segments found in input');
    }

    return this.buildInterchange(segments);
  }

  /**
   * Parse UNA segment to extract custom delimiters
   */
  parseUNA(unaChars) {
    if (unaChars.length !== 6) {
      throw new EdifactParseError('Invalid UNA segment: must be exactly 6 characters');
    }
    this.delimiters = {
      componentSeparator: unaChars[0],
      dataSeparator: unaChars[1],
      decimalNotation: unaChars[2],
      escapeCharacter: unaChars[3],
      reserved: unaChars[4],
      segmentTerminator: unaChars[5]
    };
  }

  /**
   * Split raw input into segment strings
   */
  tokenizeSegments(input) {
    const terminator = this.delimiters.segmentTerminator;
    const escape = this.delimiters.escapeCharacter;
    const segments = [];
    let current = '';

    for (let i = 0; i < input.length; i++) {
      const char = input[i];

      // Handle escape character
      if (char === escape && i + 1 < input.length) {
        current += char + input[i + 1];
        i++;
        continue;
      }

      if (char === terminator) {
        const trimmed = current.trim();
        if (trimmed.length > 0) {
          segments.push(trimmed);
        }
        current = '';
      } else {
        current += char;
      }
    }

    // Handle remaining content (segment without terminator)
    const trimmed = current.trim();
    if (trimmed.length > 0) {
      segments.push(trimmed);
    }

    return segments;
  }

  /**
   * Parse a single segment string into tag + elements
   */
  parseSegment(segmentStr) {
    const dataSep = this.delimiters.dataSeparator;
    const compSep = this.delimiters.componentSeparator;
    const escape = this.delimiters.escapeCharacter;

    const elements = this.splitWithEscape(segmentStr, dataSep, escape);
    const tag = elements.shift();

    const parsedElements = elements.map(element => {
      const components = this.splitWithEscape(element, compSep, escape);
      // Unescape all components
      return components.map(c => this.unescape(c));
    });

    return { tag, elements: parsedElements };
  }

  /**
   * Split string by delimiter, respecting escape character
   */
  splitWithEscape(str, delimiter, escape) {
    const parts = [];
    let current = '';

    for (let i = 0; i < str.length; i++) {
      const char = str[i];

      if (char === escape && i + 1 < str.length) {
        current += char + str[i + 1];
        i++;
        continue;
      }

      if (char === delimiter) {
        parts.push(current);
        current = '';
      } else {
        current += char;
      }
    }

    parts.push(current);
    return parts;
  }

  /**
   * Remove escape characters from a string
   */
  unescape(str) {
    const escape = this.delimiters.escapeCharacter;
    let result = '';
    for (let i = 0; i < str.length; i++) {
      if (str[i] === escape && i + 1 < str.length) {
        result += str[i + 1];
        i++;
      } else {
        result += str[i];
      }
    }
    return result;
  }

  /**
   * Build structured interchange from parsed segments
   */
  buildInterchange(segmentStrings) {
    const segments = segmentStrings.map(s => this.parseSegment(s));
    let idx = 0;

    const interchange = {
      delimiters: { ...this.delimiters },
      header: null,
      groups: [],
      messages: [],
      trailer: null
    };

    // Parse UNB (Interchange Header)
    if (segments[idx] && segments[idx].tag === 'UNB') {
      interchange.header = this.parseUNB(segments[idx]);
      idx++;
    } else if (this.options.strictMode) {
      throw new EdifactParseError('Missing UNB interchange header');
    }

    // Parse functional groups and messages
    while (idx < segments.length) {
      const seg = segments[idx];

      if (seg.tag === 'UNG') {
        // Functional Group
        const group = this.parseFunctionalGroup(segments, idx);
        interchange.groups.push(group.group);
        idx = group.nextIndex;
      } else if (seg.tag === 'UNH') {
        // Message (without group)
        const msg = this.parseMessage(segments, idx);
        interchange.messages.push(msg.message);
        idx = msg.nextIndex;
      } else if (seg.tag === 'UNZ') {
        // Interchange Trailer
        interchange.trailer = this.parseUNZ(seg);
        idx++;
      } else {
        idx++;
      }
    }

    return interchange;
  }

  /**
   * Parse UNB (Interchange Header) segment
   */
  parseUNB(segment) {
    const e = segment.elements;
    return {
      syntaxIdentifier: {
        id: this.getComponent(e, 0, 0),
        version: this.getComponent(e, 0, 1)
      },
      sender: {
        id: this.getComponent(e, 1, 0),
        qualifier: this.getComponent(e, 1, 1),
        routingAddress: this.getComponent(e, 1, 2)
      },
      recipient: {
        id: this.getComponent(e, 2, 0),
        qualifier: this.getComponent(e, 2, 1),
        routingAddress: this.getComponent(e, 2, 2)
      },
      dateTime: {
        date: this.getComponent(e, 3, 0),
        time: this.getComponent(e, 3, 1)
      },
      controlReference: this.getComponent(e, 4, 0),
      recipientReference: this.getComponent(e, 5, 0),
      applicationReference: this.getComponent(e, 6, 0),
      processingPriority: this.getComponent(e, 7, 0),
      acknowledgementRequest: this.getComponent(e, 8, 0),
      agreementId: this.getComponent(e, 9, 0),
      testIndicator: this.getComponent(e, 10, 0)
    };
  }

  /**
   * Parse UNZ (Interchange Trailer) segment
   */
  parseUNZ(segment) {
    const e = segment.elements;
    return {
      controlCount: this.getComponent(e, 0, 0),
      controlReference: this.getComponent(e, 1, 0)
    };
  }

  /**
   * Parse a functional group (UNG...UNE)
   */
  parseFunctionalGroup(segments, startIdx) {
    let idx = startIdx;
    const ungSeg = segments[idx];
    idx++;

    const group = {
      header: {
        groupId: this.getComponent(ungSeg.elements, 0, 0),
        sender: this.getComponent(ungSeg.elements, 1, 0),
        recipient: this.getComponent(ungSeg.elements, 2, 0),
        dateTime: {
          date: this.getComponent(ungSeg.elements, 3, 0),
          time: this.getComponent(ungSeg.elements, 3, 1)
        },
        controlReference: this.getComponent(ungSeg.elements, 4, 0),
        controllingAgency: this.getComponent(ungSeg.elements, 5, 0),
        messageVersion: {
          version: this.getComponent(ungSeg.elements, 6, 0),
          release: this.getComponent(ungSeg.elements, 6, 1)
        }
      },
      messages: [],
      trailer: null
    };

    while (idx < segments.length) {
      const seg = segments[idx];
      if (seg.tag === 'UNH') {
        const msg = this.parseMessage(segments, idx);
        group.messages.push(msg.message);
        idx = msg.nextIndex;
      } else if (seg.tag === 'UNE') {
        group.trailer = {
          controlCount: this.getComponent(seg.elements, 0, 0),
          controlReference: this.getComponent(seg.elements, 1, 0)
        };
        idx++;
        break;
      } else {
        idx++;
      }
    }

    return { group, nextIndex: idx };
  }

  /**
   * Parse a message (UNH...UNT)
   */
  parseMessage(segments, startIdx) {
    let idx = startIdx;
    const unhSeg = segments[idx];
    idx++;

    const message = {
      header: {
        referenceNumber: this.getComponent(unhSeg.elements, 0, 0),
        messageIdentifier: {
          type: this.getComponent(unhSeg.elements, 1, 0),
          version: this.getComponent(unhSeg.elements, 1, 1),
          release: this.getComponent(unhSeg.elements, 1, 2),
          controllingAgency: this.getComponent(unhSeg.elements, 1, 3),
          associationCode: this.getComponent(unhSeg.elements, 1, 4)
        }
      },
      segments: [],
      trailer: null
    };

    while (idx < segments.length) {
      const seg = segments[idx];
      if (seg.tag === 'UNT') {
        message.trailer = {
          segmentCount: this.getComponent(seg.elements, 0, 0),
          referenceNumber: this.getComponent(seg.elements, 1, 0)
        };
        idx++;
        break;
      } else if (seg.tag === 'UNH' || seg.tag === 'UNZ' || seg.tag === 'UNE') {
        break;
      } else {
        message.segments.push({
          tag: seg.tag,
          elements: seg.elements
        });
        idx++;
      }
    }

    return { message, nextIndex: idx };
  }

  /**
   * Safely get a component from nested elements array
   */
  getComponent(elements, elementIdx, componentIdx) {
    if (!elements || elementIdx >= elements.length) return '';
    const element = elements[elementIdx];
    if (!element || componentIdx >= element.length) return '';
    return element[componentIdx] || '';
  }
}

/**
 * Custom error class for parse errors
 */
class EdifactParseError extends Error {
  constructor(message, position) {
    super(message);
    this.name = 'EdifactParseError';
    this.position = position;
  }
}

// Export for Node.js / module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { EdifactParser, EdifactParseError };
}
