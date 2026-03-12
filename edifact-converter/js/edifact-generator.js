/**
 * EDIFACT Generator - Generates EDIFACT messages from structured JSON
 *
 * Usage:
 *   const generator = new EdifactGenerator();
 *   const edifact = generator.generate(jsonObject);
 */
class EdifactGenerator {
  constructor(options = {}) {
    this.options = {
      lineBreaks: options.lineBreaks !== undefined ? options.lineBreaks : true,
      includeUNA: options.includeUNA !== undefined ? options.includeUNA : true,
      ...options
    };

    this.delimiters = {
      componentSeparator: options.componentSeparator || ':',
      dataSeparator: options.dataSeparator || '+',
      decimalNotation: options.decimalNotation || '.',
      escapeCharacter: options.escapeCharacter || '?',
      reserved: options.reserved || ' ',
      segmentTerminator: options.segmentTerminator || "'"
    };
  }

  /**
   * Generate a complete EDIFACT interchange from JSON
   * @param {object} interchange - Structured interchange object
   * @returns {string} EDIFACT formatted string
   */
  generate(interchange) {
    if (!interchange) {
      throw new Error('Interchange object is required');
    }

    const segments = [];
    const lineBreak = this.options.lineBreaks ? '\n' : '';

    // UNA segment
    if (this.options.includeUNA) {
      const d = interchange.delimiters || this.delimiters;
      segments.push('UNA' + d.componentSeparator + d.dataSeparator +
        d.decimalNotation + d.escapeCharacter + d.reserved + d.segmentTerminator);
    }

    // Use interchange delimiters if provided
    if (interchange.delimiters) {
      this.delimiters = { ...this.delimiters, ...interchange.delimiters };
    }

    // UNB segment
    if (interchange.header) {
      segments.push(this.generateUNB(interchange.header));
    }

    // Functional groups
    if (interchange.groups && interchange.groups.length > 0) {
      for (const group of interchange.groups) {
        segments.push(...this.generateFunctionalGroup(group));
      }
    }

    // Messages (without groups)
    if (interchange.messages && interchange.messages.length > 0) {
      for (const message of interchange.messages) {
        segments.push(...this.generateMessage(message));
      }
    }

    // UNZ segment
    if (interchange.trailer) {
      segments.push(this.generateUNZ(interchange.trailer));
    }

    return segments.join(lineBreak);
  }

  /**
   * Generate UNB (Interchange Header) segment
   */
  generateUNB(header) {
    const elements = [];

    // Syntax identifier
    elements.push(this.buildElement([
      header.syntaxIdentifier?.id || 'UNOC',
      header.syntaxIdentifier?.version || '3'
    ]));

    // Sender
    elements.push(this.buildElement([
      header.sender?.id || '',
      header.sender?.qualifier || '',
      header.sender?.routingAddress || ''
    ]));

    // Recipient
    elements.push(this.buildElement([
      header.recipient?.id || '',
      header.recipient?.qualifier || '',
      header.recipient?.routingAddress || ''
    ]));

    // Date/Time
    elements.push(this.buildElement([
      header.dateTime?.date || '',
      header.dateTime?.time || ''
    ]));

    // Control reference
    elements.push(header.controlReference || '');

    // Optional fields
    if (header.recipientReference) elements.push(header.recipientReference);
    if (header.applicationReference) elements.push(header.applicationReference);
    if (header.processingPriority) elements.push(header.processingPriority);
    if (header.acknowledgementRequest) elements.push(header.acknowledgementRequest);
    if (header.agreementId) elements.push(header.agreementId);
    if (header.testIndicator) elements.push(header.testIndicator);

    return this.buildSegment('UNB', elements);
  }

  /**
   * Generate UNZ (Interchange Trailer) segment
   */
  generateUNZ(trailer) {
    return this.buildSegment('UNZ', [
      trailer.controlCount || '1',
      trailer.controlReference || ''
    ]);
  }

