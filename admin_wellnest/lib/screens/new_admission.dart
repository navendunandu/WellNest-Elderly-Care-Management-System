import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewAdmission extends StatefulWidget {
  const NewAdmission({super.key});

  @override
  State<NewAdmission> createState() => _NewAdmissionState();
}

class _NewAdmissionState extends State<NewAdmission> {
  List<Map<String, dynamic>> _filetypeList = [];

  @override
  void initState() {
    super.initState();
    fetchFiletype();
  }

  Future<void> fetchFiletype() async {
    try {
      final response =
          await supabase.from('tbl_resident').select().eq('resident_status', 0);
      setState(() {
        _filetypeList = response;
      });
    } catch (e) {
      print("ERROR FETCHING FILE TYPE DATA: $e");
    }
  }

  Future<void> viewProof(String filePath) async {
    try {
      
      final publicUrl = await supabase.storage.from('resident_files').getPublicUrl(filePath);
      if (await canLaunchUrl(Uri.parse(publicUrl))) {
        await launchUrl(Uri.parse(filePath));
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      print('ERROR OPENING FILE: $e');
    }
  }

  Future<void> verifyAdm(String res, int status) async {
    try {
      await supabase
          .from('tbl_resident')
          .update({'resident_status': status}).eq('resident_id', res);
    String msg = status == 1 ? "Accepted" : "Rejected";
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: Text("Admission $msg successfully"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                fetchFiletype();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("ERROR UPDATING ADMISSION STATUS: $e");
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Sl.No")),
          DataColumn(label: Text("Resident Name")),
          DataColumn(label: Text("Room ID")),
          DataColumn(label: Text("Relation ID")),
          DataColumn(label: Text("Contact")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Proof")),
          DataColumn(label: Text("Action")),
        ],
        rows: _filetypeList.asMap().entries.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text((entry.key + 1).toString())),
              DataCell(Text(entry.value['resident_name'].toString())),
              DataCell(Text(entry.value['room_id'].toString())),
              DataCell(Text(entry.value['relation_id'].toString())),
              DataCell(Text(entry.value['resident_contact'].toString())),
              DataCell(Text(entry.value['resident_email'].toString())),
              DataCell(
                TextButton(
                  onPressed: () => viewProof(entry.value['resident_proof'].toString()),
                  child: const Text('View Proof', style: TextStyle(color: Colors.blue)),
                ),
              ),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => {
                      verifyAdm(entry.value['resident_id'].toString(), 1),
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => {
                      verifyAdm(entry.value['resident_id'].toString(), 2),
                    },
                  ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
