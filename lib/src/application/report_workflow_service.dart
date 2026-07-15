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
      technicianSignaturePath: '',
      clientSignaturePath: '',
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

  /// Guarda un informe.
  ///
  /// Cuando [asDraft] es `true` (auto-guardado en segundo plano) el informe
  /// queda como [SyncStatus.draft]: se conserva localmente pero NO se
  /// sincroniza, porque puede estar incompleto (por ejemplo si la app se cerró
  /// a la mitad). Al guardar explícitamente desde el formulario se promueve a
  /// [SyncStatus.pendingSync] para que entre en la cola de sincronización.
  Future<MaintenanceReport> saveReport(
    MaintenanceReport report, {
    bool asDraft = false,
  }) async {
    final now = DateTime.now();
    final normalized = report.copyWith(
      updatedAt: now,
      syncStatus: asDraft ? SyncStatus.draft : SyncStatus.pendingSync,
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

  Future<MaintenanceReport> attachTechnicianSignature({
    required MaintenanceReport report,
    required List<int> bytes,
  }) async {
    final signaturePath = await _fileService.persistSignature(
      reportUuid: report.uuid,
      suffix: 'technician_signature',
      bytes: bytes,
    );

    return report.copyWith(
      technicianSignaturePath: signaturePath,
    );
  }

  Future<MaintenanceReport> attachClientSignature({
    required MaintenanceReport report,
    required List<int> bytes,
  }) async {
    final signaturePath = await _fileService.persistSignature(
      reportUuid: report.uuid,
      suffix: 'client_signature',
      bytes: bytes,
    );

    return report.copyWith(
      clientSignaturePath: signaturePath,
    );
  }

  /// Elimina el registro de un informe de la base local. Las fotos y firmas
  /// asociadas se conservan en el dispositivo a propósito (no se borran).
  /// No afecta lo que ya se haya sincronizado a Supabase.
  Future<void> deleteReport(MaintenanceReport report) async {
    await _repository.delete(report.uuid);
  }

  /// Borra un archivo de foto ya persistido en disco (best-effort). Se usa
  /// al quitar una foto del formulario para no acumular archivos huérfanos.
  Future<void> deletePhotoFile(String path) {
    return _fileService.deleteFile(path);
  }

  Future<File> generatePdf(
    MaintenanceReport report, {
    String? logoPath,
  }) {
    return _pdfService.generateReportPdf(report, logoPath: logoPath);
  }

  List<ReportValidationError> validateReport(MaintenanceReport report) {
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
        system: 'Lubricación',
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
        system: 'Refrigeración',
        item: 'Nivel refrigerante / Radiador / Mangueras',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Admisión/Escape',
        item: 'Filtro de aire / Estado del silenciador',
        state: InspectionState.notApplicable,
        observation: '',
      ),
      InspectionChecklistEntry(
        system: 'Eléctrico',
        item: 'Estado de baterías / Voltaje / Bornes',
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
        system: 'Mecánico',
        item: 'Correas / Tensión / Desgaste / Soportes',
        state: InspectionState.notApplicable,
        observation: '',
      ),
    ];
  }
}
