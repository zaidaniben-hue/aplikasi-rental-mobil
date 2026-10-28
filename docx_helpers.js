const fs = require('fs');
const path = require('path');
const docx = require('docx');
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  Table,
  TableRow,
  TableCell,
  WidthType,
  AlignmentType,
  HeadingLevel,
  BorderStyle,
  Header,
  Footer,
  PageNumber,
  NumberFormat,
  ShadingType
} = docx;

// Palette Warna Formal Profesional
const PRIMARY_HEX = "0F3E76";     // Deep Navy
const SECONDARY_HEX = "1E293B";   // Slate Charcoal
const ACCENT_HEX = "0284C7";      // Sky Blue
const LIGHT_BG_HEX = "F8FAFC";    // Off-white / light slate
const CALLOUT_BG_HEX = "F0F9FF";  // Very light sky blue
const BORDER_HEX = "CBD5E1";      // Light gray border
const TEXT_MUTED_HEX = "64748B";  // Slate gray
const SUCCESS_HEX = "16A34A";     // Forest green
const WARNING_HEX = "D97706";     // Amber

// Helper Membuat Border Tipis
const standardBorder = {
  style: BorderStyle.SINGLE,
  size: 4,
  color: BORDER_HEX,
};

const cellBorders = {
  top: standardBorder,
  bottom: standardBorder,
  left: standardBorder,
  right: standardBorder,
};

const noBorder = {
  style: BorderStyle.NONE,
  size: 0,
  color: "auto",
};

// Helper Paragraph Standar
function p(text, options = {}) {
  const {
    bold = false,
    italic = false,
    color = "1E293B",
    size = 22, // 11pt
    align = AlignmentType.JUSTIFIED,
    spaceBefore = 100,
    spaceAfter = 140,
    lineSpacing = 276 // 1.15 line spacing
  } = options;

  return new Paragraph({
    alignment: align,
    spacing: {
      before: spaceBefore,
      after: spaceAfter,
      line: lineSpacing,
    },
    children: [
      new TextRun({
        text: text,
        bold: bold,
        italics: italic,
        color: color,
        size: size,
        font: "Arial",
      }),
    ],
  });
}

// Paragraph dengan Multiple TextRuns
function pRuns(runs, options = {}) {
  const {
    align = AlignmentType.JUSTIFIED,
    spaceBefore = 100,
    spaceAfter = 140,
    lineSpacing = 276
  } = options;

  return new Paragraph({
    alignment: align,
    spacing: {
      before: spaceBefore,
      after: spaceAfter,
      line: lineSpacing,
    },
    children: runs.map(r => new TextRun({
      text: r.text,
      bold: r.bold || false,
      italics: r.italic || false,
      color: r.color || "1E293B",
      size: r.size || 22,
      font: r.font || "Arial",
    })),
  });
}

// Heading 1 (BAB)
function h1(title) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 180 },
    children: [
      new TextRun({
        text: title,
        bold: true,
        size: 28, // 14pt
        color: PRIMARY_HEX,
        font: "Arial",
      }),
    ],
  });
}

// Heading 2 (Sub Bab)
function h2(title) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 260, after: 120 },
    children: [
      new TextRun({
        text: title,
        bold: true,
        size: 24, // 12pt
        color: SECONDARY_HEX,
        font: "Arial",
      }),
    ],
  });
}

// Heading 3 (Sub-Sub Bab)
function h3(title) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 180, after: 80 },
    children: [
      new TextRun({
        text: title,
        bold: true,
        italics: true,
        size: 22, // 11pt
        color: ACCENT_HEX,
        font: "Arial",
      }),
    ],
  });
}

// Bullet Point
function bullet(text, boldPrefix = '') {
  return new Paragraph({
    bullet: { level: 0 },
    spacing: { before: 60, after: 60, line: 260 },
    alignment: AlignmentType.JUSTIFIED,
    children: [
      ...(boldPrefix ? [new TextRun({ text: boldPrefix + ' ', bold: true, size: 22, color: SECONDARY_HEX, font: "Arial" })] : []),
      new TextRun({ text: text, size: 22, color: SECONDARY_HEX, font: "Arial" }),
    ],
  });
}

// Numbered List
function numberedItem(num, text, boldPrefix = '') {
  return new Paragraph({
    spacing: { before: 60, after: 60, line: 260 },
    alignment: AlignmentType.JUSTIFIED,
    children: [
      new TextRun({ text: `${num}. `, bold: true, size: 22, color: PRIMARY_HEX, font: "Arial" }),
      ...(boldPrefix ? [new TextRun({ text: boldPrefix + ' ', bold: true, size: 22, color: SECONDARY_HEX, font: "Arial" })] : []),
      new TextRun({ text: text, size: 22, color: SECONDARY_HEX, font: "Arial" }),
    ],
  });
}

