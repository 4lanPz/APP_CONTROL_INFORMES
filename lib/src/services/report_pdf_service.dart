import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models/maintenance_report.dart';
import '../utils/date_formats.dart';
import 'report_file_service.dart';

class ReportPdfService {
  const ReportPdfService(this._fileService);

  static const _logoAssetPath = 'assets/branding/cfc_logo.jpg';

  static const _companyName = 'CFC² ENGINEERING SOLUTIONS';
  static const _companyAddress =
      'Juan Bautista Aguirre S7-65 y Bobonaza, sector Pio XII';
  static const _companyEmail = 'cfc2.engineering.solutions@hotmail.com';
  static const _companyPhone = '0992795022';

  /// Margen del contenido respecto al borde de la hoja. Debe ser mayor que
  /// [_pageBorderInset] para que el texto quede dentro del recuadro (no
  /// encima de la línea).
  static const _pageMargin = pw.EdgeInsets.all(28);

  /// Cuánto se separa el recuadro decorativo del borde físico de la hoja.
  static const _pageBorderInset = 14.0;

  /// Fotos por fila en "Evidencia fotográfica". Cada fila es una unidad
  /// independiente dentro del flujo del documento: si una fila no cabe en lo
  /// que queda de la página actual, solo esa fila pasa a la siguiente -las
  /// filas anteriores que sí caben se quedan donde están-, en vez de mandar
  /// todas las fotos de la sección juntas.
  static const _photosPerRow = 3;

  final ReportFileService _fileService;

  Future<File> generateReportPdf(MaintenanceReport report) async {
    final document = pw.Document(
      title: 'Informe ${report.uuid}',
      author: 'APP_CONTROL_INFORMES',
    );

    final logoImage = await _loadLogo();
    final beforeImages = await _loadOptionalImages(report.photos.beforePaths);
    final afterImages = await _loadOptionalImages(report.photos.afterPaths);
    final technicianSignature = await _loadOptionalImage(
      report.technicianSignaturePath,
    );
    final clientSignature = await _loadOptionalImage(
      report.clientSignaturePath,
    );
    // Un solo MultiPage para todo el informe: si el contenido de una sección
    // no cabe en la página actual, el motor de PDF continúa en una página
    // nueva automáticamente (nada se corta en silencio, como pasaba con la
    // portada de tamaño fijo), y el recuadro decorativo se repite igual en
    // todas las páginas (antes solo estaba en la primera).
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: _pageMargin,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(_pageBorderInset),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: const PdfColor(1, 1, 1, 0.92),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#184A45'),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        build: (context) {
          return [
            _buildHeader(report, logoImage),
            pw.SizedBox(height: 10),
            _buildCompactSectionTitle('Datos generales'),
            _buildCompactRow(
              leftLabel: 'Fecha',
              leftValue: formatDisplayDate(report.serviceDate),
              rightLabel: 'Tipo',
              rightValue: report.maintenanceType.label,
            ),
            _buildCompactRow(
              leftLabel: 'Ubicación',
              leftValue: report.location,
              rightLabel: 'Horómetro',
              rightValue: report.hourMeter,
            ),
            pw.SizedBox(height: 8),
            _buildCompactSectionTitle('Equipo'),
            _buildCompactRow(
              leftLabel: 'Marca motor',
              leftValue: report.equipment.engineBrand,
              rightLabel: 'Modelo motor',
              rightValue: report.equipment.engineModel,
            ),
            _buildCompactRow(
              leftLabel: 'Marca alternador',
              leftValue: report.equipment.alternatorBrand,
              rightLabel: 'Potencia',
              rightValue: report.equipment.power,
            ),
            _buildCompactRow(
              leftLabel: 'Serie',
              leftValue: report.equipment.serialNumber,
              rightLabel: 'Año',
              rightValue: report.equipment.manufactureYear,
            ),
            pw.SizedBox(height: 8),
            _buildCompactSectionTitle('Pruebas'),
            _buildCompactRow(
              leftLabel: 'Voltajes',
              leftValue:
                  'L1 ${report.tests.voltageL1} | L2 ${report.tests.voltageL2} | L3 ${report.tests.voltageL3}',
              rightLabel: 'Frecuencia',
              rightValue: '${report.tests.frequencyHz} Hz',
            ),
            _buildCompactRow(
              leftLabel: 'Presión aceite',
              leftValue: '${report.tests.oilPressurePsi} PSI',
              rightLabel: 'Temperatura',
              rightValue: '${report.tests.temperatureC} C',
            ),
            _buildCompactRow(
              leftLabel: 'Ruidos / vibraciones',
              leftValue:
                  report.tests.hasAbnormalNoiseOrVibration ? 'Sí' : 'No',
              rightLabel: 'Estado sync',
              rightValue: report.syncStatus.label,
            ),
            pw.SizedBox(height: 8),
            _buildCompactSectionTitle('Checklist de inspección'),
            _buildChecklistTable(report.checklist),
            pw.SizedBox(height: 12),
            _buildSectionTitle('Actividades y repuestos'),
            _buildParagraph(
              'Descripción de actividades / repuestos',
              report.activitiesAndParts,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Observaciones y recomendaciones'),
            _buildParagraph(
              'Observaciones / recomendaciones',
              report.observationsAndRecommendations,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Validación'),
            _buildCompactRow(
              leftLabel: 'Técnico',
              leftValue:
                  '${report.technician.name} (${report.technician.identification})',
              rightLabel: 'Responsable',
              rightValue:
                  '${report.clientContact.name} (${report.clientContact.role})',
            ),
            pw.SizedBox(height: 12),
            _buildSectionTitle('Evidencia fotográfica'),
            ..._buildPhotoSection('Antes del Servicio', beforeImages),
            pw.SizedBox(height: 10),
            ..._buildPhotoSection('Estado Final', afterImages),
            pw.SizedBox(height: 18),
            _buildSignatureRow(
              technicianSignature: technicianSignature,
              clientSignature: clientSignature,
            ),
          ];
        },
      ),
    );

