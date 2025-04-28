import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewBookings extends StatefulWidget {
  const ViewBookings({super.key});

  @override
  State<ViewBookings> createState() => _ViewBookingsState();
}

class _ViewBookingsState extends State<ViewBookings> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('tbl_familybooking')
        .select('*')
        .eq('familymember_id', userId);

    if (response.isEmpty) {
      return [];
    }
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        title: const Text('My Bookings'),
      ),
      body: FutureBuilder(
        future: fetchBookings(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Error fetching bookings.'));
          }

          final currentDate = DateTime.now();
          final pastBookings = snapshot.data!.where((booking) => DateTime.parse(booking['familybooking_todate']).isBefore(currentDate)).toList();
          final upcomingBookings = snapshot.data!.where((booking) => DateTime.parse(booking['familybooking_fromdate']).isAfter(currentDate)).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upcomingBookings.isNotEmpty)
                  _buildBookingSection('Upcoming Bookings', upcomingBookings),
                if (pastBookings.isNotEmpty)
                  _buildBookingSection('Past Bookings', pastBookings),
                if (upcomingBookings.isEmpty && pastBookings.isEmpty)
                  const Center(child: Text('No bookings found.')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingSection(String title, List<Map<String, dynamic>> bookings) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...bookings.map((booking) => Card(
                child: ListTile(
                  title: Text('Booking ID: ${booking['familybooking_id']}'),
                  subtitle: Text(
                      'From: ${booking['familybooking_fromdate']} To: ${booking['familybooking_todate']}\nStatus: ${booking['familybooking_status'] == 1 ? 'Confirmed' : 'Pending'}'),
                ),
              ))
        ],
      ),
    );
  }
}
