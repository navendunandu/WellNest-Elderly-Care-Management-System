import 'package:admin_wellnest/main.dart'; // Assuming this contains your Supabase client
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class MonthlyPayment extends StatefulWidget {
  const MonthlyPayment({super.key, required id});

  @override
  State<MonthlyPayment> createState() => _MonthlyPaymentState();
}

class _MonthlyPaymentState extends State<MonthlyPayment> {
  bool isLoading = true;
  List<Map<String, dynamic>> payments = [];
  final int currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch all payments for the current year
      final response = await supabase
          .from('tbl_payment')
          .select('payment_rzid, payment_date, payment_amount, resident_id, tbl_resident!inner(resident_name)')
          .gte('payment_date', '$currentYear-01-01')
          .lte('payment_date', '$currentYear-12-31');

      print("Fetched payment data: $response");
      setState(() {
        payments = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching payments: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to check if payment exists for a given month
  bool hasPaymentForMonth(int month) {
    return payments.any((payment) {
      final paymentDate = DateTime.parse(payment['payment_date']);
      return paymentDate.year == currentYear && paymentDate.month == month;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Payments',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 56, 111),
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
            : payments.isEmpty
                ? const Center(child: Text('No payments found for this year'))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payments for $currentYear',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 24, 56, 111),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: List.generate(12, (index) {
                                  final month = index + 1;
                                  final monthName = DateFormat('MMMM')
                                      .format(DateTime(currentYear, month));
                                  final hasPayment = hasPaymentForMonth(month);
                                  
                                  return ListTile(
                                    title: Text(monthName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          hasPayment ? 'Complete' : 'Incomplete',
                                          style: TextStyle(
                                            color: hasPayment
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          hasPayment
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: hasPayment
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ],
                                    ),
                                    subtitle: hasPayment
                                        ? Text(
                                            'Last payment: ${payments.where((p) => DateTime.parse(p['payment_date']).month == month).last['payment_amount']} INR')
                                        : const Text('No payment recorded'),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}