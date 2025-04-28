import 'dart:html' as html; // Add this import for web-specific functionality
import 'package:admin_wellnest/main.dart';
import 'package:admin_wellnest/screens/assign_caretaker.dart';
import 'package:admin_wellnest/screens/family_member.dart';
import 'package:admin_wellnest/screens/monthly_payment.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Still needed for PdfGoogleFonts

class ManageResident extends StatefulWidget {
  const ManageResident({super.key});

  @override
  State<ManageResident> createState() => _ManageResidentState();
}

class _ManageResidentState extends State<ManageResident> {
  List<Map<String, dynamic>> _filetypeList = [];

  @override
  void initState() {
    super.initState();
    fetchFiletype();
  }

  Future<void> fetchFiletype() async {
    try {
      final response = await supabase
          .from('tbl_resident')
          .select('*, tbl_relation(*), tbl_room(*)')
          .inFilter('resident_status', [1, 3, 4]);
      print('Fetched data: $response');
      setState(() {
        _filetypeList = response;
      });
    } catch (e) {
      print("ERROR FETCHING FILE TYPE DATA: $e");
    }
  }

  Future<void> _generateAndDownloadPdf() async {
    final pdf = pw.Document();

    if (_filetypeList.isEmpty) {
      print('No data available to generate PDF');
      return;
    }

    // Load the Roboto font
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Resident List',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: [
                'Sl.No',
                'Resident Name',
                'Room Type',
                'Relation',
                'Contact',
                'Email'
              ],
              data: _filetypeList.asMap().entries.map((entry) {
                print('Processing entry: ${entry.value}');
                return [
                  (entry.key + 1).toString(),
                  entry.value['resident_name']?.toString() ?? 'N/A',
                  entry.value['tbl_room']?['room_name']?.toString() ?? 'N/A',
                  entry.value['tbl_relation']?['relation_name']?.toString() ??
                      'N/A',
                  entry.value['resident_contact']?.toString() ?? 'N/A',
                  entry.value['resident_email']?.toString() ?? 'N/A',
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle:
                  pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(font: font),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: pw.EdgeInsets.all(5),
            ),
          ];
        },
      ),
    );

    // Generate PDF bytes
    final pdfBytes = await pdf.save();

    // Create a Blob and trigger download for web
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'resident_list_${DateTime.now().toString()}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url); // Clean up
  }

  Future<void> updateResidentStatus(String residentId, int status) async {
    try {
      await supabase.from('tbl_resident').update(
          {'resident_status': status}).match({'resident_id': residentId});
      fetchFiletype();
    } catch (e) {
      print("ERROR UPDATING RESIDENT STATUS: $e");
    }
  }

  void paymentVerify(String residentId) {
    updateResidentStatus(residentId, 3);
  }

  Future<void> deleteResident(String id) async {
    try {
      await supabase.from('tbl_assign').delete().eq('resident_id', id);
      await supabase
          .from('tbl_resident')
          .update({'resident_status': 5}).eq('resident_id', id);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Success"),
            content: Text("Resident Deleted Successfully"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("OK"))
            ],
          );
        },
      );
    } catch (e) {
      print("Error Deleting $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(255, 227, 242, 253),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topRight,
            padding: EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Download PDF'),
              onPressed: _generateAndDownloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 24, 56, 111),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: const Color(0xFFEEEEEE),
              dataTableTheme: DataTableThemeData(
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 24, 56, 111),
                  fontSize: 16,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                ),
              ),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF5F7FA),
              ),
              dataRowColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFE8F0FE);
                  }
                  return Colors.transparent;
                },
              ),
              horizontalMargin: 20,
              columnSpacing: 25,
              dividerThickness: 1,
              border: TableBorder(
                horizontalInside: BorderSide(
                  width: 1,
                  color: Colors.grey.withAlpha(51),
                ),
                top: BorderSide(
                  width: 1,
                  color: Colors.grey.withAlpha(51),
                ),
                bottom: BorderSide(
                  width: 1,
                  color: Colors.grey.withAlpha(51),
                ),
              ),
              showBottomBorder: true,
              columns: const [
                DataColumn(label: Text("Sl.No")),
                DataColumn(label: Text("Resident Name")),
                DataColumn(label: Text("Room Type")),
                DataColumn(label: Text("Relation")),
                DataColumn(label: Text("Contact")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Action")),
              ],
              rows: _filetypeList.asMap().entries.map((entry) {
                print(entry.value);
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      return entry.key % 2 == 0
                          ? const Color(0xFFFAFAFA)
                          : Colors.white;
                    },
                  ),
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 24, 56, 111),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          (entry.key + 1).toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      entry.value['resident_name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.value['tbl_room']['room_name'].toString(),
                          style: const TextStyle(
                              color: Color.fromARGB(255, 24, 56, 111)),
                        ),
                      ),
                    ),
                    DataCell(Text(entry.value['tbl_relation']['relation_name']
                        .toString())),
                    DataCell(Text(entry.value['resident_contact'].toString())),
                    DataCell(Text(
                      entry.value['resident_email'].toString(),
                      style: const TextStyle(color: Colors.blue),
                    )),
                    DataCell(
                      entry.value['resident_status'] == 1
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFFFD54F), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Payment Pending",
                                    style: TextStyle(
                                      color: Color(0xFFFF8F00),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.verified,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    onPressed: () {
                                      paymentVerify(entry.value['resident_id']
                                          .toString());
                                    },
                                  ),
                                ],
                              ),
                            )
                          : entry.value['resident_status'] == 4
                              ? Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.person_add,
                                        size: 18,
                                      ),
                                      label: const Text("Reassign"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AssignCaretaker(
                                              id: entry.value['resident_id'],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 26, 196, 196),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.payment,
                                        size: 18,
                                      ),
                                      label: const Text("Payment"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MonthlyPayment(
                                                    id: entry
                                                        .value['resident_id']),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 56, 111),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.person,
                                        size: 18,
                                      ),
                                      label: const Text("Family Member"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FamilyMember(
                                                id: entry
                                                    .value['familymember_id']
                                                    .toString()),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 56, 111),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                  title:
                                                      Text("Delete Resident"),
                                                  content: Text(
                                                      "Are you sure you want to delete this resident?"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text("Cancel")),
                                                    TextButton(
                                                        onPressed: () {
                                                          deleteResident(entry
                                                              .value[
                                                                  'resident_id']
                                                              .toString());
                                                        },
                                                        child: Text(
                                                            "Confirm Delete"))
                                                  ]);
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.delete_forever,
                                            color: Colors.red)),
                                  ],
                                )
                              : Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.person_add,
                                        size: 18,
                                      ),
                                      label: const Text("Assign"),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AssignCaretaker(
                                                    id: entry
                                                        .value['resident_id']),
                                          ),
                                        );
                                        if(result == true){
                                          fetchFiletype();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 56, 111),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.payment,
                                        size: 18,
                                      ),
                                      label: const Text("Payment"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MonthlyPayment(
                                                    id: entry
                                                        .value['resident_id']),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 56, 111),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.person_2_rounded,
                                        size: 18,
                                      ),
                                      label: const Text("Family Member"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FamilyMember(
                                                id: entry
                                                    .value['familymember_id']
                                                    .toString()),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 56, 111),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
