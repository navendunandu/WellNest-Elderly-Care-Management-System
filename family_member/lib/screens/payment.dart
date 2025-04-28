import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Add this for date formatting

class PaymentPage extends StatefulWidget {
  final String residentId;
  const PaymentPage({super.key, required this.residentId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  late SupabaseClient supabase;
  List<Map<String, dynamic>> paymentHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    supabase = Supabase.instance.client;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    try {
      setState(() => isLoading = true);
      final response = await supabase
          .from('tbl_payment')
          .select()
          .eq('resident_id', widget.residentId)
          .order('payment_date', ascending: false);

      setState(() {
        paymentHistory = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Error loading payment history: $e");
    }
  }

  bool _isPaidForCurrentMonth() {
    final now = DateTime.now();
    return paymentHistory.any((payment) {
      final paymentDate = DateTime.parse(payment['payment_date']);
      return paymentDate.year == now.year && paymentDate.month == now.month;
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final paymentData = {
        'payment_rzid': response.paymentId,
        'payment_date': DateTime.now().toIso8601String(),
        'payment_amount': 27500.00,
        'resident_id': widget.residentId,
        'familymember_id': supabase.auth.currentUser?.id,
      };

      await supabase.from('tbl_payment').insert(paymentData);

      Fluttertoast.showToast(
        msg: "Payment Successful: ${response.paymentId}",
        toastLength: Toast.LENGTH_SHORT,
      );

      await _fetchPaymentHistory(); // Refresh history after payment
    } catch (e) {
      print('The recorded error is: $e');
      Fluttertoast.showToast(
        msg: "Payment recorded but failed to save: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Payment History Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : paymentHistory.isEmpty
                    ? const Center(child: Text("No payment history available"))
                    : ListView.builder(
                        itemCount: paymentHistory.length,
                        itemBuilder: (context, index) {
                          final payment = paymentHistory[index];
                          final date = DateTime.parse(payment['payment_date']);
                          final formattedDate =
                              DateFormat('MMM dd, yyyy').format(date);
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(
                                  'Amount: ₹${(payment['payment_amount'] as num).toStringAsFixed(2)}'),
                              subtitle: Text(
                                  'Date: $formattedDate\nID: ${payment['payment_rzid']}'),
                              trailing: date.month == DateTime.now().month &&
                                      date.year == DateTime.now().year
                                  ? const Chip(
                                      label: Text('Current Month'),
                                      backgroundColor: Colors.green,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
          // Pay Now Button Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isPaidForCurrentMonth())
                  const Text(
                    "Paid for this month",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isPaidForCurrentMonth() ? null : openCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Pay Now",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openCheckout() async {
    final user = await supabase
        .from('tbl_familymember')
        .select()
        .eq('familymember_id', supabase.auth.currentUser!.id)
        .single();

    var options = {
      'key': 'rzp_test_565dkZaITtTfYu',
      'amount': 2750000, // in paise
      'name': 'WellNest',
      'description': 'Payment',
      'prefill': {
        'contact': user['familymember_contact'],
        'email': user['familymember_email'],
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }
}
