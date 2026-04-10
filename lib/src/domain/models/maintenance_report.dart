enum MaintenanceType {
  preventive('preventivo', 'Preventivo'),
  corrective('correctivo', 'Correctivo'),
  emergency('emergencia', 'Emergencia');

  const MaintenanceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MaintenanceType fromApiValue(String? value) {
    return values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => MaintenanceType.preventive,
    );
  }
}

enum InspectionState {
  ok('ok', 'OK'),
  actionRequired('requiere_accion', 'Requiere acción'),
  notApplicable('na', 'N/A');

  const InspectionState(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static InspectionState fromApiValue(String? value) {
    return values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => InspectionState.notApplicable,
    );
  }
}

enum SyncStatus {
  draft('draft', 'Borrador'),
  pendingSync('pending_sync', 'Pendiente'),
  synced('synced', 'Sincronizado'),
  syncError('sync_error', 'Con error');

  const SyncStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SyncStatus fromApiValue(String? value) {
    return values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => SyncStatus.pendingSync,
    );
  }
}

class InspectionChecklistEntry {
  const InspectionChecklistEntry({
    required this.system,
    required this.item,
    required this.state,
    required this.observation,
  });

  final String system;
  final String item;
  final InspectionState state;
  final String observation;

  InspectionChecklistEntry copyWith({
    String? system,
    String? item,
    InspectionState? state,
    String? observation,
  }) {
    return InspectionChecklistEntry(
      system: system ?? this.system,
      item: item ?? this.item,
      state: state ?? this.state,
      observation: observation ?? this.observation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sistema': system,
      'item': item,
      'estado': state.apiValue,
      'observacion': observation,
    };
  }

  factory InspectionChecklistEntry.fromJson(Map<String, dynamic> json) {
    return InspectionChecklistEntry(
      system: (json['sistema'] ?? '') as String,
      item: (json['item'] ?? '') as String,
      state: InspectionState.fromApiValue(json['estado'] as String?),
      observation: (json['observacion'] ?? '') as String,
    );
  }
}

class EquipmentInfo {
  const EquipmentInfo({
    required this.engineBrand,
    required this.engineModel,
    required this.alternatorBrand,
    required this.power,
    required this.serialNumber,
    required this.manufactureYear,
  });

  final String engineBrand;
  final String engineModel;
  final String alternatorBrand;
  final String power;
  final String serialNumber;
  final String manufactureYear;

  EquipmentInfo copyWith({
    String? engineBrand,
    String? engineModel,
    String? alternatorBrand,
    String? power,
    String? serialNumber,
    String? manufactureYear,
  }) {
    return EquipmentInfo(
      engineBrand: engineBrand ?? this.engineBrand,
      engineModel: engineModel ?? this.engineModel,
      alternatorBrand: alternatorBrand ?? this.alternatorBrand,
      power: power ?? this.power,
      serialNumber: serialNumber ?? this.serialNumber,
      manufactureYear: manufactureYear ?? this.manufactureYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marca_motor': engineBrand,
      'modelo_motor': engineModel,
      'marca_alternador': alternatorBrand,
      'potencia': power,
      'serie_equipo': serialNumber,
      'anio_fabricacion': manufactureYear,
    };
  }

  factory EquipmentInfo.fromJson(Map<String, dynamic> json) {
    return EquipmentInfo(
      engineBrand: (json['marca_motor'] ?? '') as String,
      engineModel: (json['modelo_motor'] ?? '') as String,
      alternatorBrand: (json['marca_alternador'] ?? '') as String,
      power: (json['potencia'] ?? '') as String,
      serialNumber: (json['serie_equipo'] ?? '') as String,
      manufactureYear: (json['anio_fabricacion'] ?? '') as String,
    );
  }
}

class TestMeasurements {
  const TestMeasurements({
    required this.voltageL1,
    required this.voltageL2,
    required this.voltageL3,
    required this.frequencyHz,
    required this.oilPressurePsi,
    required this.temperatureC,
    required this.hasAbnormalNoiseOrVibration,
  });

  final String voltageL1;
  final String voltageL2;
  final String voltageL3;
  final String frequencyHz;
  final String oilPressurePsi;
  final String temperatureC;
  final bool hasAbnormalNoiseOrVibration;

  TestMeasurements copyWith({
    String? voltageL1,
    String? voltageL2,
    String? voltageL3,
    String? frequencyHz,
    String? oilPressurePsi,
    String? temperatureC,
    bool? hasAbnormalNoiseOrVibration,
  }) {
    return TestMeasurements(
      voltageL1: voltageL1 ?? this.voltageL1,
      voltageL2: voltageL2 ?? this.voltageL2,
      voltageL3: voltageL3 ?? this.voltageL3,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      oilPressurePsi: oilPressurePsi ?? this.oilPressurePsi,
      temperatureC: temperatureC ?? this.temperatureC,
      hasAbnormalNoiseOrVibration: hasAbnormalNoiseOrVibration ??
          this.hasAbnormalNoiseOrVibration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voltaje_l1': voltageL1,
      'voltaje_l2': voltageL2,
      'voltaje_l3': voltageL3,
      'frecuencia_hz': frequencyHz,
      'presion_aceite_psi': oilPressurePsi,
      'temperatura_c': temperatureC,
      'ruidos_vibraciones_anormales':
          hasAbnormalNoiseOrVibration ? 'si' : 'no',
    };
  }

