import 'package:caretaker_wellnest/main.dart';
import 'package:caretaker_wellnest/screens/family_member.dart';
import 'package:flutter/material.dart';
import 'view_routine.dart';
import 'view_medication.dart';
import 'view_health.dart';
import 'view_medappointments.dart';

class ResidentProfile extends StatefulWidget {
  String resident;
  ResidentProfile({super.key, required this.resident});

  @override
  State<ResidentProfile> createState() => _ResidentProfileState();
}

class _ResidentProfileState extends State<ResidentProfile> {
  String name = "";
  String dob = "";
  String photo = "";
  String resident_age = "";
  String resident_id = "";

  @override
  void initState() {
    super.initState();
    fetchresident();
  }

  Future<void> fetchresident() async {
    try {
      final response = await supabase
          .from('tbl_resident')
          .select()
          .eq('resident_id', widget.resident)
          .single();

      setState(() {
        name = response['resident_name'];
        photo = response['resident_photo'];
        dob = response['resident_dob'];
        resident_age = _calculateAge(DateTime.parse(dob)).toString();
        resident_id = response['resident_id'];
      });
    } catch (e) {
      print('Error is: $e');
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'Resident Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Age: $resident_age',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
             _buildMenuButton(
              context,
              icon: Icons.schedule,
              label: 'View Family',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyMember(residentId: resident_id),
                  ),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.schedule,
              label: 'Manage Routine',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewRoutine(residentId: resident_id),
                  ),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.medical_services,
              label: 'Manage Medication',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewMedication(residentId: resident_id),
                  ),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.health_and_safety,
              label: 'Manage Health Record',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewHealth(resident_id: resident_id),
                  ),
                );
              },
            ),
            _buildMenuButton(
              context,
              icon: Icons.calendar_today,
              label: 'Manage Appointments',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewMedappointments(resident_id: resident_id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 36, 94),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
