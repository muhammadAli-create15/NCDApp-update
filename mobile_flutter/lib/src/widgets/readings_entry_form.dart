import 'package:flutter/material.dart';
import '../models/patient_reading.dart';
import '../services/supabase_readings_service.dart';
import 'dart:async';

/// Form widget for entering patient medical readings
class ReadingsEntryForm extends StatefulWidget {
  final PatientReading? initialReading;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const ReadingsEntryForm({
    super.key,
    this.initialReading,
    this.onSuccess,
    this.onError,
  });

  @override
  State<ReadingsEntryForm> createState() => _ReadingsEntryFormState();
}

class _ReadingsEntryFormState extends State<ReadingsEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers for all fields
  late final Map<String, TextEditingController> _controllers;
  
  // Focus nodes for navigation
  late final Map<String, FocusNode> _focusNodes;
  
  // Loading and validation states
  bool _isLoading = false;
  bool _autoCalculateBMI = true;
  
  // Patient name suggestions
  List<String> _patientSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPatientSuggestions();
  }

  void _initializeControllers() {
    _controllers = {};
    _focusNodes = {};
    
    for (final field in ReadingFields.allFields) {
      _controllers[field.key] = TextEditingController();
      _focusNodes[field.key] = FocusNode();
    }

    // Set initial values if editing
    if (widget.initialReading != null) {
      _setInitialValues(widget.initialReading!);
    }

    // Setup BMI auto-calculation listeners
    _controllers['height']!.addListener(_onHeightWeightChanged);
    _controllers['weight']!.addListener(_onHeightWeightChanged);
    
    // Setup patient name suggestions
    _controllers['name']!.addListener(_onPatientNameChanged);
  }

  void _setInitialValues(PatientReading reading) {
    _controllers['name']!.text = reading.name;
    _controllers['age']!.text = reading.age;
    _controllers['bloodPressure']!.text = reading.bloodPressure;
    _controllers['heartRate']!.text = reading.heartRate;
    _controllers['respiratoryRate']!.text = reading.respiratoryRate;
    _controllers['temperature']!.text = reading.temperature;
    _controllers['height']!.text = reading.height;
    _controllers['weight']!.text = reading.weight;
    _controllers['bmi']!.text = reading.bmi;
    _controllers['fastingBloodGlucose']!.text = reading.fastingBloodGlucose;
    _controllers['randomBloodGlucose']!.text = reading.randomBloodGlucose;
    _controllers['hba1c']!.text = reading.hba1c;
    _controllers['lipidProfile']!.text = reading.lipidProfile;
    _controllers['serumCreatinine']!.text = reading.serumCreatinine;
    _controllers['bloodUreaNitrogen']!.text = reading.bloodUreaNitrogen;
    _controllers['egfr']!.text = reading.egfr;
    _controllers['electrolytes']!.text = reading.electrolytes;
    _controllers['liverFunctionTests']!.text = reading.liverFunctionTests;
    _controllers['echocardiography']!.text = reading.echocardiography;
  }

  void _onHeightWeightChanged() {
    if (!_autoCalculateBMI) return;
    
    final height = _controllers['height']!.text;
    final weight = _controllers['weight']!.text;
    
    if (height.isNotEmpty && weight.isNotEmpty) {
      final bmi = ReadingValidator.calculateBMI(height, weight);
      if (bmi.isNotEmpty) {
        _controllers['bmi']!.text = bmi;
      }
    }
  }

  void _onPatientNameChanged() {
    final query = _controllers['name']!.text;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty && query.length >= 2) {
        _searchPatients(query);
      } else {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _loadPatientSuggestions() async {
    try {
      final suggestions = await SupabaseReadingsService.getPatientNames();
      if (mounted) {
        setState(() {
          _patientSuggestions = suggestions;
        });
      }
    } catch (e) {
      debugPrint('Error loading patient suggestions: $e');
    }
  }

  Future<void> _searchPatients(String query) async {
    try {
      final suggestions = await SupabaseReadingsService.getPatientNames(searchTerm: query);
      if (mounted) {
        setState(() {
          _patientSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error searching patients: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reading = PatientReading(
        id: widget.initialReading?.id,
        name: _controllers['name']!.text.trim(),
        age: _controllers['age']!.text.trim(),
        bloodPressure: _controllers['bloodPressure']!.text.trim(),
        heartRate: _controllers['heartRate']!.text.trim(),
        respiratoryRate: _controllers['respiratoryRate']!.text.trim(),
        temperature: _controllers['temperature']!.text.trim(),
        height: _controllers['height']!.text.trim(),
        weight: _controllers['weight']!.text.trim(),
        bmi: _controllers['bmi']!.text.trim(),
        fastingBloodGlucose: _controllers['fastingBloodGlucose']!.text.trim(),
        randomBloodGlucose: _controllers['randomBloodGlucose']!.text.trim(),
        hba1c: _controllers['hba1c']!.text.trim(),
        lipidProfile: _controllers['lipidProfile']!.text.trim(),
        serumCreatinine: _controllers['serumCreatinine']!.text.trim(),
        bloodUreaNitrogen: _controllers['bloodUreaNitrogen']!.text.trim(),
        egfr: _controllers['egfr']!.text.trim(),
        electrolytes: _controllers['electrolytes']!.text.trim(),
        liverFunctionTests: _controllers['liverFunctionTests']!.text.trim(),
        echocardiography: _controllers['echocardiography']!.text.trim(),
      );

      PatientReading? result;
      if (widget.initialReading?.id != null) {
        result = await SupabaseReadingsService.updateReading(reading);
      } else {
        result = await SupabaseReadingsService.insertReading(reading);
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialReading?.id != null
                  ? 'Reading updated successfully!'
                  : 'Reading saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onSuccess?.call();
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = 'Error saving reading: ${e.toString()}';
        widget.onError?.call(errorMessage);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _formKey.currentState?.reset();
  }

  void _calculateBMI() {
    final height = _controllers['height']!.text;
    final weight = _controllers['weight']!.text;
    
    if (height.isNotEmpty && weight.isNotEmpty) {
      final bmi = ReadingValidator.calculateBMI(height, weight);
      if (bmi.isNotEmpty) {
        _controllers['bmi']!.text = bmi;
        
        // Show BMI category
        final category = ReadingValidator.getBMICategory(bmi);
        if (category.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('BMI: $bmi ($category)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildTextField(ReadingField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient name field with suggestions
        if (field.key == 'name') ...[
          TextFormField(
            controller: _controllers[field.key],
            focusNode: _focusNodes[field.key],
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              prefixText: field.icon,
              border: const OutlineInputBorder(),
              suffixIcon: field.required 
                ? const Icon(Icons.star, color: Colors.red, size: 12)
                : null,
            ),
            validator: field.required
              ? (value) => value?.trim().isEmpty == true ? '${field.label} is required' : null
              : null,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (_) => _focusNodes['age']?.requestFocus(),
          ),
          if (_showSuggestions) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _patientSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _patientSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    onTap: () {
                      _controllers['name']!.text = suggestion;
                      setState(() {
                        _showSuggestions = false;
                      });
                      _focusNodes['age']?.requestFocus();
                    },
                  );
                },
              ),
            ),
          ],
        ] else if (field.key == 'bmi') ...[
          // BMI field with auto-calculate option
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers[field.key],
                  focusNode: _focusNodes[field.key],
                  decoration: InputDecoration(
                    labelText: field.label,
                    hintText: field.hint,
                    prefixText: field.icon,
                    suffixText: field.unit,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => ReadingValidator.validateNumeric(value, field.label, required: field.required),
                  onFieldSubmitted: (_) => _focusNodes['fastingBloodGlucose']?.requestFocus(),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: _calculateBMI,
                    icon: const Icon(Icons.calculate),
                    tooltip: 'Calculate BMI',
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _autoCalculateBMI,
                      onChanged: (value) {
                        setState(() {
                          _autoCalculateBMI = value;
                        });
                      },
                    ),
                  ),
                  const Text(
                    'Auto',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          // Regular text field
          TextFormField(
            controller: _controllers[field.key],
            focusNode: _focusNodes[field.key],
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              prefixText: field.icon,
              suffixText: field.unit,
              border: const OutlineInputBorder(),
              suffixIcon: field.required 
                ? const Icon(Icons.star, color: Colors.red, size: 12)
                : null,
            ),
            keyboardType: _getKeyboardType(field),
            textCapitalization: _getTextCapitalization(field),
            validator: (value) => ReadingValidator.validateNumeric(value, field.label, required: field.required),
            onFieldSubmitted: (_) => _focusNextField(field.key),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  TextInputType _getKeyboardType(ReadingField field) {
    if (field.key == 'name' || field.key == 'echocardiography' || 
        field.key == 'lipidProfile' || field.key == 'electrolytes' || 
        field.key == 'liverFunctionTests') {
      return TextInputType.text;
    }
    return const TextInputType.numberWithOptions(decimal: true);
  }

  TextCapitalization _getTextCapitalization(ReadingField field) {
    if (field.key == 'name') {
      return TextCapitalization.words;
    }
    return TextCapitalization.none;
  }

  void _focusNextField(String currentKey) {
    final fields = ReadingFields.allFields;
    final currentIndex = fields.indexWhere((f) => f.key == currentKey);
    if (currentIndex >= 0 && currentIndex < fields.length - 1) {
      final nextKey = fields[currentIndex + 1].key;
      _focusNodes[nextKey]?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialReading?.id != null ? 'Edit Reading' : 'New Reading'),
          actions: [
            TextButton(
              onPressed: _clearForm,
              child: const Text('Clear'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Form title
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.medical_information, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Patient Medical Reading',
                                            style: Theme.of(context).textTheme.headlineSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Enter patient vitals and medical measurements',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Required fields',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Form fields
                        ...ReadingFields.allFields.map(_buildTextField),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Submit button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.initialReading?.id != null ? 'Update Reading' : 'Save Reading',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    
    super.dispose();
  }
}