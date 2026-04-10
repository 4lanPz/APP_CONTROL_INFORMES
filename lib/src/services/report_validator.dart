import '../domain/models/maintenance_report.dart';

class ReportValidator {
  List<String> validate(MaintenanceReport report) {
    final errors = <String>[];

    if (report.location.trim().isEmpty) {
      errors.add('La ubicación es obligatoria.');
    }
    if (report.hourMeter.trim().isEmpty) {
      errors.add('El horómetro actual es obligatorio.');
    }
    if (report.equipment.engineBrand.trim().isEmpty) {
      errors.add('La marca del motor es obligatoria.');
    }
    if (report.equipment.engineModel.trim().isEmpty) {
      errors.add('El modelo del motor es obligatorio.');
    }
    if (report.equipment.alternatorBrand.trim().isEmpty) {
      errors.add('La marca del alternador es obligatoria.');
    }
    if (report.equipment.power.trim().isEmpty) {
      errors.add('La potencia es obligatoria.');
    }
    if (report.equipment.serialNumber.trim().isEmpty) {
      errors.add('La serie del equipo es obligatoria.');
    }
    if (report.equipment.manufactureYear.trim().isEmpty) {
      errors.add('El año de fabricación es obligatorio.');
    }
    if (report.activitiesAndParts.trim().isEmpty) {
      errors.add('Las actividades y repuestos son obligatorios.');
    }
    if (report.observationsAndRecommendations.trim().isEmpty) {
      errors.add('Las observaciones y recomendaciones son obligatorias.');
    }
    if (report.technician.name.trim().isEmpty) {
      errors.add('El nombre del técnico es obligatorio.');
    }
    if (report.technician.identification.trim().isEmpty) {
      errors.add('La identificación del técnico es obligatoria.');
    }
    if (report.technicianSignaturePath.trim().isEmpty) {
      errors.add('La firma del técnico es obligatoria.');
    }
    if (report.clientSignaturePath.trim().isEmpty) {
      errors.add('La firma del cliente es obligatoria.');
    }
    if (report.clientContact.name.trim().isEmpty) {
      errors.add('El nombre del responsable es obligatorio.');
    }
    if (report.clientContact.role.trim().isEmpty) {
      errors.add('El cargo del responsable es obligatorio.');
    }
    if (!report.photos.isComplete) {
      errors.add('Debes adjuntar al menos una foto antes y una foto después.');
    }
    if (report.checklist.isEmpty) {
      errors.add('El checklist no puede estar vacío.');
    }

    for (final entry in report.checklist) {
      if (entry.state != InspectionState.notApplicable &&
          entry.observation.trim().isEmpty) {
        errors.add(
          'Cada ítem del checklist debe incluir observación: ${entry.system}.',
        );
        break;
      }
    }

    if (report.tests.voltageL1.trim().isEmpty ||
        report.tests.voltageL2.trim().isEmpty ||
        report.tests.voltageL3.trim().isEmpty) {
      errors.add('Los voltajes L1, L2 y L3 son obligatorios.');
    }
    if (report.tests.frequencyHz.trim().isEmpty) {
      errors.add('La frecuencia es obligatoria.');
    }
    if (report.tests.oilPressurePsi.trim().isEmpty) {
      errors.add('La presión de aceite es obligatoria.');
    }
    if (report.tests.temperatureC.trim().isEmpty) {
      errors.add('La temperatura es obligatoria.');
    }

    return errors;
  }
}
