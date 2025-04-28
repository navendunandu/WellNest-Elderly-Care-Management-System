import 'package:family_member/main.dart';
import 'package:flutter/material.dart';

class Complaints extends StatefulWidget {
  const Complaints({super.key});

  @override
  _ComplaintsState createState() => _ComplaintsState();
}

class _ComplaintsState extends State<Complaints> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedComplaintType = "Room Cleaning";
  String _selectedUrgency = "Low Priority";

  final List<String> complaintTypes = [
    "Room Cleaning",
    "Maintenance",
    "Staff Behavior",
    "Food Quality",
    "Medical Concerns",
    "Laundry Services",
    "Recreational Activities",
    "Others"
  ];

  void _submitComplaint() async {
  String complaint = _descriptionController.text.trim();

  if (complaint.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a complaint description.")),
    );
    return;
  }

  try {
    // Insert data into Supabase table
    await supabase.from('tbl_complaint').insert({
      'complaint_title': _selectedComplaintType,
      'complaint_content': complaint,
      'complaint_priority': _selectedUrgency,
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Complaint Submitted:\nType: $_selectedComplaintType\nUrgency: $_selectedUrgency\nDescription: $complaint",
        ),
      ),
    );

    // Clear fields after submission
    setState(() {
      _descriptionController.clear();
      _selectedComplaintType = "Room Cleaning";
      _selectedUrgency = "Low Priority";
    });
  } catch (e) {
    // Handle errors
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error submitting complaint: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text("Complaints",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 23)),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 8,
            shadowColor: Colors.black45,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Complaint Type Dropdown
                  const Text("Complaint Type",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(2, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedComplaintType,
                        items: complaintTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedComplaintType = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Complaint Description
                  const Text("Complaint Description",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(2, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter complaint details...",
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Urgency Level
                  const Text("Urgency Level",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(2, 2)),
                      ],
                    ),
                    child: Column(
                      children:
                          ["Low Priority", "Medium Priority", "High Priority"]
                              .map((level) => RadioListTile(
                                    title: Text(level),
                                    value: level,
                                    groupValue: _selectedUrgency,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUrgency = value!;
                                      });
                                    },
                                    activeColor:
                                        const Color.fromARGB(255, 0, 36, 94),
                                  ))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        shadowColor: Colors.black38,
                      ),
                      child: const Text("Submit",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
