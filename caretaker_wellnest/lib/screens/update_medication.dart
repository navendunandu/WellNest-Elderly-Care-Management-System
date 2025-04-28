import 'package:caretaker_wellnest/components/notification_service.dart';
import 'package:caretaker_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateMedication extends StatefulWidget {
  final String residentId;
  const UpdateMedication({super.key, required this.residentId});

  @override
  State<UpdateMedication> createState() => _UpdateMedicationState();
}

class _UpdateMedicationState extends State<UpdateMedication> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _foodtiming = TextEditingController();
  final TextEditingController _medicinecount = TextEditingController();

  String? _medicinetime = 'Before food';
  bool isLoading = false; // Changed to false initially

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });
    try {
      // Insert the medication into the database and get the inserted row
      final response = await supabase.from('tbl_medication').insert({
        'medication_timing': _foodtiming.text,
        'medication_count': _medicinecount.text,
        'medication_time': _medicinetime,
        'resident_id': widget.residentId,
      }).select().single(); // Fetch the inserted row

      // Use the medication_id from the response (assuming it exists)
      final medicationId = response['medication_id'] as int?;
      if (medicationId == null) {
        throw Exception('Failed to retrieve medication ID');
      }

      // Schedule the notification
      await _scheduleMedicationNotification(medicationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medication Added Successfully"),
          backgroundColor: Color.fromARGB(255, 0, 128, 0),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding medication: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scheduleMedicationNotification(int medicationId) async {
    try {
      int generateNotificationId(int id) {
      // Create a consistent numeric ID from the UUID and type
      return ('$id-medication')
          .hashCode
          .abs(); // Use absolute value to ensure positive
    }
      if (_foodtiming.text.isNotEmpty) {
      final title =
          'Medication: ${_medicinecount.text} pills $_medicinetime at ${_foodtiming.text}';
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(medicationId), // Use the database-generated ID
        title,
        _foodtiming.text,
      );
    }
    } catch (e) {
      print("Error scheduling notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error scheduling notification: $e"),
          backgroundColor: Color.fromARGB(255, 0, 36, 94)
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "Update Medication",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Set Medication",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 36, 94),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTimeField(
                      _foodtiming,
                      'Medicine Timing',
                      Icons.food_bank,
                    ),
                    _buildTextField(
                      _medicinecount,
                      'Total Pills',
                      Icons.medication_rounded,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Medicine Time",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'Before food',
                              groupValue: _medicinetime,
                              onChanged: (String? value) {
                                setState(() {
                                  _medicinetime = value;
                                });
                              },
                            ),
                            const Text('Before food'),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: 'After food',
                              groupValue: _medicinetime,
                              onChanged: (String? value) {
                                setState(() {
                                  _medicinetime = value;
                                });
                              },
                            ),
                            const Text('After food'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading ? null : submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a time';
          }
          return null;
        },
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            final formattedTime = DateFormat('HH:mm').format(
              DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute),
            );
            controller.text = formattedTime;
          }
        },
        readOnly: true,
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the number of pills';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}