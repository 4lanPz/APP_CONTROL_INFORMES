import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models/maintenance_report.dart';
import 'report_file_service.dart';

class ReportPdfService {
  const ReportPdfService(this._fileService);

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
    final beforeImage = await _loadOptionalImage(report.photos.beforePath);
    final afterImage = await _loadOptionalImage(report.photos.afterPath);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            _buildHeader(report, logoImage),
            pw.SizedBox(height: 12),
            _buildSectionTitle('Datos generales'),
            _buildTwoColumnRow(
              leftLabel: 'Fecha',
              leftValue: _formatDate(report.serviceDate),
              rightLabel: 'Tipo',
              rightValue: report.maintenanceType.label,
            ),
            _buildTwoColumnRow(
              leftLabel: 'Ubicacion',
              leftValue: report.location,
              rightLabel: 'Horometro',
              rightValue: report.hourMeter,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Equipo'),
            _buildTwoColumnRow(
              leftLabel: 'Marca motor',
              leftValue: report.equipment.engineBrand,
              rightLabel: 'Modelo motor',
              rightValue: report.equipment.engineModel,
            ),
            _buildTwoColumnRow(
              leftLabel: 'Marca alternador',
              leftValue: report.equipment.alternatorBrand,
              rightLabel: 'Potencia',
              rightValue: report.equipment.power,
            ),
            _buildTwoColumnRow(
              leftLabel: 'Serie',
              leftValue: report.equipment.serialNumber,
              rightLabel: 'Anio',
              rightValue: report.equipment.manufactureYear,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Checklist'),
            _buildChecklistTable(report.checklist),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Pruebas'),
            _buildTwoColumnRow(
              leftLabel: 'Voltajes',
              leftValue:
                  'L1 ${report.tests.voltageL1} / L2 ${report.tests.voltageL2} / L3 ${report.tests.voltageL3}',
              rightLabel: 'Frecuencia',
              rightValue: report.tests.frequencyHz,
            ),
            _buildTwoColumnRow(
              leftLabel: 'Presion aceite',
              leftValue: report.tests.oilPressurePsi,
              rightLabel: 'Temperatura',
              rightValue: report.tests.temperatureC,
            ),
            _buildSingleLine(
              'Ruidos o vibraciones anormales',
              report.tests.hasAbnormalNoiseOrVibration ? 'Si' : 'No',
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Actividades y recomendaciones'),
            _buildParagraph('Actividades / repuestos', report.activitiesAndParts),
            _buildParagraph(
              'Observaciones / recomendaciones',
              report.observationsAndRecommendations,
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Validacion'),
            _buildTwoColumnRow(
              leftLabel: 'Tecnico',
              leftValue:
                  '${report.technician.name} (${report.technician.identification})',
              rightLabel: 'Responsable',
              rightValue:
                  '${report.clientContact.name} (${report.clientContact.role})',
            ),
            pw.SizedBox(height: 10),
            _buildSectionTitle('Fotos'),
            _buildPhotosRow(beforeImage, afterImage),
            pw.SizedBox(height: 20),
            _buildSignatureRow(),
          ];
        },
      ),
    );

    final outputPath = await _fileService.buildPdfOutputPath(report.uuid);
    final file = File(outputPath);
    await file.writeAsBytes(await document.save());
    return file;
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
            width: 72,
            height: 72,
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
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('UUID: ${report.uuid}'),
              pw.Text('Estado: ${report.syncStatus.label}'),
            ],
          ),
        ),
      ],
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

  pw.Widget _buildTwoColumnRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _buildSingleLine(leftLabel, leftValue)),
          pw.SizedBox(width: 16),
          pw.Expanded(child: _buildSingleLine(rightLabel, rightValue)),
        ],
      ),
    );
  }

  pw.Widget _buildSingleLine(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
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
          pw.SizedBox(height: 3),
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
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(2),
        },
        children: rows,
      ),
    );
  }

  pw.Widget _tableCell(String value, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value.trim().isEmpty ? '-' : value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPhotosRow(
    pw.MemoryImage? beforeImage,
    pw.MemoryImage? afterImage,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        children: [
          pw.Expanded(child: _buildPhotoCard('Antes', beforeImage)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _buildPhotoCard('Despues', afterImage)),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoCard(String title, pw.MemoryImage? image) {
    return pw.Container(
      height: 180,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: image == null
                ? pw.Center(child: pw.Text('Imagen no disponible'))
                : pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ],
      ),
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

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

