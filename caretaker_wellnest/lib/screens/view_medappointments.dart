import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'update_medappointments.dart';
import 'package:caretaker_wellnest/components/notification_service.dart';

class ViewMedappointments extends StatefulWidget {
  String resident_id;
  ViewMedappointments({super.key, required this.resident_id});

  @override
  State<ViewMedappointments> createState() => _ViewMedappointmentsState();
}

class _ViewMedappointmentsState extends State<ViewMedappointments> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    final response = await supabase
        .from('tbl_appointment')
        .select()
        .eq('resident_id', widget.resident_id);
    setState(() {
      appointments = response;
    });

    // Schedule notifications for all fetched appointments
    //for (var appointment in appointments) {
    //   scheduleNotification(appointment);
    // }
  }

  // void scheduleNotification(Map<String, dynamic> appointment) {
  //   String doctorName = appointment['appointment_name'];
  //   String date = appointment['appointment_date']; // Format: YYYY-MM-DD
  //   String time = appointment['appointment_time']; // Format: HH:mm:ss
  //   DateTime appointmentDateTime = DateTime.parse("$date $time");

  //   // Schedule a notification 30 minutes before appointment
  //   DateTime reminderTime =
  //       appointmentDateTime.subtract(const Duration(minutes: 30));

  //   if (reminderTime.isAfter(DateTime.now())) {
  //     NotificationService.scheduleNotification(
  //       appointmentDateTime.millisecondsSinceEpoch ~/ 1000, // Unique ID
  //       "Appointment Reminder: Dr. $doctorName",
  //       reminderTime,
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'View Appointments',
          style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontWeight: FontWeight.bold,
              fontSize: 23),
        ),
        backgroundColor: Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            appointments.isEmpty
                ? const Center(child: Text("No Appointments Available"))
                : Expanded(
                    child: ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title:
                                Text("Dr. ${appointment['appointment_name']}"),
                            subtitle: Text(
                              "Date: ${appointment['appointment_date']}\n"
                              "Time: ${appointment['appointment_time']}",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 0, 36, 94), // Button color
                foregroundColor: Colors.white, // Text color
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Slightly rounded corners
                ),
                elevation: 5, // Adds a shadow effect
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UpdateMedappointments(
                          resident_id: widget.resident_id)),
                );
              },
              child: const Text(
                'Update Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