    final pdfBytes = await document.save();
    final file = await _fileService.savePdfToCache(
      report: report,
      bytes: pdfBytes,
    );
    await _fileService.openPdfExternally(file);
    return file;
  }

  pw.Widget _buildHeader(
    MaintenanceReport report,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 58,
                height: 58,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#184A45'),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _companyAddress,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '$_companyEmail | Cel: $_companyPhone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400, thickness: 0.7),
        pw.SizedBox(height: 6),
        pw.Text(
          'Informe de mantenimiento de grupo electrógeno',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'UUID: ${report.uuid}',
          style: const pw.TextStyle(fontSize: 8.5),
        ),
      ],
    );
  }

  pw.Widget _buildCompactSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: PdfColor.fromHex('#DDE9E5'),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: PdfColor.fromHex('#E6EEEC'),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildCompactRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _buildCompactLine(leftLabel, leftValue)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _buildCompactLine(rightLabel, rightValue)),
        ],
      ),
    );
  }

  pw.Widget _buildCompactLine(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 8.5),
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value.trim().isEmpty ? '-' : value),
        ],
      ),
    );
  }

  pw.Widget _buildParagraph(String label, String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value.trim().isEmpty ? '-' : value),
        ],
      ),
    );
  }

  pw.Widget _buildChecklistTable(List<InspectionChecklistEntry> checklist) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _tableCell('Sistema', isHeader: true),
          _tableCell('Item', isHeader: true),
          _tableCell('Estado', isHeader: true),
          _tableCell('Observación', isHeader: true),
        ],
      ),
      ...checklist.map(
        (entry) => pw.TableRow(
          children: [
            _tableCell(entry.system),
            _tableCell(entry.item),
            _tableCell(entry.state.label),
            _tableCell(entry.observation),
          ],
        ),
      ),
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.1),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(1.8),
        },
        children: rows,
      ),
    );
  }

  pw.Widget _tableCell(String value, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        value.trim().isEmpty ? '-' : value,
        style: pw.TextStyle(
          fontSize: 7.6,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Devuelve cada fila de fotos como un elemento independiente de la lista
  /// (en vez de un único bloque `Wrap` con todas las imágenes) para que el
  /// `MultiPage` pueda repartirlas entre páginas fila por fila: la página
  /// actual se llena con las filas completas que quepan y el resto continúa
  /// en la siguiente, sin dejar espacio en blanco ni mandar todas las fotos
  /// juntas a la página nueva.
  List<pw.Widget> _buildPhotoSection(
    String title,
    List<pw.MemoryImage> images,
  ) {
    final widgets = <pw.Widget>[
      pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
      pw.SizedBox(height: 8),
    ];

    if (images.isEmpty) {
      widgets.add(_buildEmptyPhotoCard());
      return widgets;
    }

    for (var start = 0; start < images.length; start += _photosPerRow) {
      final end = (start + _photosPerRow < images.length)
          ? start + _photosPerRow
          : images.length;
      final rowImages = images.sublist(start, end);

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              for (var i = 0; i < rowImages.length; i++) ...[
                if (i > 0) pw.SizedBox(width: 8),
                _buildPhotoCard(image: rowImages[i]),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildPhotoCard({
    required pw.MemoryImage image,
  }) {
    return pw.Container(
      width: 165,
      height: 125,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
      ),
      child: pw.Center(
        child: pw.Image(image, fit: pw.BoxFit.cover),
      ),
    );
  }

  pw.Widget _buildEmptyPhotoCard() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
      ),
      child: pw.Text('No hay imágenes disponibles para esta sección.'),
    );
  }

  pw.Widget _buildSignatureRow({
    required pw.MemoryImage? technicianSignature,
    required pw.MemoryImage? clientSignature,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSignatureBox(
            'Firma técnico',
            signature: technicianSignature,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: _buildSignatureBox(
            'Firma responsable / cliente',
            signature: clientSignature,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureBox(
    String label, {
    pw.MemoryImage? signature,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          height: 48,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          child: signature == null
              ? null
              : pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                  child: pw.Image(signature, fit: pw.BoxFit.contain),
                ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(label),
      ],
    );
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final logoData = await rootBundle.load(_logoAssetPath);
      final logoBytes = logoData.buffer.asUint8List(
        logoData.offsetInBytes,
        logoData.lengthInBytes,
      );
      return pw.MemoryImage(logoBytes);
    } catch (_) {
      return null;
    }
  }

  Future<pw.MemoryImage?> _loadOptionalImage(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    return pw.MemoryImage(bytes);
  }

  Future<List<pw.MemoryImage>> _loadOptionalImages(List<String> paths) async {
    final images = <pw.MemoryImage>[];

    for (final path in paths) {
      final image = await _loadOptionalImage(path);
      if (image != null) {
        images.add(image);
      }
    }

    return images;
  }

}
