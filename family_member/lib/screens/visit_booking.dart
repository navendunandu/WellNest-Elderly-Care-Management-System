import 'package:family_member/main.dart';
import 'package:family_member/screens/payment_visitbooking.dart';
import 'package:family_member/screens/view_bookings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitBooking extends StatefulWidget {
  const VisitBooking({super.key});

  @override
  State<VisitBooking> createState() => _VisitBookingState();
}

class _VisitBookingState extends State<VisitBooking> {
  DateTime? fromDate;
  DateTime? toDate;
  int? personCount = 1;
  int numberOfDays = 0;
  int total = 0;

  // Add TextEditingControllers
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = isFromDate
        ? (fromDate ?? DateTime.now())
        : (toDate ?? fromDate ?? DateTime.now());

    DateTime firstDate =
        isFromDate ? DateTime.now() : (fromDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          _fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = null;
            _toDateController.clear();
          }
        } else {
          if (fromDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a From Date first.")),
            );
            return;
          }
          toDate = picked;
          _toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
        _calculateDays(personCount ?? 1); // Update total when dates change
      });
    }
  }

  Map<String, dynamic> roomList = {};

  Future<void> fetchRoom() async {
    try {
      final response = await supabase
          .from('tbl_room')
          .select()
          .eq('room_name', "Family Room")
          .maybeSingle()
          .limit(1);
      setState(() {
        roomList = response ?? {};
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoom();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _calculateDays(int count) {
    if (fromDate != null && toDate != null) {
      numberOfDays = toDate!.difference(fromDate!).inDays + 1;
    } else {
      numberOfDays = 0;
    }
    // Use null-safe default value for room_price
    int price = roomList['room_price'] as int? ?? 0;
    int amount = numberOfDays * price * count;
    print("Amount: $amount");
    setState(() {
      total = amount;
    });
  }

  void _submitBooking() async {
    if (fromDate == null || toDate == null || personCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details")),
      );
      return;
    }

    try {
      if (roomList['room_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid room selection.")),
        );
        return;
      }

      final bookedCountResponse = await supabase
          .from('tbl_familybooking')
          .select('familybooking_id')
          .gte('familybooking_fromdate', fromDate!.toIso8601String())
          .lte('familybooking_todate', toDate!.toIso8601String())
          .eq('room_id', roomList['room_id']);

      if (bookedCountResponse == null || bookedCountResponse is! List) {
        throw Exception("Invalid response from Supabase");
      }

      int bookedCount = bookedCountResponse.length;
      int availableRooms = (roomList['room_count'] as int? ?? 0) - bookedCount;

      if (availableRooms <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No rooms available for the selected dates.")),
        );
        return;
      }

      final result = await supabase
          .from('tbl_familybooking')
          .insert({
            'familybooking_fromdate': fromDate!.toIso8601String(),
            'familybooking_todate': toDate!.toIso8601String(),
            'familybooking_count': personCount,
            'room_id': roomList['room_id'],
            'familymember_id': supabase.auth.currentUser?.id,
          })
          .select()
          .single();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Booking confirmed for ${toDate!.difference(fromDate!).inDays} days with $personCount person(s)"),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentVisitbooking(
            amt: total,
            id: result['familybooking_id'],
          ),
        ),
      );
      print('total: $total');
    } catch (e) {
      print("Error checking availability: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error checking room availability.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'Visit Booking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Book a Visit",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 36, 94)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildDateField("From Date", _fromDateController,
                    () => _selectDate(context, true)),
                _buildDateField("To Date", _toDateController,
                    () => _selectDate(context, false)),
                _buildDropdownField("Number of Persons", personCount!),
                const SizedBox(height: 20),
                Text("Number of Days: $numberOfDays",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("Total Amount: Rs.$total",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(
                    "Disclaimer: The room price is Rs.${roomList['room_price'] ?? 'N/A'} per head per day. There will not be any refunds.",
                    style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Confirm Booking',
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
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          hintText: "Select Date",
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildDropdownField(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        value: value,
        items: List.generate(6, (index) => index + 1).map((num) {
          return DropdownMenuItem<int>(
            value: num,
            child: Text("$num"),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            personCount = value;
            _calculateDays(value!);
          });
        },
      ),
    );
  }
}
