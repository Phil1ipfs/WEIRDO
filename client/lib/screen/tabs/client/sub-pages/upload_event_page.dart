import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../services/event_service.dart';

class UploadEventPage extends StatefulWidget {
  const UploadEventPage({super.key});

  @override
  State<UploadEventPage> createState() => _UploadEventPageState();
}

class _UploadEventPageState extends State<UploadEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isDraft = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<Uint8List> _getDefaultImageBytes() async {
    final byteData = await rootBundle.load('assets/images/banner.png');
    return byteData.buffer.asUint8List();
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final bytes = _imageBytes ?? await _getDefaultImageBytes();

    final result = await EventService.uploadEvent(
      title: _titleController.text,
      date: _dateController.text,
      time: _timeController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      imageBytes: bytes,
      status: _isDraft ? 'draft' : 'upcoming',
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? icon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      suffixIcon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePreview = _imageBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _imageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/banner.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Event',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              imagePreview,
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB36CC6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title'),
                validator: (value) => value!.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _inputDecoration(
                      'Date',
                      icon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Date required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: _inputDecoration(
                  'Time (e.g. 08:00 AM)',
                  icon: const Icon(Icons.access_time),
                ),
                validator: (value) => value!.isEmpty ? 'Time required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isDraft,
                    onChanged: (val) => setState(() => _isDraft = val!),
                    activeColor: const Color(0xFFB36CC6),
                  ),
                  const Text("Save as Draft"),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitEvent,
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Event',
                          style: TextStyle(color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB36CC6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
}
