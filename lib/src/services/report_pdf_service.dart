import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/maintenance_report.dart';
import 'report_file_service.dart';

class ReportPdfService {
  const ReportPdfService(this._fileService);

  static const _templateAssetPath = 'Formulario_base.pdf';
  static const _showDraftWatermark = true;
  static const _draftWatermarkLabel = 'BORRADOR';

  final ReportFileService _fileService;

  Future<File> generateReportPdf(
    MaintenanceReport report, {
    String? logoPath,
  }) async {
    final document = pw.Document(
      title: 'Informe ${report.uuid}',
      author: 'APP_CONTROL_INFORMES',
    );

    final logoImage = await _loadOptionalImage(logoPath);
    final beforeImages = await _loadOptionalImages(report.photos.beforePaths);
    final afterImages = await _loadOptionalImages(report.photos.afterPaths);
    final templateBackground = await _loadTemplateBackground();

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: templateBackground == null
              ? null
              : (context) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(
                      templateBackground,
                      fit: pw.BoxFit.fill,
                    ),
                  ),
          buildForeground: _showDraftWatermark
              ? (context) => _buildDraftWatermark()
              : null,
        ),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(22),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor(1, 1, 1, 0.92),
                border: pw.Border.all(
                  color: PdfColor.fromHex('#184A45'),
                  width: 1,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(report, logoImage),
                  pw.SizedBox(height: 10),
                  _buildCompactSectionTitle('Datos generales'),
                  _buildCompactRow(
                    leftLabel: 'Fecha',
                    leftValue: _formatDate(report.serviceDate),
                    rightLabel: 'Tipo',
                    rightValue: report.maintenanceType.label,
                  ),
                  _buildCompactRow(
                    leftLabel: 'Ubicacion',
                    leftValue: report.location,
                    rightLabel: 'Horometro',
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
                    rightLabel: 'Anio',
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
                    leftLabel: 'Presion aceite',
                    leftValue: '${report.tests.oilPressurePsi} PSI',
                    rightLabel: 'Temperatura',
                    rightValue: '${report.tests.temperatureC} C',
                  ),
                  _buildCompactRow(
                    leftLabel: 'Ruidos / vibraciones',
                    leftValue:
                        report.tests.hasAbnormalNoiseOrVibration ? 'Si' : 'No',
                    rightLabel: 'Estado sync',
                    rightValue: report.syncStatus.label,
                  ),
                  pw.SizedBox(height: 8),
                  _buildCompactSectionTitle('Checklist de inspeccion'),
                  _buildChecklistTable(report.checklist),
                ],
              ),
            ),
          );
        },
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          buildForeground: _showDraftWatermark
              ? (context) => _buildDraftWatermark()
              : null,
        ),
        build: (context) {
          return [
            _buildSectionTitle('Actividades y repuestos'),
            _buildParagraph(
              'Descripcion de actividades / repuestos',
              report.activitiesAndParts,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Observaciones y recomendaciones'),
            _buildParagraph(
              'Observaciones / recomendaciones',
              report.observationsAndRecommendations,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Validacion'),
            _buildCompactRow(
              leftLabel: 'Tecnico',
              leftValue:
                  '${report.technician.name} (${report.technician.identification})',
              rightLabel: 'Responsable',
              rightValue:
                  '${report.clientContact.name} (${report.clientContact.role})',
            ),
            pw.SizedBox(height: 12),
            _buildSectionTitle('Evidencia fotografica'),
            _buildPhotoSection('Antes del Servicio', beforeImages),
            pw.SizedBox(height: 10),
            _buildPhotoSection('Estado Final', afterImages),
            pw.SizedBox(height: 18),
            _buildSignatureRow(),
          ];
        },
      ),
    );

    final pdfBytes = await document.save();
    return _fileService.savePdf(
      report: report,
      bytes: pdfBytes,
    );
  }

  pw.Widget _buildHeader(
    MaintenanceReport report,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Row(
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
                'Informe de mantenimiento de grupo electrogeno',
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
              pw.Text(
                'Plantilla base: Formulario_base.pdf',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ],
          ),
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
          _tableCell('Observacion', isHeader: true),
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

  pw.Widget _buildPhotoSection(String title, List<pw.MemoryImage> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
          ),
        ),
        pw.SizedBox(height: 8),
        if (images.isEmpty)
          _buildEmptyPhotoCard()
        else
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images
                .map((image) => _buildPhotoCard(image: image))
                .toList(growable: false),
          ),
      ],
    );
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
      child: pw.Text('No hay imagenes disponibles para esta seccion.'),
    );
  }

  pw.Widget _buildSignatureRow() {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildSignatureBox('Firma tecnico')),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _buildSignatureBox('Firma responsable / cliente')),
      ],
    );
  }

  pw.Widget _buildSignatureBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          height: 48,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(label),
      ],
    );
  }

  Future<pw.MemoryImage?> _loadTemplateBackground() async {
    try {
      final templateData = await rootBundle.load(_templateAssetPath);
      final templateBytes = templateData.buffer.asUint8List(
        templateData.offsetInBytes,
        templateData.lengthInBytes,
      );

      await for (final page in Printing.raster(
        templateBytes,
        pages: const [0],
        dpi: 144,
      )) {
        final pngBytes = await page.toPng();
        return pw.MemoryImage(pngBytes);
      }
    } catch (_) {
      return null;
    }

    return null;
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

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  pw.Widget _buildDraftWatermark() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Watermark.text(
        _draftWatermarkLabel,
        style: pw.TextStyle(
          color: PdfColor.fromHex('#D7DED9'),
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}
