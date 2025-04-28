import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';

class FamilyMember extends StatefulWidget {
  final String id;
  const FamilyMember({super.key, required this.id});

  @override
  State<FamilyMember> createState() => _FamilyMemberState();
}

class _FamilyMemberState extends State<FamilyMember> {
  bool isLoading = true;
  List<Map<String, dynamic>> familyMembers = [];
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchBookings();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase
          .from("tbl_familymember")
          .select()
          .eq("familymember_id", widget.id);

      print("Fetched family member data: $response");
      setState(() {
        familyMembers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching family member data: $e");
    }
  }

  Future<void> fetchBookings() async {
    try {
      final response = await supabase
          .from("tbl_familybooking")
          .select("*, tbl_room(*)")
          .eq("familymember_id", widget.id);

      print("Fetched booking data: $response");
      setState(() {
        bookings = List<Map<String, dynamic>>.from(response);
        isLoading = false; // Set loading false only after both fetches complete
      });
    } catch (e) {
      print("Error fetching booking data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> viewProof(String filePath) async {
    try {
      await launchUrl(Uri.parse(filePath));
    } catch (e) {
      print('ERROR OPENING FILE: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Family Members',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 56, 111),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 227, 242, 253),
              Color.fromARGB(255, 227, 242, 253),
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : familyMembers.isEmpty
                ? const Center(child: Text('No family members found'))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Family Member Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 24, 56, 111),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Card(
                                  elevation: 4,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      columns: const [
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Address')),
                                        DataColumn(label: Text('Contact')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text("Proof")),
                                        DataColumn(label: Text('Photo')),
                                      ],
                                      rows: familyMembers
                                          .map((member) => DataRow(
                                                cells: [
                                                  DataCell(Text(member[
                                                          'familymember_name'] ??
                                                      '')),
                                                  DataCell(Text(member[
                                                          'familymember_address'] ??
                                                      '')),
                                                  DataCell(Text(
                                                      member['familymember_contact']
                                                              .toString() ??
                                                          '')),
                                                  DataCell(Text(member[
                                                          'familymember_email'] ??
                                                      '')),
                                                  DataCell(
                                                    TextButton(
                                                      onPressed: () => viewProof(
                                                          member['familymember_proof']
                                                              .toString()),
                                                      child: const Text(
                                                          'View Proof',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.blue)),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    member['familymember_photo'] !=
                                                            null
                                                        ? Image.network(
                                                            member[
                                                                'familymember_photo'],
                                                            width: 50,
                                                            height: 50,
                                                            errorBuilder: (context,
                                                                    error,
                                                                    stackTrace) =>
                                                                const Icon(Icons
                                                                    .broken_image),
                                                          )
                                                        : const Text(
                                                            'No Photo'),
                                                  ),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const Text(
                                  'Booking Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 24, 56, 111),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                bookings.isEmpty
                                    ? const Center(
                                        child: Text('No bookings found'))
                                    : Card(
                                        elevation: 4,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columnSpacing: 16,
                                            columns: const [
                                              DataColumn(
                                                  label: Text('Booking ID')),
                                              DataColumn(
                                                  label: Text('Booking Date')),
                                              DataColumn(
                                                  label: Text('From Date')),
                                              DataColumn(
                                                  label: Text('To Date')),
                                              DataColumn(
                                                  label: Text('Room Type')),
                                              DataColumn(label: Text('Count')),
                                              DataColumn(label: Text('Status')),
                                            ],
                                            rows: bookings
                                                .map((booking) => DataRow(
                                                      cells: [
                                                        DataCell(Text(booking[
                                                                'familybooking_id']
                                                            .toString())),
                                                        DataCell(Text(DateFormat(
                                                                'yyyy-MM-dd HH:mm')
                                                            .format(DateTime
                                                                .parse(booking[
                                                                    'familybooking_date'])))),
                                                        DataCell(Text(DateFormat(
                                                                'yyyy-MM-dd')
                                                            .format(DateTime
                                                                .parse(booking[
                                                                    'familybooking_fromdate'])))),
                                                        DataCell(Text(DateFormat(
                                                                'yyyy-MM-dd')
                                                            .format(DateTime
                                                                .parse(booking[
                                                                    'familybooking_todate'])))),
                                                        DataCell(Text(booking[
                                                                    'tbl_room']
                                                                ['room_name']
                                                            .toString())),
                                                        DataCell(Text(booking[
                                                                'familybooking_count']
                                                            .toString())),
                                                        DataCell(Text(
                                                          booking['familybooking_status'] ==
                                                                  1
                                                              ? 'Confirmed'
                                                              : 'Pending',
                                                          style: TextStyle(
                                                            color: booking[
                                                                        'familybooking_status'] ==
                                                                    1
                                                                ? Colors.green
                                                                : Colors.orange,
                                                          ),
                                                        )),
                                                      ],
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
