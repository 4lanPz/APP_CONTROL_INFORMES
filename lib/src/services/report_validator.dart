import '../domain/models/maintenance_report.dart';

/// Un error de validación asociado a un campo concreto del formulario.
///
/// [field] coincide con la clave (`fieldKey`) que usa `ReportFormScreen` para
/// resaltar el campo en rojo, y [message] es el texto explicativo.
class ReportValidationError {
  const ReportValidationError(this.field, this.message);

  final String field;
  final String message;
}

/// Valida un informe de mantenimiento.
///
/// Fuente ÚNICA de las reglas de campos obligatorios: tanto el bloqueo del
/// guardado como el resaltado de campos en rojo salen de aquí. Antes esta
/// lógica estaba duplicada entre este validador y el formulario.
class ReportValidator {
  List<ReportValidationError> validate(MaintenanceReport report) {
    final errors = <ReportValidationError>[];

    void requireText(String field, String value, String message) {
      if (value.trim().isEmpty) {
        errors.add(ReportValidationError(field, message));
      }
    }

    requireText('location', report.location, 'La ubicación es obligatoria.');
    requireText(
      'hour_meter',
      report.hourMeter,
      'El horómetro actual es obligatorio.',
    );
    requireText(
      'engine_brand',
      report.equipment.engineBrand,
      'La marca del motor es obligatoria.',
    );
    requireText(
      'engine_model',
      report.equipment.engineModel,
      'El modelo del motor es obligatorio.',
    );
    requireText(
      'alternator_brand',
      report.equipment.alternatorBrand,
      'La marca del alternador es obligatoria.',
    );
    requireText('power', report.equipment.power, 'La potencia es obligatoria.');
    requireText(
      'serial_number',
      report.equipment.serialNumber,
      'La serie del equipo es obligatoria.',
    );
    requireText(
      'manufacture_year',
      report.equipment.manufactureYear,
      'El año de fabricación es obligatorio.',
    );
    requireText(
      'voltage_l1',
      report.tests.voltageL1,
      'El voltaje L1 es obligatorio.',
    );
    requireText(
      'voltage_l2',
      report.tests.voltageL2,
      'El voltaje L2 es obligatorio.',
    );
    requireText(
      'voltage_l3',
      report.tests.voltageL3,
      'El voltaje L3 es obligatorio.',
    );
    requireText(
      'frequency_hz',
      report.tests.frequencyHz,
      'La frecuencia es obligatoria.',
    );
    requireText(
      'oil_pressure_psi',
      report.tests.oilPressurePsi,
      'La presión de aceite es obligatoria.',
    );
    requireText(
      'temperature_c',
      report.tests.temperatureC,
      'La temperatura es obligatoria.',
    );
    requireText(
      'activities',
      report.activitiesAndParts,
      'Las actividades y repuestos son obligatorios.',
    );
    requireText(
      'observations',
      report.observationsAndRecommendations,
      'Las observaciones y recomendaciones son obligatorias.',
    );
    requireText(
      'technician_name',
      report.technician.name,
      'El nombre del técnico es obligatorio.',
    );
    requireText(
      'technician_identification',
      report.technician.identification,
      'La identificación del técnico es obligatoria.',
    );
    requireText(
      'technician_signature',
      report.technicianSignaturePath,
      'La firma del técnico es obligatoria.',
    );
    requireText(
      'client_signature',
      report.clientSignaturePath,
      'La firma del cliente es obligatoria.',
    );
    requireText(
      'client_name',
      report.clientContact.name,
      'El nombre del responsable es obligatorio.',
    );
    requireText(
      'client_role',
      report.clientContact.role,
      'El cargo del responsable es obligatorio.',
    );

    if (report.photos.beforePaths.isEmpty) {
      errors.add(
        const ReportValidationError(
          'before_photo',
          'Debes adjuntar al menos una foto del antes.',
        ),
      );
    }
    if (report.photos.afterPaths.isEmpty) {
      errors.add(
        const ReportValidationError(
          'after_photo',
          'Debes adjuntar al menos una foto del estado final.',
        ),
      );
    }

    if (report.checklist.isEmpty) {
      errors.add(
        const ReportValidationError(
          'checklist',
          'El checklist no puede estar vacío.',
        ),
      );
    }

    for (var index = 0; index < report.checklist.length; index++) {
      final entry = report.checklist[index];
      if (entry.state != InspectionState.notApplicable &&
          entry.observation.trim().isEmpty) {
        errors.add(
          ReportValidationError(
            'checklist_observation_$index',
            'Cada ítem del checklist debe incluir observación: ${entry.system}.',
          ),
        );
      }
    }

    return errors;
  }
}
