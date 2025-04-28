import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewMedappointments extends StatefulWidget {
  final String profile; // Made final since it’s immutable
  const ViewMedappointments({super.key, required this.profile});

  @override
  State<ViewMedappointments> createState() => _ViewMedappointmentsState();
}

class _ViewMedappointmentsState extends State<ViewMedappointments> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments(); // Fetch data when the widget initializes
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await supabase
          .from('tbl_appointment')
          .select()
          .eq('resident_id', widget.profile) // Assuming profile is resident_id
          .order('appointment_date',
              ascending: false); // Optional: sort by date
      setState(() {
        appointments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() {
        appointments = []; // Reset on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'View Appointments',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            appointments.isEmpty
                ? const Center(
                    child: Text(
                      "No Appointments Available",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
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
          ],
        ),
      ),
    );
  }
}
