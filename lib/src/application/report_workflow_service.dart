import 'dart:io';

import 'package:uuid/uuid.dart';

import '../data/remote/supabase_sync_service.dart';
import '../domain/models/maintenance_report.dart';
import '../domain/repositories/maintenance_report_repository.dart';
import '../services/report_file_service.dart';
import '../services/report_pdf_service.dart';
import '../services/report_validator.dart';

class ReportWorkflowService {
  ReportWorkflowService({
    required MaintenanceReportRepository repository,
    required ReportFileService fileService,
    required ReportPdfService pdfService,
    required SupabaseSyncService syncService,
    required ReportValidator validator,
    Uuid? uuidGenerator,
  })  : _repository = repository,
        _fileService = fileService,
        _pdfService = pdfService,
        _syncService = syncService,
        _validator = validator,
        _uuid = uuidGenerator ?? const Uuid();

  final MaintenanceReportRepository _repository;
  final ReportFileService _fileService;
  final ReportPdfService _pdfService;
  final SupabaseSyncService _syncService;
  final ReportValidator _validator;
  final Uuid _uuid;

  bool get isRemoteSyncEnabled => _syncService.isEnabled;

  MaintenanceReport createEmptyReport() {
    final now = DateTime.now();
    return MaintenanceReport(
      uuid: _uuid.v4(),
      serviceDate: now,
      maintenanceType: MaintenanceType.preventive,
      location: '',
      hourMeter: '',
      equipment: const EquipmentInfo(
        engineBrand: '',
        engineModel: '',
        alternatorBrand: '',
        power: '',
        serialNumber: '',
        manufactureYear: '',
      ),
      checklist: _defaultChecklist(),
      tests: const TestMeasurements(
        voltageL1: '',
        voltageL2: '',
        voltageL3: '',
        frequencyHz: '',
        oilPressurePsi: '',
        temperatureC: '',
        hasAbnormalNoiseOrVibration: false,
      ),
      activitiesAndParts: '',
      observationsAndRecommendations: '',
      technician: const TechnicianInfo(
        name: '',
        identification: '',
      ),
      clientContact: const ClientContactInfo(
        name: '',
        role: '',
      ),
      photos: const ReportPhotos(
        beforePaths: [],
        afterPaths: [],
      ),
      syncStatus: SyncStatus.pendingSync,
      createdAt: now,
      updatedAt: now,
      syncedAt: null,
    );
  }

  Future<List<MaintenanceReport>> loadReports({SyncStatus? status}) {
    return _repository.list(status: status);
  }

  Future<MaintenanceReport?> getReport(String uuid) {
    return _repository.findByUuid(uuid);
  }

  Future<MaintenanceReport> saveReport(MaintenanceReport report) async {
    final now = DateTime.now();
    final normalized = report.copyWith(
      updatedAt: now,
      syncStatus: SyncStatus.pendingSync,
      syncedAt: null,
    );
    return _repository.save(normalized);
  }

  Future<MaintenanceReport> attachPhotos({
    required MaintenanceReport report,
    required List<String> sourcePaths,
    required ReportPhotoType type,
  }) async {
    if (sourcePaths.isEmpty) {
      return report;
    }

    final managedPaths = <String>[];
    for (final sourcePath in sourcePaths) {
      managedPaths.add(
        await _fileService.persistPhoto(
          reportUuid: report.uuid,
          sourcePath: sourcePath,
          type: type,
        ),
      );
    }

    final updatedPhotos = type == ReportPhotoType.before
        ? report.photos.copyWith(
            beforePaths: [...report.photos.beforePaths, ...managedPaths],
          )
        : report.photos.copyWith(
            afterPaths: [...report.photos.afterPaths, ...managedPaths],
          );

    return report.copyWith(photos: updatedPhotos);
  }

  Future<File> generatePdf(
    MaintenanceReport report, {
    String? logoPath,
  }) {
    return _pdfService.generateReportPdf(report, logoPath: logoPath);
  }

  List<String> validateReport(MaintenanceReport report) {
    return _validator.validate(report);
  }

  Future<SyncBatchResult> syncPendingReports() async {
    final pendingReports = await _repository.pendingSync();
    final result = await _syncService.syncReports(pendingReports);

    if (result.successfulUuids.isEmpty && result.failedUuids.isEmpty) {
      return result;
    }

    final syncTime = DateTime.now();

    for (final uuid in result.successfulUuids) {
      final report = await _repository.findByUuid(uuid);
      if (report == null) {
        continue;
      }

      await _repository.save(
        report.copyWith(
          syncStatus: SyncStatus.synced,
          updatedAt: syncTime,
          syncedAt: syncTime,
        ),
      );
    }

    for (final uuid in result.failedUuids) {
      final report = await _repository.findByUuid(uuid);
      if (report == null) {
        continue;
      }

      await _repository.save(
        report.copyWith(
          syncStatus: SyncStatus.syncError,
          updatedAt: syncTime,
        ),
      );
    }

    return result;
  }

  List<InspectionChecklistEntry> _defaultChecklist() {
    return const [
      InspectionChecklistEntry(
        system: 'Lubricacion',
        item: 'Nivel de aceite / Cambio realizado',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Combustible',
        item: 'Nivel de tanque / Fugas / Filtros',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Refrigeracion',
        item: 'Nivel refrigerante / Radiador / Mangueras',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Admision/Escape',
        item: 'Filtro de aire / Estado del silenciador',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Electrico',
        item: 'Estado de baterias / Voltaje / Bornes',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Control',
        item: 'Panel de control / Alarmas / Sensores',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Mecanico',
        item: 'Correas / Tension / Desgaste / Soportes',
        state: InspectionState.notApplicable,
        observation: '',
      ),
    ];
  }
}
