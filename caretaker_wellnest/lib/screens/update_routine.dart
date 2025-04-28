import 'package:caretaker_wellnest/components/notification_service.dart';
import 'package:caretaker_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for time formatting
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class UpdateRoutine extends StatefulWidget {
  String resident_id;
  UpdateRoutine({super.key, required this.resident_id});

  @override
  State<UpdateRoutine> createState() => _UpdateRoutineState();
}

class _UpdateRoutineState extends State<UpdateRoutine> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _waketime = TextEditingController();
  final TextEditingController _sleeptime = TextEditingController();
  final TextEditingController _breakfasttime = TextEditingController();
  final TextEditingController _lunchtime = TextEditingController();
  final TextEditingController _exercisetime = TextEditingController();
  final TextEditingController _dinnertime = TextEditingController();
  final TextEditingController _calltime = TextEditingController();

  bool isLoading = true;

  Future<void> submit() async {
    setState(() {
      isLoading = true;
    });
    try {
      _cancelExistingNotifications(widget.resident_id);
      await supabase.from('tbl_routine').insert({
        'routine_waketime': _waketime.text,
        'routine_sleeptime': _sleeptime.text,
        'routine_bftime': _breakfasttime.text,
        'routine_lunchtime': _lunchtime.text,
        'routine_dinnertime': _dinnertime.text,
        'routine_exercisetime': _exercisetime.text,
        'routine_calltime': _calltime.text,
        'resident_id': widget.resident_id
      });

      _scheduleRoutineNotifications(widget.resident_id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Updation Successful"),
          backgroundColor: Color.fromARGB(255, 86, 1, 1),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cancelExistingNotifications(String residentId) async {
    final routineTypes = [
      'wake',
      'sleep',
      'breakfast',
      'lunch',
      'exercise',
      'dinner',
      'call',
    ];
    for (var type in routineTypes) {
      final notificationId = '$residentId-$type'.hashCode;
      await RoutineNotificationService.cancelNotification(notificationId);
    }
  }

  Future<void> _scheduleRoutineNotifications(String residentId) async {

    int generateNotificationId(String residentId, String type) {
      // Create a consistent numeric ID from the UUID and type
      return ('$residentId-$type')
          .hashCode
          .abs(); // Use absolute value to ensure positive
    }

    if (_waketime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'wake'),
        'Wake Up Time ',
        _waketime.text,
      );
    }
    if (_sleeptime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'sleep'),
        'Sleep Time',
        _sleeptime.text,
      );
    }
    if (_breakfasttime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'breakfast'),
        'Breakfast Time',
        _breakfasttime.text,
      );
    }
    if (_lunchtime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'lunch'),
        'Lunch Time',
        _lunchtime.text,
      );
    }
    if (_exercisetime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'exercise'),
        'Exercise Time',
        _exercisetime.text,
      );
    }
    if (_dinnertime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'dinner'),
        'Dinner Time',
        _dinnertime.text,
      );
    }
    if (_calltime.text.isNotEmpty) {
      await RoutineNotificationService.scheduleNotification(
        generateNotificationId(residentId, 'call'),
        'Call Reminder Time',
        _calltime.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "Routine Setup",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
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
                      "Set Routine",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 36, 94)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_waketime, 'Wake Up Time', Icons.person),
                    _buildTextField(
                      _breakfasttime,
                      'Breakfast Time',
                      Icons.home,
                    ),
                    _buildTextField(
                      _lunchtime,
                      'Lunch Time',
                      Icons.lunch_dining,
                    ),
                    _buildTextField(_exercisetime, 'Exercise Time',
                        Icons.sports_gymnastics),
                    _buildTextField(
                      _calltime,
                      'Call Reminder Time',
                      Icons.call,
                    ),
                    _buildTextField(
                        _dinnertime, 'Dinner Time', Icons.dinner_dining),
                    _buildTextField(
                        _sleeptime, 'Bed Time', Icons.single_bed_sharp),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 0, 36, 94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        submit();
                      },
                      child: const Text(
                        'Update',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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
        onTap: () async {
          // Show time picker when the text field is tapped
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null) {
            // Format the selected time and set it to the text field
            final formattedTime = DateFormat('HH:mm').format(
              DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute),
            );
            controller.text = formattedTime;
          }
        },
      ),
    );
  }
}