  factory TestMeasurements.fromJson(Map<String, dynamic> json) {
    return TestMeasurements(
      voltageL1: (json['voltaje_l1'] ?? '') as String,
      voltageL2: (json['voltaje_l2'] ?? '') as String,
      voltageL3: (json['voltaje_l3'] ?? '') as String,
      frequencyHz: (json['frecuencia_hz'] ?? '') as String,
      oilPressurePsi: (json['presion_aceite_psi'] ?? '') as String,
      temperatureC: (json['temperatura_c'] ?? '') as String,
      hasAbnormalNoiseOrVibration:
          (json['ruidos_vibraciones_anormales'] ?? 'no') == 'si',
    );
  }
}

class TechnicianInfo {
  const TechnicianInfo({
    required this.name,
    required this.identification,
  });

  final String name;
  final String identification;

  TechnicianInfo copyWith({
    String? name,
    String? identification,
  }) {
    return TechnicianInfo(
      name: name ?? this.name,
      identification: identification ?? this.identification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'identificacion': identification,
    };
  }

  factory TechnicianInfo.fromJson(Map<String, dynamic> json) {
    return TechnicianInfo(
      name: (json['nombre'] ?? '') as String,
      identification: (json['identificacion'] ?? '') as String,
    );
  }
}

class ClientContactInfo {
  const ClientContactInfo({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  ClientContactInfo copyWith({
    String? name,
    String? role,
  }) {
    return ClientContactInfo(
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'cargo': role,
    };
  }

  factory ClientContactInfo.fromJson(Map<String, dynamic> json) {
    return ClientContactInfo(
      name: (json['nombre'] ?? '') as String,
      role: (json['cargo'] ?? '') as String,
    );
  }
}

class ReportPhotos {
  const ReportPhotos({
    required this.beforePaths,
    required this.afterPaths,
  });

  final List<String> beforePaths;
  final List<String> afterPaths;

  String get beforePath => beforePaths.isEmpty ? '' : beforePaths.first;

  String get afterPath => afterPaths.isEmpty ? '' : afterPaths.first;

  bool get isComplete =>
      beforePaths.isNotEmpty && afterPaths.isNotEmpty;

  ReportPhotos copyWith({
    List<String>? beforePaths,
    List<String>? afterPaths,
  }) {
    return ReportPhotos(
      beforePaths: beforePaths ?? this.beforePaths,
      afterPaths: afterPaths ?? this.afterPaths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'antes_ruta_local': beforePath,
      'despues_ruta_local': afterPath,
      'antes_rutas_locales': beforePaths,
      'despues_rutas_locales': afterPaths,
    };
  }

  factory ReportPhotos.fromJson(Map<String, dynamic> json) {
    final beforePaths = _readPathList(
      json['antes_rutas_locales'],
      fallback: json['antes_ruta_local'],
    );
    final afterPaths = _readPathList(
      json['despues_rutas_locales'],
      fallback: json['despues_ruta_local'],
    );

    return ReportPhotos(
      beforePaths: beforePaths,
      afterPaths: afterPaths,
    );
  }

  static List<String> _readPathList(
    Object? value, {
    Object? fallback,
  }) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final fallbackValue = fallback?.toString().trim() ?? '';
    if (fallbackValue.isEmpty) {
      return const [];
    }

    return <String>[fallbackValue];
  }
}

const Object _sentinel = Object();

class MaintenanceReport {
  const MaintenanceReport({
    this.localId,
    required this.uuid,
    required this.serviceDate,
    required this.maintenanceType,
    required this.location,
    required this.hourMeter,
    required this.equipment,
    required this.checklist,
    required this.tests,
    required this.activitiesAndParts,
    required this.observationsAndRecommendations,
    required this.technician,
    required this.technicianSignaturePath,
    required this.clientContact,
    required this.photos,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.syncedAt,
  });

