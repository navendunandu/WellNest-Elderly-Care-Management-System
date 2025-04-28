import 'package:caretaker_wellnest/components/notification_service.dart';
import 'package:caretaker_wellnest/screens/update_medication.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ViewMedication extends StatefulWidget {
  final String residentId;
  const ViewMedication({super.key, required this.residentId});

  @override
  State<ViewMedication> createState() => _ViewMedicationState();
}

class _ViewMedicationState extends State<ViewMedication> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> medications = [];

  @override
  void initState() {
    super.initState();
    fetchMedications();
  }

  Future<void> fetchMedications() async {
    try {
      final response = await supabase
          .from('tbl_medication')
          .select()
          .eq('resident_id', widget.residentId);

      print("Supabase Response: $response"); // Debugging Output

      setState(() {
        medications = List<Map<String, dynamic>>.from(response);
      });

      if (medications.isEmpty) {
        print("No medications found in the database.");
      } else {
        print("Medications fetched successfully: $medications");
      }

      // Schedule notifications for medications
      // for (var medication in medications) {
      //   scheduleNotification(medication);
      // }
    } catch (error) {
      print("Error fetching medications: $error");
    }
  }

  Future<void> _cancelExistingNotifications(int mid) async {
    final notificationId = '$mid-medication'.hashCode;
    await RoutineNotificationService.cancelNotification(notificationId);
  }

  Future<void> deletemedication(int mid) async {
    try {
      final response = await supabase
          .from('tbl_medication')
          .delete()
          .eq('medication_id', mid);

      print("Supabase Response: $response"); // Debugging Output
      _cancelExistingNotifications(mid);
      setState(() {
        medications = List<Map<String, dynamic>>.from(response);
      });

      if (medications.isEmpty) {
        print("No medications found in the database.");
      } else {
        print("Medications fetched successfully: $medications");
      }
    } catch (error) {
      print("Error fetching medications: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'View Medication',
          style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            medications.isEmpty
                ? const Center(child: Text("No Medications Available"))
                : Expanded(
                    child: ListView.builder(
                      itemCount: medications.length,
                      itemBuilder: (context, index) {
                        final medication = medications[index];
                        String formattedTime = DateFormat('hh:mm a').format(
                            DateTime.parse(
                                "2000-01-01 ${medication['medication_timing']}"));
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                                "Medication: ${medication['medication_time']}"),
                            subtitle: Text(
                              "Time: $formattedTime\nCount: ${medication['medication_count']}",
                            ),
                            trailing: IconButton(
                                onPressed: () {
                                  deletemedication(medication['medication_id']);
                                  fetchMedications(); // Refresh the medication list
                                },
                                icon: Icon(Icons.delete,
                                    color: Color.fromARGB(255, 0, 36, 94))),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              onPressed: () async {
                bool? updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateMedication(residentId: widget.residentId),
                  ),
                );

                // Check if update was successful and refresh the data
                if (updated == true) {
                  fetchMedications(); // Refresh the medication list
                }
              },
              child: const Text(
                'Update Medication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