// Callout Box
function calloutBox(title, bodyText, options = {}) {
  const { borderColor = PRIMARY_HEX, bgColor = CALLOUT_BG_HEX } = options;

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    margins: { top: 140, bottom: 140, left: 180, right: 180 },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            borders: {
              top: noBorder,
              bottom: noBorder,
              right: noBorder,
              left: { style: BorderStyle.SINGLE, size: 24, color: borderColor },
            },
            shading: { fill: bgColor, type: ShadingType.CLEAR },
            children: [
              new Paragraph({
                spacing: { before: 40, after: 60 },
                children: [
                  new TextRun({ text: title, bold: true, color: borderColor, size: 22, font: "Arial" }),
                ],
              }),
              new Paragraph({
                spacing: { before: 0, after: 40, line: 260 },
                alignment: AlignmentType.JUSTIFIED,
                children: [
                  new TextRun({ text: bodyText, size: 21, color: SECONDARY_HEX, font: "Arial" }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}

// Formula Block Box
function formulaBox(formulaText, explanation = '') {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    margins: { top: 120, bottom: 120, left: 180, right: 180 },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            borders: cellBorders,
            shading: { fill: "F1F5F9", type: ShadingType.CLEAR },
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { before: 80, after: 60 },
                children: [
                  new TextRun({ text: formulaText, bold: true, size: 24, color: PRIMARY_HEX, font: "Courier New" }),
                ],
              }),
              ...(explanation ? [
                new Paragraph({
                  alignment: AlignmentType.JUSTIFIED,
                  spacing: { before: 40, after: 40 },
                  children: [
                    new TextRun({ text: 'Keterangan: ', bold: true, italics: true, size: 20, color: TEXT_MUTED_HEX, font: "Arial" }),
                    new TextRun({ text: explanation, italics: true, size: 20, color: SECONDARY_HEX, font: "Arial" }),
                  ],
                })
              ] : []),
            ],
          }),
        ],
      }),
    ],
  });
}

// Table Generator
function createTable(headers, rowsData, colWidths = []) {
  const tableRows = [];

  // Header Row
  const headerCells = headers.map((h, i) => {
    return new TableCell({
      borders: cellBorders,
      shading: { fill: PRIMARY_HEX, type: ShadingType.CLEAR },
      margins: { top: 100, bottom: 100, left: 120, right: 120 },
      width: colWidths[i] ? { size: colWidths[i], type: WidthType.PERCENTAGE } : undefined,
      children: [
        new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [
            new TextRun({ text: h, bold: true, color: "FFFFFF", size: 21, font: "Arial" }),
          ],
        }),
      ],
    });
  });
  tableRows.push(new TableRow({ children: headerCells }));

  // Data Rows
  rowsData.forEach((row, rowIndex) => {
    const isAlt = rowIndex % 2 === 1;
    const cells = row.map((cellText, i) => {
      return new TableCell({
        borders: cellBorders,
        shading: { fill: isAlt ? LIGHT_BG_HEX : "FFFFFF", type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        width: colWidths[i] ? { size: colWidths[i], type: WidthType.PERCENTAGE } : undefined,
        children: [
          new Paragraph({
            alignment: i === 0 ? AlignmentType.CENTER : AlignmentType.LEFT,
            children: [
              new TextRun({ text: String(cellText), size: 20, color: SECONDARY_HEX, font: "Arial" }),
            ],
          }),
        ],
      });
    });
    tableRows.push(new TableRow({ children: cells }));
  });

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: tableRows,
  });
}

// Helper Cover Header Section
function createCoverSection(modelTitle, subtitle, modelCategory) {
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 60 },
      children: [
        new TextRun({ text: "SISTEM INFORMASI MANAJEMEN RENTAL MOBIL TERPADU", bold: true, size: 22, color: TEXT_MUTED_HEX, font: "Arial" }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 200 },
      children: [
        new TextRun({ text: "RENTDESK ENTERPRISE PLATFORM", bold: true, size: 26, color: PRIMARY_HEX, font: "Arial" }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 120 },
      children: [
        new TextRun({ text: "LAPORAN TEKNIS IMPLEMENTASI ALGORITMA MACHINE LEARNING", bold: true, size: 30, color: PRIMARY_HEX, font: "Arial" }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 60, after: 160 },
      children: [
        new TextRun({ text: modelTitle.toUpperCase(), bold: true, size: 32, color: ACCENT_HEX, font: "Arial" }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 360 },
      children: [
        new TextRun({ text: subtitle, italics: true, size: 22, color: SECONDARY_HEX, font: "Arial" }),
      ],
    }),
    // Metadata Table
    new Table({
      width: { size: 100, type: WidthType.PERCENTAGE },
      rows: [
        new TableRow({
          children: [
            new TableCell({
              borders: cellBorders,
              shading: { fill: LIGHT_BG_HEX, type: ShadingType.CLEAR },
              margins: { top: 120, bottom: 120, left: 160, right: 160 },
              children: [
                pRuns([
                  { text: "Kategori Algoritma: ", bold: true },
                  { text: modelCategory },
                ], { spaceBefore: 40, spaceAfter: 40 }),
                pRuns([
                  { text: "Arsitektur Modul: ", bold: true },
                  { text: "Client-Side Embedded ML (Dart Native) & Supabase Synchronized" },
                ], { spaceBefore: 40, spaceAfter: 40 }),
                pRuns([
                  { text: "Penyusun: ", bold: true },
                  { text: "Tim Pengembang Sistem RentDesk (Full Stack Engineering Team)" },
                ], { spaceBefore: 40, spaceAfter: 40 }),
                pRuns([
                  { text: "Waktu Rilis & Versi: ", bold: true },
                  { text: "Tahun Akademik 2026/2027 - Versi Produksi 1.0.0" },
                ], { spaceBefore: 40, spaceAfter: 40 }),
              ],
            }),
          ],
        }),
      ],
    }),
    new Paragraph({
      spacing: { before: 300, after: 200 },
      children: [new TextRun({ text: "" })],
    }),
  ];
}

console.log("Helper functions defined successfully.");
module.exports = {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, AlignmentType, HeadingLevel, BorderStyle, Header, Footer,
  PageNumber, NumberFormat, ShadingType,
  p, pRuns, h1, h2, h3, bullet, numberedItem, calloutBox, formulaBox, createTable, createCoverSection,
  PRIMARY_HEX, SECONDARY_HEX, ACCENT_HEX, LIGHT_BG_HEX, BORDER_HEX, TEXT_MUTED_HEX, SUCCESS_HEX, WARNING_HEX
};