  /**
   * Generate a functional group (UNG...UNE)
   */
  generateFunctionalGroup(group) {
    const segments = [];

    // UNG
    const ungElements = [
      group.header?.groupId || '',
      group.header?.sender || '',
      group.header?.recipient || '',
      this.buildElement([
        group.header?.dateTime?.date || '',
        group.header?.dateTime?.time || ''
      ]),
      group.header?.controlReference || '',
      group.header?.controllingAgency || '',
      this.buildElement([
        group.header?.messageVersion?.version || '',
        group.header?.messageVersion?.release || ''
      ])
    ];
    segments.push(this.buildSegment('UNG', ungElements));

    // Messages
    if (group.messages) {
      for (const message of group.messages) {
        segments.push(...this.generateMessage(message));
      }
    }

    // UNE
    segments.push(this.buildSegment('UNE', [
      group.trailer?.controlCount || String(group.messages?.length || 0),
      group.trailer?.controlReference || group.header?.controlReference || ''
    ]));

    return segments;
  }

  /**
   * Generate a message (UNH...UNT)
   */
  generateMessage(message) {
    const segments = [];

    // UNH
    const unhElements = [
      message.header?.referenceNumber || '1',
      this.buildElement([
        message.header?.messageIdentifier?.type || '',
        message.header?.messageIdentifier?.version || 'D',
        message.header?.messageIdentifier?.release || '96A',
        message.header?.messageIdentifier?.controllingAgency || 'UN',
        message.header?.messageIdentifier?.associationCode || ''
      ])
    ];
    segments.push(this.buildSegment('UNH', unhElements));

    // Content segments
    if (message.segments) {
      for (const seg of message.segments) {
        const elements = seg.elements.map(el => {
          if (Array.isArray(el)) {
            return this.buildElement(el.map(c => this.escape(c)));
          }
          return this.escape(String(el));
        });
        segments.push(this.buildSegment(seg.tag, elements));
      }
    }

    // UNT
    const segCount = segments.length + 1; // +1 for UNT itself
    segments.push(this.buildSegment('UNT', [
      message.trailer?.segmentCount || String(segCount),
      message.trailer?.referenceNumber || message.header?.referenceNumber || '1'
    ]));

    return segments;
  }

  /**
   * Build a segment string from tag and elements
   */
  buildSegment(tag, elements) {
    // Remove trailing empty elements
    while (elements.length > 0 && elements[elements.length - 1] === '') {
      elements.pop();
    }
    return tag + this.delimiters.dataSeparator +
      elements.join(this.delimiters.dataSeparator) +
      this.delimiters.segmentTerminator;
  }

  /**
   * Build an element string from components
   */
  buildElement(components) {
    // Remove trailing empty components
    while (components.length > 0 && components[components.length - 1] === '') {
      components.pop();
    }
    return components.join(this.delimiters.componentSeparator);
  }

  /**
   * Escape special characters in a value
   */
  escape(value) {
    if (!value) return '';
    const esc = this.delimiters.escapeCharacter;
    const specials = [
      this.delimiters.componentSeparator,
      this.delimiters.dataSeparator,
      this.delimiters.segmentTerminator,
      this.delimiters.escapeCharacter
    ];

    let result = '';
    for (const char of value) {
      if (specials.includes(char)) {
        result += esc + char;
      } else {
        result += char;
      }
    }
    return result;
  }

  /**
   * Generate EDIFACT from a simplified flat structure
   * Useful for creating messages from form data
   */
  generateFromTemplate(template) {
    const now = new Date();
    const dateStr = now.getFullYear().toString() +
      String(now.getMonth() + 1).padStart(2, '0') +
      String(now.getDate()).padStart(2, '0');
    const timeStr = String(now.getHours()).padStart(2, '0') +
      String(now.getMinutes()).padStart(2, '0');
    const refNum = String(Math.floor(Math.random() * 999999)).padStart(6, '0');

    const interchange = {
      delimiters: this.delimiters,
      header: {
        syntaxIdentifier: { id: 'UNOC', version: '3' },
        sender: { id: template.senderId || 'SENDER', qualifier: template.senderQualifier || '14' },
        recipient: { id: template.recipientId || 'RECIPIENT', qualifier: template.recipientQualifier || '14' },
        dateTime: { date: dateStr, time: timeStr },
        controlReference: refNum
      },
      messages: [{
        header: {
          referenceNumber: '1',
          messageIdentifier: {
            type: template.messageType || 'ORDERS',
            version: template.version || 'D',
            release: template.release || '96A',
            controllingAgency: 'UN'
          }
        },
        segments: template.segments || []
      }],
      trailer: {
        controlCount: '1',
        controlReference: refNum
      }
    };

    return this.generate(interchange);
  }
}

// Export for Node.js / module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { EdifactGenerator };
}