  final int? localId;
  final String uuid;
  final DateTime serviceDate;
  final MaintenanceType maintenanceType;
  final String location;
  final String hourMeter;
  final EquipmentInfo equipment;
  final List<InspectionChecklistEntry> checklist;
  final TestMeasurements tests;
  final String activitiesAndParts;
  final String observationsAndRecommendations;
  final TechnicianInfo technician;
  final String technicianSignaturePath;
  final ClientContactInfo clientContact;
  final ReportPhotos photos;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  MaintenanceReport copyWith({
    int? localId,
    String? uuid,
    DateTime? serviceDate,
    MaintenanceType? maintenanceType,
    String? location,
    String? hourMeter,
    EquipmentInfo? equipment,
    List<InspectionChecklistEntry>? checklist,
    TestMeasurements? tests,
    String? activitiesAndParts,
    String? observationsAndRecommendations,
    TechnicianInfo? technician,
    String? technicianSignaturePath,
    ClientContactInfo? clientContact,
    ReportPhotos? photos,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? syncedAt = _sentinel,
  }) {
    return MaintenanceReport(
      localId: localId ?? this.localId,
      uuid: uuid ?? this.uuid,
      serviceDate: serviceDate ?? this.serviceDate,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      location: location ?? this.location,
      hourMeter: hourMeter ?? this.hourMeter,
      equipment: equipment ?? this.equipment,
      checklist: checklist ?? this.checklist,
      tests: tests ?? this.tests,
      activitiesAndParts: activitiesAndParts ?? this.activitiesAndParts,
      observationsAndRecommendations: observationsAndRecommendations ??
          this.observationsAndRecommendations,
      technician: technician ?? this.technician,
      technicianSignaturePath:
          technicianSignaturePath ?? this.technicianSignaturePath,
      clientContact: clientContact ?? this.clientContact,
      photos: photos ?? this.photos,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: identical(syncedAt, _sentinel)
          ? this.syncedAt
          : syncedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'fecha_servicio': _formatDateOnly(serviceDate),
      'tipo_mantenimiento': maintenanceType.apiValue,
      'ubicacion_sede': location,
      'horometro_actual': hourMeter,
      'equipo': equipment.toJson(),
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'pruebas': tests.toJson(),
      'actividades_repuestos': activitiesAndParts,
      'observaciones_recomendaciones': observationsAndRecommendations,
      'tecnico': technician.toJson(),
      'firma_tecnico_ruta_local': technicianSignaturePath,
      'responsable_cliente': clientContact.toJson(),
      'fotos': photos.toJson(),
      'estado_sync': syncStatus.apiValue,
      'fecha_creacion': createdAt.toIso8601String(),
      'fecha_actualizacion': updatedAt.toIso8601String(),
      'fecha_sync': syncedAt?.toIso8601String(),
    };
  }

  factory MaintenanceReport.fromJson(
    Map<String, dynamic> json, {
    int? localId,
  }) {
    final equipmentJson = Map<String, dynamic>.from(
      (json['equipo'] ?? <String, dynamic>{}) as Map,
    );
    final testsJson = Map<String, dynamic>.from(
      (json['pruebas'] ?? <String, dynamic>{}) as Map,
    );
    final technicianJson = Map<String, dynamic>.from(
      (json['tecnico'] ?? <String, dynamic>{}) as Map,
    );
    final clientJson = Map<String, dynamic>.from(
      (json['responsable_cliente'] ?? <String, dynamic>{}) as Map,
    );
    final photosJson = Map<String, dynamic>.from(
      (json['fotos'] ?? <String, dynamic>{}) as Map,
    );
    final checklistJson = (json['checklist'] as List<dynamic>? ?? const []);

    return MaintenanceReport(
      localId: localId,
      uuid: (json['uuid'] ?? '') as String,
      serviceDate: DateTime.parse(
        (json['fecha_servicio'] ?? DateTime.now().toIso8601String()) as String,
      ),
      maintenanceType:
          MaintenanceType.fromApiValue(json['tipo_mantenimiento'] as String?),
      location: (json['ubicacion_sede'] ?? '') as String,
      hourMeter: (json['horometro_actual'] ?? '') as String,
      equipment: EquipmentInfo.fromJson(equipmentJson),
      checklist: checklistJson
          .map((item) => InspectionChecklistEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      tests: TestMeasurements.fromJson(testsJson),
      activitiesAndParts: (json['actividades_repuestos'] ?? '') as String,
      observationsAndRecommendations:
          (json['observaciones_recomendaciones'] ?? '') as String,
      technician: TechnicianInfo.fromJson(technicianJson),
      technicianSignaturePath:
          (json['firma_tecnico_ruta_local'] ?? '') as String,
      clientContact: ClientContactInfo.fromJson(clientJson),
      photos: ReportPhotos.fromJson(photosJson),
      syncStatus: SyncStatus.fromApiValue(json['estado_sync'] as String?),
      createdAt: DateTime.parse(
        (json['fecha_creacion'] ?? DateTime.now().toIso8601String()) as String,
      ),
      updatedAt: DateTime.parse(
        (json['fecha_actualizacion'] ?? DateTime.now().toIso8601String())
            as String,
      ),
      syncedAt: json['fecha_sync'] == null
          ? null
          : DateTime.parse(json['fecha_sync'] as String),
    );
  }

  static String _formatDateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

