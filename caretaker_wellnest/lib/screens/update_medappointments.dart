import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:caretaker_wellnest/main.dart';
import 'package:caretaker_wellnest/components/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class UpdateMedappointments extends StatefulWidget {
  final String resident_id;
  const UpdateMedappointments({super.key, required this.resident_id});

  @override
  State<UpdateMedappointments> createState() => _UpdateMedappointmentsState();
}

class _UpdateMedappointmentsState extends State<UpdateMedappointments> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _docNameController = TextEditingController();

  bool isLoading = false;

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = DateFormat('HH:mm').format(
          DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute),
        ); // Use 24-hour format for consistency
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Insert the appointment into the database and retrieve the ID
      final response = await supabase.from('tbl_appointment').insert({
        'appointment_date': _dateController.text,
        'appointment_time': _timeController.text,
        'appointment_name': _docNameController.text,
        'resident_id': widget.resident_id,
      }).select().single();

      final appointmentId = response['appointment_id'] as int?;
      if (appointmentId == null) {
        throw Exception('Failed to retrieve appointment ID');
      }

      final resident = await supabase
          .from('tbl_resident')
          .select()
          .eq('resident_id', widget.resident_id)
          .single();
      String residentName = resident['resident_name'] ?? "";
      // Schedule notifications
      await _scheduleAppointmentNotifications(appointmentId, residentName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment Added Successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scheduleAppointmentNotifications(int appointmentId, String name) async {
    // Parse the date and time
    final date = DateTime.parse(_dateController.text);
    final timeParts = _timeController.text.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Create the exact appointment time in the local timezone
    final appointmentDateTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    // Create the 3-hour prior notification time
    final reminderDateTime = appointmentDateTime.subtract(const Duration(hours: 3));

    // Schedule the exact appointment notification
    await RoutineNotificationService.scheduleOneTimeNotification(
      id: appointmentId, // Unique ID for the exact time notification
      title: 'Doctor Appointment for $name',
      body:
          'Appointment with Dr. ${_docNameController.text} at ${_timeController.text}',
      scheduledDate: appointmentDateTime,
    );

    // Schedule the 3-hour prior reminder (using a different ID)
    await RoutineNotificationService.scheduleOneTimeNotification(
      id: appointmentId + 10000, // Offset to avoid collision
      title: 'Upcoming Doctor Appointment',
      body:
          'Reminder: Appointment with Dr. ${_docNameController.text} in 3 hours at ${_timeController.text}',
      scheduledDate: reminderDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "Update Doctor Appointment",
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
                      "Set Doctor Appointment",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 56, 111),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: "Appointment Date",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      readOnly: true,
                      validator: (value) =>
                          value!.isEmpty ? "Please select a date" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: "Appointment Time",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: _selectTime,
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      readOnly: true,
                      validator: (value) =>
                          value!.isEmpty ? "Please select a time" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _docNameController,
                      decoration: const InputDecoration(
                        labelText: "Doctor's Name",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Please enter doctor's name" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (){
                        RoutineNotificationService.checkPendingNotifications();
                      },
                      // onPressed: isLoading ? null : submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Update Appointment',
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
}