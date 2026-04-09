import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/report_workflow_service.dart';
import '../../domain/models/maintenance_report.dart';
import '../../services/report_file_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.reportService,
    this.initialReport,
  });

  final ReportWorkflowService reportService;
  final MaintenanceReport? initialReport;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late MaintenanceReport _workingReport;
  late DateTime _serviceDate;
  late MaintenanceType _maintenanceType;
  late bool _hasAbnormalNoiseOrVibration;
  late String _beforePhotoPath;
  late String _afterPhotoPath;

  late final TextEditingController _locationController;
  late final TextEditingController _hourMeterController;
  late final TextEditingController _engineBrandController;
  late final TextEditingController _engineModelController;
  late final TextEditingController _alternatorBrandController;
  late final TextEditingController _powerController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _manufactureYearController;
  late final TextEditingController _voltageL1Controller;
  late final TextEditingController _voltageL2Controller;
  late final TextEditingController _voltageL3Controller;
  late final TextEditingController _frequencyController;
  late final TextEditingController _oilPressureController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _activitiesController;
  late final TextEditingController _observationsController;
  late final TextEditingController _technicianNameController;
  late final TextEditingController _technicianIdController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientRoleController;

  late final List<TextEditingController> _checklistObservationControllers;
  late List<InspectionState> _checklistStates;

  bool _isSaving = false;
  ReportPhotoType? _photoBeingPicked;

  bool get _isEditing => widget.initialReport != null;

  @override
  void initState() {
    super.initState();

    _workingReport =
        widget.initialReport ?? widget.reportService.createEmptyReport();
    _serviceDate = _workingReport.serviceDate;
    _maintenanceType = _workingReport.maintenanceType;
    _hasAbnormalNoiseOrVibration =
        _workingReport.tests.hasAbnormalNoiseOrVibration;
    _beforePhotoPath = _workingReport.photos.beforePath;
    _afterPhotoPath = _workingReport.photos.afterPath;

    _locationController = TextEditingController(text: _workingReport.location);
    _hourMeterController =
        TextEditingController(text: _workingReport.hourMeter);
    _engineBrandController = TextEditingController(
      text: _workingReport.equipment.engineBrand,
    );
    _engineModelController = TextEditingController(
      text: _workingReport.equipment.engineModel,
    );
    _alternatorBrandController = TextEditingController(
      text: _workingReport.equipment.alternatorBrand,
    );
    _powerController =
        TextEditingController(text: _workingReport.equipment.power);
    _serialNumberController = TextEditingController(
      text: _workingReport.equipment.serialNumber,
    );
    _manufactureYearController = TextEditingController(
      text: _workingReport.equipment.manufactureYear,
    );
    _voltageL1Controller = TextEditingController(
      text: _workingReport.tests.voltageL1,
    );
    _voltageL2Controller = TextEditingController(
      text: _workingReport.tests.voltageL2,
    );
    _voltageL3Controller = TextEditingController(
      text: _workingReport.tests.voltageL3,
    );
    _frequencyController = TextEditingController(
      text: _workingReport.tests.frequencyHz,
    );
    _oilPressureController = TextEditingController(
      text: _workingReport.tests.oilPressurePsi,
    );
    _temperatureController = TextEditingController(
      text: _workingReport.tests.temperatureC,
    );
    _activitiesController = TextEditingController(
      text: _workingReport.activitiesAndParts,
    );
    _observationsController = TextEditingController(
      text: _workingReport.observationsAndRecommendations,
    );
    _technicianNameController = TextEditingController(
      text: _workingReport.technician.name,
    );
    _technicianIdController = TextEditingController(
      text: _workingReport.technician.identification,
    );
    _clientNameController = TextEditingController(
      text: _workingReport.clientContact.name,
    );
    _clientRoleController = TextEditingController(
      text: _workingReport.clientContact.role,
    );

    _checklistStates = _workingReport.checklist
        .map((entry) => entry.state)
        .toList(growable: false);
    _checklistObservationControllers = _workingReport.checklist
        .map((entry) => TextEditingController(text: entry.observation))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _hourMeterController.dispose();
    _engineBrandController.dispose();
    _engineModelController.dispose();
    _alternatorBrandController.dispose();
    _powerController.dispose();
    _serialNumberController.dispose();
    _manufactureYearController.dispose();
    _voltageL1Controller.dispose();
    _voltageL2Controller.dispose();
    _voltageL3Controller.dispose();
    _frequencyController.dispose();
    _oilPressureController.dispose();
    _temperatureController.dispose();
    _activitiesController.dispose();
    _observationsController.dispose();
    _technicianNameController.dispose();
    _technicianIdController.dispose();
    _clientNameController.dispose();
    _clientRoleController.dispose();

    for (final controller in _checklistObservationControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar informe' : 'Nuevo informe'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveReport,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar informe'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Datos generales',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Fecha del servicio'),
                subtitle: Text(_formatDate(_serviceDate)),
                trailing: TextButton(
                  onPressed: _pickServiceDate,
                  child: const Text('Cambiar'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MaintenanceType>(
                initialValue: _maintenanceType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de mantenimiento',
                  border: OutlineInputBorder(),
                ),
                items: MaintenanceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _maintenanceType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Ubicacion / sede',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hourMeterController,
                label: 'Horometro actual',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Identificacion del equipo',
            children: [
              _buildTextField(
                controller: _engineBrandController,
                label: 'Marca del motor',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _engineModelController,
                label: 'Modelo del motor',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _alternatorBrandController,
                label: 'Marca del alternador',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _powerController,
                label: 'Potencia (kVA/kW)',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _serialNumberController,
                label: 'Serie del equipo',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _manufactureYearController,
                label: 'Anio de fabricacion',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Checklist de inspeccion y tareas',
            children: List.generate(
              _workingReport.checklist.length,
              _buildChecklistItem,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Pruebas de funcionamiento',
            children: [
              _buildTextField(
                controller: _voltageL1Controller,
                label: 'Voltaje L1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _voltageL2Controller,
                label: 'Voltaje L2',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _voltageL3Controller,
                label: 'Voltaje L3',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _frequencyController,
                label: 'Frecuencia (Hz)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _oilPressureController,
                label: 'Presion de aceite (PSI)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _temperatureController,
                label: 'Temperatura (C)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ruidos o vibraciones anormales'),
                subtitle: Text(_hasAbnormalNoiseOrVibration ? 'Si' : 'No'),
                value: _hasAbnormalNoiseOrVibration,
                onChanged: (value) {
                  setState(() {
                    _hasAbnormalNoiseOrVibration = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Actividades / repuestos',
            children: [
              _buildTextField(
                controller: _activitiesController,
                label: 'Descripcion de actividades / repuestos utilizados',
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Observaciones y recomendaciones',
            children: [
              _buildTextField(
                controller: _observationsController,
                label: 'Observaciones y recomendaciones',
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Validacion',
            children: [
              _buildTextField(
                controller: _technicianNameController,
                label: 'Nombre del tecnico',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _technicianIdController,
                label: 'Identificacion del tecnico',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _clientNameController,
                label: 'Nombre del responsable / cliente',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _clientRoleController,
                label: 'Cargo del responsable / cliente',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Fotos',
            children: [
              _buildPhotoSelector(
                title: 'Foto antes',
                path: _beforePhotoPath,
                type: ReportPhotoType.before,
              ),
              const SizedBox(height: 16),
              _buildPhotoSelector(
                title: 'Foto despues',
                path: _afterPhotoPath,
                type: ReportPhotoType.after,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Informe existente' : 'Nuevo informe real',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('UUID: ${_workingReport.uuid}'),
            const SizedBox(height: 4),
            Text('Estado actual: ${_workingReport.syncStatus.label}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final entry = _workingReport.checklist[index];

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _workingReport.checklist.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.system,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(entry.item),
          const SizedBox(height: 12),
          DropdownButtonFormField<InspectionState>(
            initialValue: _checklistStates[index],
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: InspectionState.values
                .map(
                  (state) => DropdownMenuItem(
                    value: state,
                    child: Text(state.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _checklistStates[index] = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _checklistObservationControllers[index],
            label: 'Observacion',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSelector({
    required String title,
    required String path,
    required ReportPhotoType type,
  }) {
    final isBusy = _photoBeingPicked == type;
    final hasImage = path.trim().isNotEmpty && File(path).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: hasImage
              ? Image.file(File(path), fit: BoxFit.cover)
              : const Center(child: Text('Imagen no seleccionada')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pickPhoto(type),
          icon: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(isBusy ? 'Cargando...' : 'Elegir desde galeria'),
        ),
        if (path.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            path,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _pickServiceDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _serviceDate = selected;
    });
  }

  Future<void> _pickPhoto(ReportPhotoType type) async {
    setState(() {
      _photoBeingPicked = type;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      final updatedReport = await widget.reportService.attachPhoto(
        report: _buildReportFromFields(),
        sourcePath: pickedFile.path,
        type: type,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _workingReport = updatedReport;
        _beforePhotoPath = updatedReport.photos.beforePath;
        _afterPhotoPath = updatedReport.photos.afterPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la foto: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _photoBeingPicked = null;
        });
      }
    }
  }

  Future<void> _saveReport() async {
    final report = _buildReportFromFields();
    final errors = widget.reportService.validateReport(report);

    if (errors.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Completa el informe'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors
                      .map(
                        (error) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('- $error'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedReport = await widget.reportService.saveReport(report);
      if (!mounted) {
        return;
      }

      _workingReport = savedReport;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el informe: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  MaintenanceReport _buildReportFromFields() {
    final checklist = List<InspectionChecklistEntry>.generate(
      _workingReport.checklist.length,
      (index) => _workingReport.checklist[index].copyWith(
        state: _checklistStates[index],
        observation: _checklistObservationControllers[index].text.trim(),
      ),
    );

    return _workingReport.copyWith(
      serviceDate: _serviceDate,
      maintenanceType: _maintenanceType,
      location: _locationController.text.trim(),
      hourMeter: _hourMeterController.text.trim(),
      equipment: _workingReport.equipment.copyWith(
        engineBrand: _engineBrandController.text.trim(),
        engineModel: _engineModelController.text.trim(),
        alternatorBrand: _alternatorBrandController.text.trim(),
        power: _powerController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        manufactureYear: _manufactureYearController.text.trim(),
      ),
      checklist: checklist,
      tests: _workingReport.tests.copyWith(
        voltageL1: _voltageL1Controller.text.trim(),
        voltageL2: _voltageL2Controller.text.trim(),
        voltageL3: _voltageL3Controller.text.trim(),
        frequencyHz: _frequencyController.text.trim(),
        oilPressurePsi: _oilPressureController.text.trim(),
        temperatureC: _temperatureController.text.trim(),
        hasAbnormalNoiseOrVibration: _hasAbnormalNoiseOrVibration,
      ),
      activitiesAndParts: _activitiesController.text.trim(),
      observationsAndRecommendations: _observationsController.text.trim(),
      technician: _workingReport.technician.copyWith(
        name: _technicianNameController.text.trim(),
        identification: _technicianIdController.text.trim(),
      ),
      clientContact: _workingReport.clientContact.copyWith(
        name: _clientNameController.text.trim(),
        role: _clientRoleController.text.trim(),
      ),
      photos: _workingReport.photos.copyWith(
        beforePath: _beforePhotoPath,
        afterPath: _afterPhotoPath,
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
