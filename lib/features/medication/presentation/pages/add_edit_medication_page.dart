import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/entities/repetition_type.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class AddEditMedicationPage extends StatefulWidget {
  final Medication? medication;
  final bool isEditing;

  const AddEditMedicationPage({
    super.key,
    this.medication,
    required this.isEditing,
  });

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _posologyController = TextEditingController();
  final _repetitionIntervalController = TextEditingController(text: '1');

  String _imagePath = '';
  List<DateTime> _schedules = [];
  final List<TimeOfDay> _timePickers = [];
  DateTime? _firstDoseDate;

  RepetitionType _repetitionType = RepetitionType.none;
  int _repetitionInterval = 1;
  bool _isIndefinite = true;
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isPickerActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _posologyController.text = widget.medication!.posology;
      _imagePath = widget.medication!.imagePath;
      _schedules = List.from(widget.medication!.schedules);
      _timePickers.addAll(
          _schedules.map((dt) => TimeOfDay(hour: dt.hour, minute: dt.minute)));
      _firstDoseDate =
          widget.medication!.firstDoseDate ?? widget.medication!.createdAt;
      _repetitionType = widget.medication!.repetitionType;
      _repetitionInterval = widget.medication!.repetitionInterval ?? 1;
      _repetitionIntervalController.text = _repetitionInterval.toString();
      _isIndefinite = widget.medication!.indefinite;
      _endDate = widget.medication!.endDate ??
          DateTime.now().add(const Duration(days: 30));
    } else {
      _firstDoseDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _posologyController.dispose();
    _repetitionIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar Medicamento' : 'Nuevo Medicamento',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 8,
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _saveMedication,
              icon: const Icon(Icons.save),
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildPosologyField(),
                const SizedBox(height: 24),
                _buildSchedulesSection(),
                const SizedBox(height: 32),
                if (!widget.isEditing) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del Medicamento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: Colors.grey.shade50,
              ),
              child: _imagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const MedicationImagePlaceholder(
                              size: 200, iconSize: 80);
                        },
                      ),
                    )
                  : const MedicationImagePlaceholder(size: 200, iconSize: 80),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              _imagePath.isEmpty ? 'Seleccionar Imagen' : 'Cambiar Imagen',
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Nombre del Medicamento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.medication),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor ingresa el nombre del medicamento';
        }
        return null;
      },
      contextMenuBuilder:
          (BuildContext context, EditableTextState editableTextState) {
        return Container();
      },
    );
  }

  Widget _buildPosologyField() {
    return TextFormField(
      controller: _posologyController,
      decoration: const InputDecoration(
        labelText: 'Posología',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info),
        hintText: 'Ej: 1 comprimido cada 8 horas',
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor ingresa la posología';
        }
        return null;
      },
    );
  }

  Widget _buildSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Horarios de Toma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: _addTimePicker,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_timePickers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No hay horarios configurados',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timePickers.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    _timePickers[index].format(context),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeTimePicker(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar horario',
                  ),
                  onTap: () => _editTimePicker(index),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        ListTile(
          title: Text(
              'Fecha de primera toma: ${_firstDoseDate != null ? DateFormat('dd/MM/yyyy').format(_firstDoseDate!) : 'No establecida'}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickFirstDoseDate,
        ),
        const SizedBox(height: 24),
        const Text(
          'Frecuencia de la Toma',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<RepetitionType>(
          initialValue: _repetitionType,
          onChanged: (value) {
            setState(() {
              _repetitionType = value!;
            });
          },
          items: RepetitionType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getRepetitionTypeText(type)),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Repetir',
            border: OutlineInputBorder(),
          ),
        ),
        if (_repetitionType != RepetitionType.none) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _repetitionIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cada',
                    border: const OutlineInputBorder(),
                    suffixText: _getRepetitionTypeIntervalText(_repetitionType),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese un intervalo';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Intervalo no válido';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _repetitionInterval = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Sin fecha de fin'),
            value: _isIndefinite,
            onChanged: (value) {
              setState(() {
                _isIndefinite = value!;
              });
            },
          ),
          if (!_isIndefinite) ...[
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                  'Fecha de fin: ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickEndDate,
            ),
          ],
        ],
      ],
    );
  }

  String _getRepetitionTypeText(RepetitionType type) {
    switch (type) {
      case RepetitionType.none:
        return 'No repetir (dosis única)';
      case RepetitionType.daily:
        return 'Diariamente';
      case RepetitionType.weekly:
        return 'Semanalmente';
      case RepetitionType.monthly:
        return 'Mensualmente';
    }
  }

  String _getRepetitionTypeIntervalText(RepetitionType type) {
    switch (type) {
      case RepetitionType.daily:
        return _repetitionInterval == 1 ? 'día' : 'días';
      case RepetitionType.weekly:
        return _repetitionInterval == 1 ? 'semana' : 'semanas';
      case RepetitionType.monthly:
        return _repetitionInterval == 1 ? 'mes' : 'meses';
      default:
        return '';
    }
  }

  Future<void> _pickFirstDoseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _firstDoseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _firstDoseDate) {
      setState(() {
        _firstDoseDate = pickedDate;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _endDate) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveMedication,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Guardar Medicamento',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    setState(() {
      _isPickerActive = true;
    });

    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    _cropImage(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    _cropImage(image.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _isPickerActive = false;
      });
    });
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Recortar Imagen',
            toolbarColor: Colors.deepPurple.shade900,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Recortar Imagen',
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _imagePath = croppedFile.path;
      });
    }
  }

  void _addTimePicker() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _timePickers.add(time);
      });
    }
  }

  void _editTimePicker(int index) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _timePickers[index],
    );

    if (newTime != null) {
      setState(() {
        _timePickers[index] = newTime;
      });
    }
  }

  void _removeTimePicker(int index) {
    setState(() {
      _timePickers.removeAt(index);
    });
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_timePickers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos un horario de toma'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    _schedules = _timePickers.map((time) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }).toList();

    if (widget.isEditing && widget.medication != null) {
      final updatedMedication = widget.medication!.copyWith(
        name: _nameController.text.trim(),
        posology: _posologyController.text.trim(),
        imagePath: _imagePath,
        schedules: _schedules,
        firstDoseDate: _firstDoseDate,
        repetitionType: _repetitionType,
        repetitionInterval: _repetitionInterval,
        indefinite: _isIndefinite,
        endDate: _isIndefinite ? null : _endDate,
      );

      context
          .read<MedicationBloc>()
          .add(UpdateMedicationEvent(updatedMedication));
    } else {
      final newMedication = Medication(
        id: DateTime.now().toIso8601String(),
        name: _nameController.text.trim(),
        posology: _posologyController.text.trim(),
        imagePath: _imagePath,
        schedules: _schedules,
        createdAt: DateTime.now(),
        firstDoseDate: _firstDoseDate ?? DateTime.now(),
        repetitionType: _repetitionType,
        repetitionInterval: _repetitionInterval,
        indefinite: _isIndefinite,
        endDate: _isIndefinite ? null : _endDate,
      );
      context.read<MedicationBloc>().add(AddMedicationEvent(newMedication));
    }

    Navigator.pop(context);
  }
}
