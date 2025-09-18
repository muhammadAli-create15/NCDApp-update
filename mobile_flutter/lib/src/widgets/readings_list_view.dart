import 'package:flutter/material.dart';
import '../models/patient_reading.dart';
import '../services/supabase_readings_service.dart';
import '../widgets/readings_entry_form.dart';
import 'dart:async';

/// Widget for displaying and searching patient readings
class ReadingsListView extends StatefulWidget {
  final String? initialSearchTerm;
  final VoidCallback? onRefresh;

  const ReadingsListView({
    super.key,
    this.initialSearchTerm,
    this.onRefresh,
  });

  @override
  State<ReadingsListView> createState() => _ReadingsListViewState();
}

class _ReadingsListViewState extends State<ReadingsListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<PatientReading> _readings = [];
  List<PatientReading> _filteredReadings = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  
  String _searchTerm = '';
  Timer? _debounceTimer;
  
  // Sorting and filtering
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchTerm != null) {
      _searchController.text = widget.initialSearchTerm!;
      _searchTerm = widget.initialSearchTerm!;
    }
    _loadReadings();
    _setupScrollListener();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreReadings();
      }
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newSearchTerm = _searchController.text.trim();
      if (newSearchTerm != _searchTerm) {
        setState(() {
          _searchTerm = newSearchTerm;
          _currentPage = 0;
          _hasMore = true;
        });
        _loadReadings(reset: true);
      }
    });
  }

  Future<void> _loadReadings({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _readings.clear();
        _filteredReadings.clear();
      }
    });

    try {
      List<PatientReading> newReadings;
      
      if (_searchTerm.isNotEmpty) {
        newReadings = await SupabaseReadingsService.searchReadings(
          searchTerm: _searchTerm,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        );
      } else {
        newReadings = await SupabaseReadingsService.getAllReadings(
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        );
      }

      if (mounted) {
        setState(() {
          if (reset || _currentPage == 0) {
            _readings = newReadings;
          } else {
            _readings.addAll(newReadings);
          }
          _hasMore = newReadings.length >= _pageSize;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading readings: ${e.toString()}'),
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

  Future<void> _loadMoreReadings() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadReadings();
  }

  void _applyFiltersAndSort() {
    List<PatientReading> filtered = List.from(_readings);

    // Apply filters
    if (_filterBy != 'all') {
      final now = DateTime.now();
      switch (_filterBy) {
        case 'today':
          filtered = filtered.where((reading) {
            if (reading.createdAt == null) return false;
            return reading.createdAt!.year == now.year &&
                   reading.createdAt!.month == now.month &&
                   reading.createdAt!.day == now.day;
          }).toList();
          break;
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          filtered = filtered.where((reading) {
            if (reading.createdAt == null) return false;
            return reading.createdAt!.isAfter(weekAgo);
          }).toList();
          break;
        case 'month':
          final monthAgo = now.subtract(const Duration(days: 30));
          filtered = filtered.where((reading) {
            if (reading.createdAt == null) return false;
            return reading.createdAt!.isAfter(monthAgo);
          }).toList();
          break;
      }
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'created_at':
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          result = a.createdAt!.compareTo(b.createdAt!);
          break;
        case 'age':
          final ageA = ReadingValidator.parseNumeric(a.age) ?? 0;
          final ageB = ReadingValidator.parseNumeric(b.age) ?? 0;
          result = ageA.compareTo(ageB);
          break;
      }
      return _sortAscending ? result : -result;
    });

    _filteredReadings = filtered;
  }

  Future<void> _refreshReadings() async {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
    });
    await _loadReadings(reset: true);
    widget.onRefresh?.call();
  }

  void _showSortFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortFilterSheet(),
    );
  }

  Widget _buildSortFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort & Filter Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Sort options
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Date'),
                  selected: _sortBy == 'created_at',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _sortBy = 'created_at');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Name'),
                  selected: _sortBy == 'name',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _sortBy = 'name');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Age'),
                  selected: _sortBy == 'age',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _sortBy = 'age');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _sortAscending,
              onChanged: (value) {
                setSheetState(() => _sortAscending = value);
              },
              dense: true,
            ),
            
            const SizedBox(height: 16),
            
            // Filter options
            Text(
              'Filter By Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterBy == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _filterBy = 'all');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _filterBy == 'today',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _filterBy = 'today');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('This Week'),
                  selected: _filterBy == 'week',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _filterBy = 'week');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('This Month'),
                  selected: _filterBy == 'month',
                  onSelected: (selected) {
                    if (selected) {
                      setSheetState(() => _filterBy = 'month');
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _applyFiltersAndSort();
                      });
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editReading(PatientReading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingsEntryForm(
          initialReading: reading,
          onSuccess: _refreshReadings,
        ),
      ),
    );
  }

  Future<void> _deleteReading(PatientReading reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: Text('Are you sure you want to delete ${reading.name}\'s reading from ${_formatDate(reading.createdAt)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && reading.id != null) {
      try {
        final success = await SupabaseReadingsService.deleteReading(reading.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshReadings();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete reading'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting reading: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showReadingDetails(PatientReading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReadingDetailView(reading: reading),
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildReadingCard(PatientReading reading) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _showReadingDetails(reading),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reading.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(reading.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _editReading(reading);
                          break;
                        case 'delete':
                          _deleteReading(reading);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Key vitals preview
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (reading.age.isNotEmpty)
                    _buildVitalChip('Age', reading.age, Icons.cake),
                  if (reading.bloodPressure.isNotEmpty)
                    _buildVitalChip('BP', reading.bloodPressure, Icons.favorite),
                  if (reading.heartRate.isNotEmpty)
                    _buildVitalChip('HR', reading.heartRate, Icons.monitor_heart),
                  if (reading.temperature.isNotEmpty)
                    _buildVitalChip('Temp', reading.temperature, Icons.thermostat),
                  if (reading.bmi.isNotEmpty)
                    _buildVitalChip('BMI', reading.bmi, Icons.accessibility),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search patients...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showSortFilterOptions,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Sort & Filter',
                  ),
                  IconButton(
                    onPressed: _refreshReadings,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_filteredReadings.length} reading${_filteredReadings.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_searchTerm.isNotEmpty || _filterBy != 'all') ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchTerm = '';
                          _filterBy = 'all';
                          _applyFiltersAndSort();
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Readings list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshReadings,
            child: _filteredReadings.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredReadings.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredReadings.length) {
                        return _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return _buildReadingCard(_filteredReadings[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchTerm.isNotEmpty
                ? 'No readings found for "$_searchTerm"'
                : 'No readings available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchTerm.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first patient reading',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Detail view for a single reading
class _ReadingDetailView extends StatelessWidget {
  final PatientReading reading;

  const _ReadingDetailView({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(reading.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadingsEntryForm(
                    initialReading: reading,
                    onSuccess: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          reading.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (reading.createdAt != null)
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Recorded on ${_formatDate(reading.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            
            // All readings data
            ...ReadingFields.allFields
                .where((field) => _getFieldValue(field.key).isNotEmpty)
                .map((field) => _buildDetailRow(context, field)),
          ],
        ),
      ),
    );
  }

  String _getFieldValue(String key) {
    switch (key) {
      case 'name': return reading.name;
      case 'age': return reading.age;
      case 'bloodPressure': return reading.bloodPressure;
      case 'heartRate': return reading.heartRate;
      case 'respiratoryRate': return reading.respiratoryRate;
      case 'temperature': return reading.temperature;
      case 'height': return reading.height;
      case 'weight': return reading.weight;
      case 'bmi': return reading.bmi;
      case 'fastingBloodGlucose': return reading.fastingBloodGlucose;
      case 'randomBloodGlucose': return reading.randomBloodGlucose;
      case 'hba1c': return reading.hba1c;
      case 'lipidProfile': return reading.lipidProfile;
      case 'serumCreatinine': return reading.serumCreatinine;
      case 'bloodUreaNitrogen': return reading.bloodUreaNitrogen;
      case 'egfr': return reading.egfr;
      case 'electrolytes': return reading.electrolytes;
      case 'liverFunctionTests': return reading.liverFunctionTests;
      case 'echocardiography': return reading.echocardiography;
      default: return '';
    }
  }

  Widget _buildDetailRow(BuildContext context, ReadingField field) {
    final value = _getFieldValue(field.key);
    if (value.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (field.unit.isNotEmpty)
                    Text(
                      field.unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}