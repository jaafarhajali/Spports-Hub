import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';

class StadiumFormScreen extends StatefulWidget {
  final Stadium? stadium; // null for create, Stadium object for edit
  
  const StadiumFormScreen({super.key, this.stadium});

  @override
  State<StadiumFormScreen> createState() => _StadiumFormScreenState();
}

class _StadiumFormScreenState extends State<StadiumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stadiumService = StadiumService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _penaltyHoursController = TextEditingController();
  final _penaltyAmountController = TextEditingController();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.stadium != null;
    
    if (_isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final stadium = widget.stadium!;
    _nameController.text = stadium.name;
    _locationController.text = stadium.location;
    
    // Format numbers properly to avoid decimal issues
    _priceController.text = stadium.pricePerMatch.toStringAsFixed(0);
    _maxPlayersController.text = stadium.maxPlayers.toString();
    _startTimeController.text = stadium.workingHours['start'] ?? '';
    _endTimeController.text = stadium.workingHours['end'] ?? '';
    
    // Handle penalty policy values safely
    final hoursBefore = stadium.penaltyPolicy['hoursBefore'];
    final penaltyAmount = stadium.penaltyPolicy['penaltyAmount'];
    
    _penaltyHoursController.text = (hoursBefore?.toInt() ?? 0).toString();
    _penaltyAmountController.text = (penaltyAmount?.toDouble() ?? 0.0).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxPlayersController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _penaltyHoursController.dispose();
    _penaltyAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(5).map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
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
      final workingHours = {
        'start': _startTimeController.text,
        'end': _endTimeController.text,
      };

      final penaltyPolicy = {
        'hoursBefore': int.tryParse(_penaltyHoursController.text) ?? 0,
        'penaltyAmount': double.tryParse(_penaltyAmountController.text) ?? 0.0,
      };

      if (_isEditMode) {
        await _stadiumService.updateStadium(
          stadiumId: widget.stadium!.id,
          name: _nameController.text,
          location: _locationController.text,
          pricePerMatch: double.tryParse(_priceController.text) ?? 0.0,
          maxPlayers: int.tryParse(_maxPlayersController.text) ?? 1,
          workingHours: workingHours,
          penaltyPolicy: penaltyPolicy,
          photos: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stadium updated successfully!')),
        );
      } else {
        await _stadiumService.createStadium(
          name: _nameController.text,
          location: _locationController.text,
          pricePerMatch: double.tryParse(_priceController.text) ?? 0.0,
          maxPlayers: int.tryParse(_maxPlayersController.text) ?? 1,
          workingHours: workingHours,
          penaltyPolicy: penaltyPolicy,
          photos: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stadium created successfully!')),
        );
      }

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Stadium' : 'Create Stadium'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                _isEditMode ? 'Update' : 'Create',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stadium Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Stadium Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stadium name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Price per Match
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Match (LBP)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                // Prevent multiple decimal points
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.split('.').length > 2) {
                    return oldValue;
                  }
                  return newValue;
                }),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                final doubleValue = double.tryParse(value);
                if (doubleValue == null) {
                  return 'Please enter a valid number';
                }
                if (doubleValue <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Max Players
            TextFormField(
              controller: _maxPlayersController,
              decoration: const InputDecoration(
                labelText: 'Maximum Players',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter maximum players';
                }
                final intValue = int.tryParse(value);
                if (intValue == null) {
                  return 'Please enter a valid number';
                }
                if (intValue <= 0) {
                  return 'Maximum players must be greater than 0';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Working Hours Section
            const Text(
              'Working Hours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_startTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_endTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select end time';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Penalty Policy Section
            const Text(
              'Penalty Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _penaltyHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours Before',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter hours';
                      }
                      final intValue = int.tryParse(value);
                      if (intValue == null || intValue < 0) {
                        return 'Please enter a valid number of hours';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _penaltyAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Penalty Amount (LBP)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      // Prevent multiple decimal points
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text;
                        if (text.split('.').length > 2) {
                          return oldValue;
                        }
                        return newValue;
                      }),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter penalty amount';
                      }
                      final doubleValue = double.tryParse(value);
                      if (doubleValue == null || doubleValue < 0) {
                        return 'Please enter a valid penalty amount';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Images Section
            const Text(
              'Stadium Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Image picker button
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(_selectedImages.isEmpty ? 'Select Images' : '${_selectedImages.length} images selected'),
            ),
            
            const SizedBox(height: 12),
            
            // Display selected images
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditMode ? 'Update Stadium' : 'Create Stadium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}