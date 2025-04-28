// import 'package:admin_wellnest/components/sidebar_button.dart';
import 'package:admin_wellnest/screens/dashboard.dart';
import 'package:admin_wellnest/screens/leave_appl.dart';
// import 'package:admin_wellnest/screens/family_member.dart';
import 'package:admin_wellnest/screens/login_screen.dart';
import 'package:admin_wellnest/screens/manage_caretaker.dart';
import 'package:admin_wellnest/screens/manage_complaints.dart';
import 'package:admin_wellnest/screens/manage_relation.dart';
import 'package:admin_wellnest/screens/manage_resident.dart';
import 'package:admin_wellnest/screens/manage_room.dart';
import 'package:admin_wellnest/screens/new_admission.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> pages = [
    {'icon': Icons.home, 'label': 'Home', 'page': Dashboard()},
    {
      'icon': Icons.room_preferences,
      'label': 'Manage Room',
      'page': ManageRoom()
    },
    {
      'icon': Icons.local_hospital_sharp,
      'label': 'Manage Caretaker',
      'page': ManageCaretaker()
    },
    {
      'icon': Icons.fiber_manual_record,
      'label': 'Relationship',
      'page': ManageRelation()
    },
    {
      'icon': Icons.fiber_new_outlined,
      'label': 'New admission',
      'page': NewAdmission()
    },
    
    {
      'icon': Icons.person_outlined,
      'label': 'Resident',
      'page': ManageResident()
    },
    {
      'icon': Icons.person_outlined,
      'label': 'Manage Leaves',
      'page': LeaveApplication()
    },

    {
      'icon': Icons.report_problem,
      'label': 'Complaints',
      'page': ManageComplaints()
    },
  ];
  Widget currentPage = Dashboard();
  int selectedIndex = 0;
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 252, 197),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(2, 2))
                ],
              ),
              child: Column(children: [
                const SizedBox(height: 20),
                const Text(
                  "Administrator",
                  style: TextStyle(
                    color: Color.fromARGB(255, 24, 56, 111),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 15),
                Image.asset(
                  'asset/logo.jpg',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return MouseRegion(
                        onEnter: (_) => setState(() => selectedIndex = index),
                        onExit: (_) => setState(() => selectedIndex = -1),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentPage = page['page'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: selectedIndex == index
                                  ? Colors.blue.shade100
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(page['icon'],
                                  color: selectedIndex == index
                                      ? Colors.blue.shade900
                                      : Colors.black54),
                              title: Text(
                                page['label'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selectedIndex == index
                                      ? Colors.blue.shade900
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1, color: Colors.black26),
                GestureDetector(
                    onTap: _logout,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? Colors.blue.shade100
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.logout,
                                color: isHovered
                                    ? Colors.blue.shade900
                                    : Colors.black54),
                            const SizedBox(width: 10),
                            Text(
                              "Logout",
                              style: TextStyle(
                                color: isHovered
                                    ? Colors.blue.shade900
                                    : const Color.fromARGB(255, 24, 56, 111),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ]),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(-2, 2))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    currentPage,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
