import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/report_workflow_service.dart';
import '../../domain/models/maintenance_report.dart';
import '../../services/editing_session_service.dart';
import '../../services/report_file_service.dart';
import '../widgets/draft_app_bar_title.dart';
import 'signature_capture_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.reportService,
    required this.editingSessionService,
    this.initialReport,
  });

  final ReportWorkflowService reportService;
  final EditingSessionService editingSessionService;
  final MaintenanceReport? initialReport;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen>
    with WidgetsBindingObserver {
  static const Duration _autoSaveDelay = Duration(milliseconds: 700);

  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _invalidFields = <String>{};

  late MaintenanceReport _workingReport;
  late DateTime _serviceDate;
  late MaintenanceType _maintenanceType;
  late bool _hasAbnormalNoiseOrVibration;
  late List<String> _beforePhotoPaths;
  late List<String> _afterPhotoPaths;
  late String _technicianSignaturePath;

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
  bool _isAutoSaving = false;
  bool _hasPendingChanges = false;
  ReportPhotoType? _photoBeingPicked;
  Timer? _autoSaveTimer;

  bool get _isEditing => widget.initialReport != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _workingReport =
        widget.initialReport ?? widget.reportService.createEmptyReport();
    _serviceDate = _workingReport.serviceDate;
    _maintenanceType = _workingReport.maintenanceType;
    _hasAbnormalNoiseOrVibration =
        _workingReport.tests.hasAbnormalNoiseOrVibration;
    _beforePhotoPaths = List<String>.from(_workingReport.photos.beforePaths);
    _afterPhotoPaths = List<String>.from(_workingReport.photos.afterPaths);
    _technicianSignaturePath = _workingReport.technicianSignaturePath;

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

    _registerAutoSaveListeners();
    unawaited(
      widget.editingSessionService.saveActiveReportUuid(_workingReport.uuid),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    unawaited(widget.editingSessionService.clearActiveReportUuid());
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistDraft(immediate: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DraftAppBarTitle(
          _isEditing ? 'Editar formulario' : 'Nuevo formulario',
        ),
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
                  _markFormChanged();
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Ubicación / sede',
                fieldKey: 'location',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hourMeterController,
                label: 'Horómetro actual',
                fieldKey: 'hour_meter',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Identificación del equipo',
            children: [
              _buildTextField(
                controller: _engineBrandController,
                label: 'Marca del motor',
                fieldKey: 'engine_brand',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _engineModelController,
                label: 'Modelo del motor',
                fieldKey: 'engine_model',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _alternatorBrandController,
                label: 'Marca del alternador',
                fieldKey: 'alternator_brand',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _powerController,
                label: 'Potencia (kVA/kW)',
                fieldKey: 'power',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _serialNumberController,
                label: 'Serie del equipo',
                fieldKey: 'serial_number',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _manufactureYearController,
                label: 'Año de fabricación',
                fieldKey: 'manufacture_year',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Checklist de inspección y tareas',
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
                fieldKey: 'voltage_l1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _voltageL2Controller,
                label: 'Voltaje L2',
                fieldKey: 'voltage_l2',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _voltageL3Controller,
                label: 'Voltaje L3',
                fieldKey: 'voltage_l3',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _frequencyController,
                label: 'Frecuencia (Hz)',
                fieldKey: 'frequency_hz',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _oilPressureController,
                label: 'Presión de aceite (PSI)',
                fieldKey: 'oil_pressure_psi',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _temperatureController,
                label: 'Temperatura (C)',
                fieldKey: 'temperature_c',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ruidos o vibraciones anormales'),
                subtitle: Text(_hasAbnormalNoiseOrVibration ? 'Sí' : 'No'),
                value: _hasAbnormalNoiseOrVibration,
                onChanged: (value) {
                  setState(() {
                    _hasAbnormalNoiseOrVibration = value;
                  });
                  _markFormChanged();
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
                label: 'Descripción de actividades / repuestos utilizados',
                fieldKey: 'activities',
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Validación',
            children: [
              _buildTextField(
                controller: _technicianNameController,
                label: 'Nombre del técnico',
                fieldKey: 'technician_name',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _technicianIdController,
                label: 'Identificación del técnico',
                fieldKey: 'technician_identification',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _clientNameController,
                label: 'Nombre del responsable / cliente',
                fieldKey: 'client_name',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _clientRoleController,
                label: 'Cargo del responsable / cliente',
                fieldKey: 'client_role',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Fotos',
            children: [
              _buildPhotoSelector(
                title: 'Antes del Servicio',
                paths: _beforePhotoPaths,
                type: ReportPhotoType.before,
              ),
              const SizedBox(height: 16),
              _buildPhotoSelector(
                title: 'Estado Final',
                paths: _afterPhotoPaths,
                type: ReportPhotoType.after,
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
                fieldKey: 'observations',
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Firma del técnico',
            children: [
              _buildTechnicianSignatureField(),
            ],
          ),
        ],
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
    required String fieldKey,
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
        errorText: _hasFieldError(fieldKey) ? 'Campo obligatorio' : null,
      ),
      onChanged: (value) {
        if (value.trim().isNotEmpty) {
          _clearFieldError(fieldKey);
        }
        _markFormChanged();
      },
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
              _markFormChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _checklistObservationControllers[index],
            label: 'Observación',
            fieldKey: 'checklist_observation_$index',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSelector({
    required String title,
    required List<String> paths,
    required ReportPhotoType type,
  }) {
    final isBusy = _photoBeingPicked == type;
    final hasError = _hasFieldError(_photoFieldKey(type));
    final helperText = paths.isEmpty
        ? 'Aún no agregas imágenes.'
        : 'Mantén presionado el ícono para arrastrar y ordenar.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pickPhotos(type),
          icon: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(isBusy ? 'Cargando...' : 'Agregar desde galería'),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outlineVariant,
              width: hasError ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${paths.length} ${paths.length == 1 ? 'imagen cargada' : 'imágenes cargadas'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                helperText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (paths.isNotEmpty) ...[
                const SizedBox(height: 12),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paths.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderPhotos(type, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    return _buildPhotoListItem(
                      key: ValueKey('${type.name}-$path'),
                      type: type,
                      index: index,
                      path: path,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        if (hasError && paths.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Agrega al menos una imagen en esta sección.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoListItem({
    required Key key,
    required ReportPhotoType type,
    required int index,
    required String path,
  }) {
    final file = File(path);
    final exists = file.existsSync();

    return Container(
      key: key,
      margin: EdgeInsets.only(
        bottom: index == _photoPathsFor(type).length - 1 ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 58,
            height: 58,
            child: exists
                ? Image.file(file, fit: BoxFit.cover)
                : ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        title: Text('Imagen ${index + 1}'),
        subtitle: Text(
          exists ? _fileNameFromPath(path) : 'Archivo no disponible',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Quitar foto',
              onPressed: () => _removePhoto(type, index),
              icon: const Icon(Icons.delete_outline),
            ),
            ReorderableDelayedDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianSignatureField() {
    final hasError = _hasFieldError('technician_signature');
    final signatureFile = File(_technicianSignaturePath);
    final hasSignature =
        _technicianSignaturePath.trim().isNotEmpty && signatureFile.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openTechnicianSignatureModal,
          child: Ink(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outlineVariant,
                width: hasError ? 1.6 : 1,
              ),
            ),
            child: hasSignature
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.file(
                      signatureFile,
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.draw_outlined,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text('Toca para agregar la firma'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasSignature
              ? 'Toca el recuadro para actualizar la firma.'
              : 'Toca el recuadro para abrir el modal de firma.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            'La firma del técnico es obligatoria.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
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
    _markFormChanged();
  }

  Future<void> _pickPhotos(ReportPhotoType type) async {
    setState(() {
      _photoBeingPicked = type;
    });

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty || !mounted) {
        return;
      }

      final updatedReport = await widget.reportService.attachPhotos(
        report: _buildReportFromFields(),
        sourcePaths: pickedFiles.map((file) => file.path).toList(growable: false),
        type: type,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _workingReport = updatedReport;
        _beforePhotoPaths = List<String>.from(updatedReport.photos.beforePaths);
        _afterPhotoPaths = List<String>.from(updatedReport.photos.afterPaths);
      });
      _clearFieldError(_photoFieldKey(type));
      _markFormChanged(immediate: true);
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
    _autoSaveTimer?.cancel();
    final report = _buildReportFromFields();
    final errors = widget.reportService.validateReport(report);
    final invalidFieldKeys = _collectInvalidFieldKeys(report);

    if (errors.isNotEmpty) {
      setState(() {
        _invalidFields
          ..clear()
          ..addAll(invalidFieldKeys);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos marcados en rojo.'),
        ),
      );
      return;
    }

    _invalidFields.clear();

    setState(() {
      _isSaving = true;
    });

    try {
      final savedReport = await widget.reportService.saveReport(report);
      if (!mounted) {
        return;
      }

      _workingReport = savedReport;
      _hasPendingChanges = false;
      await widget.editingSessionService.clearActiveReportUuid();
      if (!mounted) {
        return;
      }
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

  Future<void> _openTechnicianSignatureModal() async {
    final signatureBytes = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: SignatureCaptureScreen(),
      ),
    );

    if (!mounted || signatureBytes == null) {
      return;
    }

    try {
      final updatedReport = await widget.reportService.attachTechnicianSignature(
        report: _buildReportFromFields(),
        bytes: signatureBytes,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _workingReport = updatedReport;
        _technicianSignaturePath = updatedReport.technicianSignaturePath;
      });
      _clearFieldError('technician_signature');
      _markFormChanged(immediate: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la firma: $error'),
        ),
      );
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
      technicianSignaturePath: _technicianSignaturePath,
      photos: _workingReport.photos.copyWith(
        beforePaths: List<String>.from(_beforePhotoPaths),
        afterPaths: List<String>.from(_afterPhotoPaths),
      ),
    );
  }

  void _registerAutoSaveListeners() {
    final controllers = <TextEditingController>[
      _locationController,
      _hourMeterController,
      _engineBrandController,
      _engineModelController,
      _alternatorBrandController,
      _powerController,
      _serialNumberController,
      _manufactureYearController,
      _voltageL1Controller,
      _voltageL2Controller,
      _voltageL3Controller,
      _frequencyController,
      _oilPressureController,
      _temperatureController,
      _activitiesController,
      _observationsController,
      _technicianNameController,
      _technicianIdController,
      _clientNameController,
      _clientRoleController,
      ..._checklistObservationControllers,
    ];

    for (final controller in controllers) {
      controller.addListener(_markFormChanged);
    }
  }

  void _markFormChanged({bool immediate = false}) {
    _hasPendingChanges = true;
    _autoSaveTimer?.cancel();

    if (immediate) {
      unawaited(_persistDraft(immediate: true));
      return;
    }

    _autoSaveTimer = Timer(_autoSaveDelay, () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft({bool immediate = false}) async {
    if (_isSaving || _isAutoSaving) {
      return;
    }

    if (!_hasPendingChanges && !immediate) {
      return;
    }

    final report = _buildReportFromFields();
    if (!_shouldPersistDraft(report)) {
      return;
    }

    _isAutoSaving = true;
    try {
      final savedReport = await widget.reportService.saveReport(report);
      _workingReport = savedReport;
      _hasPendingChanges = false;
    } catch (_) {
      _hasPendingChanges = true;
    } finally {
      _isAutoSaving = false;
    }
  }

  bool _shouldPersistDraft(MaintenanceReport report) {
    if (report.location.trim().isNotEmpty ||
        report.hourMeter.trim().isNotEmpty ||
        report.equipment.engineBrand.trim().isNotEmpty ||
        report.equipment.engineModel.trim().isNotEmpty ||
        report.equipment.alternatorBrand.trim().isNotEmpty ||
        report.equipment.power.trim().isNotEmpty ||
        report.equipment.serialNumber.trim().isNotEmpty ||
        report.equipment.manufactureYear.trim().isNotEmpty ||
        report.tests.voltageL1.trim().isNotEmpty ||
        report.tests.voltageL2.trim().isNotEmpty ||
        report.tests.voltageL3.trim().isNotEmpty ||
        report.tests.frequencyHz.trim().isNotEmpty ||
        report.tests.oilPressurePsi.trim().isNotEmpty ||
        report.tests.temperatureC.trim().isNotEmpty ||
        report.tests.hasAbnormalNoiseOrVibration ||
        report.activitiesAndParts.trim().isNotEmpty ||
        report.observationsAndRecommendations.trim().isNotEmpty ||
        report.technician.name.trim().isNotEmpty ||
        report.technician.identification.trim().isNotEmpty ||
        report.technicianSignaturePath.trim().isNotEmpty ||
        report.clientContact.name.trim().isNotEmpty ||
        report.clientContact.role.trim().isNotEmpty ||
        report.photos.beforePaths.isNotEmpty ||
        report.photos.afterPaths.isNotEmpty) {
      return true;
    }

    return report.checklist.any(
      (entry) =>
          entry.state != InspectionState.notApplicable ||
          entry.observation.trim().isNotEmpty,
    );
  }

  Set<String> _collectInvalidFieldKeys(MaintenanceReport report) {
    final invalidFields = <String>{};

    if (report.location.trim().isEmpty) {
      invalidFields.add('location');
    }
    if (report.hourMeter.trim().isEmpty) {
      invalidFields.add('hour_meter');
    }
    if (report.equipment.engineBrand.trim().isEmpty) {
      invalidFields.add('engine_brand');
    }
    if (report.equipment.engineModel.trim().isEmpty) {
      invalidFields.add('engine_model');
    }
    if (report.equipment.alternatorBrand.trim().isEmpty) {
      invalidFields.add('alternator_brand');
    }
    if (report.equipment.power.trim().isEmpty) {
      invalidFields.add('power');
    }
    if (report.equipment.serialNumber.trim().isEmpty) {
      invalidFields.add('serial_number');
    }
    if (report.equipment.manufactureYear.trim().isEmpty) {
      invalidFields.add('manufacture_year');
    }
    if (report.tests.voltageL1.trim().isEmpty) {
      invalidFields.add('voltage_l1');
    }
    if (report.tests.voltageL2.trim().isEmpty) {
      invalidFields.add('voltage_l2');
    }
    if (report.tests.voltageL3.trim().isEmpty) {
      invalidFields.add('voltage_l3');
    }
    if (report.tests.frequencyHz.trim().isEmpty) {
      invalidFields.add('frequency_hz');
    }
    if (report.tests.oilPressurePsi.trim().isEmpty) {
      invalidFields.add('oil_pressure_psi');
    }
    if (report.tests.temperatureC.trim().isEmpty) {
      invalidFields.add('temperature_c');
    }
    if (report.activitiesAndParts.trim().isEmpty) {
      invalidFields.add('activities');
    }
    if (report.observationsAndRecommendations.trim().isEmpty) {
      invalidFields.add('observations');
    }
    if (report.technician.name.trim().isEmpty) {
      invalidFields.add('technician_name');
    }
    if (report.technician.identification.trim().isEmpty) {
      invalidFields.add('technician_identification');
    }
    if (report.technicianSignaturePath.trim().isEmpty) {
      invalidFields.add('technician_signature');
    }
    if (report.clientContact.name.trim().isEmpty) {
      invalidFields.add('client_name');
    }
    if (report.clientContact.role.trim().isEmpty) {
      invalidFields.add('client_role');
    }
    if (report.photos.beforePaths.isEmpty) {
      invalidFields.add(_photoFieldKey(ReportPhotoType.before));
    }
    if (report.photos.afterPaths.isEmpty) {
      invalidFields.add(_photoFieldKey(ReportPhotoType.after));
    }

    for (var index = 0; index < report.checklist.length; index++) {
      if (report.checklist[index].state != InspectionState.notApplicable &&
          report.checklist[index].observation.trim().isEmpty) {
        invalidFields.add('checklist_observation_$index');
      }
    }

    return invalidFields;
  }

  bool _hasFieldError(String fieldKey) => _invalidFields.contains(fieldKey);

  void _clearFieldError(String fieldKey) {
    if (_invalidFields.remove(fieldKey)) {
      setState(() {});
    }
  }

  String _photoFieldKey(ReportPhotoType type) {
    return type == ReportPhotoType.before ? 'before_photo' : 'after_photo';
  }

  List<String> _photoPathsFor(ReportPhotoType type) {
    return type == ReportPhotoType.before
        ? _beforePhotoPaths
        : _afterPhotoPaths;
  }

  void _reorderPhotos(ReportPhotoType type, int oldIndex, int newIndex) {
    final updatedPaths = List<String>.from(_photoPathsFor(type));
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = updatedPaths.removeAt(oldIndex);
    updatedPaths.insert(newIndex, moved);

    setState(() {
      _updatePhotoPaths(type, updatedPaths);
    });
    _markFormChanged(immediate: true);
  }

  void _removePhoto(ReportPhotoType type, int index) {
    final updatedPaths = List<String>.from(_photoPathsFor(type));
    updatedPaths.removeAt(index);

    setState(() {
      _updatePhotoPaths(type, updatedPaths);
    });
    _markFormChanged(immediate: true);
  }

  void _updatePhotoPaths(ReportPhotoType type, List<String> paths) {
    if (type == ReportPhotoType.before) {
      _beforePhotoPaths = paths;
      _workingReport = _workingReport.copyWith(
        photos: _workingReport.photos.copyWith(beforePaths: paths),
      );
      return;
    }

    _afterPhotoPaths = paths;
    _workingReport = _workingReport.copyWith(
      photos: _workingReport.photos.copyWith(afterPaths: paths),
    );
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final lastSeparator = normalized.lastIndexOf('/');
    if (lastSeparator == -1) {
      return normalized;
    }
    return normalized.substring(lastSeparator + 1);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
