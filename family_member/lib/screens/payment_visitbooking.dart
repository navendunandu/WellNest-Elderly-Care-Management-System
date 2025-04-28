import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentVisitbooking extends StatefulWidget {
  final int id;
  final int amt;
  const PaymentVisitbooking({super.key, required this.id, required this.amt});

  @override
  State<PaymentVisitbooking> createState() => _PaymentVisitbookingState();
}

class _PaymentVisitbookingState extends State<PaymentVisitbooking> {
  late Razorpay _razorpay;
  late SupabaseClient supabase; // Add Supabase clien
  void initState() {
    super.initState();
    
    // Initialize Supabase
    supabase = Supabase.instance.client;
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
   
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Insert payment details into Supabase
      final paymentData = {
        'payment_rzid': response.paymentId,
        'payment_date': DateTime.now().toIso8601String(),
        'payment_amount': widget.amt, 
        'familymember_id': supabase.auth.currentUser?.id,
      };

      await supabase.from('tbl_payment').insert(paymentData);
      await supabase.from('tbl_familybooking').update({'familybooking_status': 1}).eq('familybooking_id', widget.id);
      Fluttertoast.showToast(
        msg: "Payment Successful: ${response.paymentId}",
        toastLength: Toast.LENGTH_SHORT,
      );
      

    } catch (e) {
      print('The recorded error is: $e');
      Fluttertoast.showToast(
        msg: "Payment recorded but failed to save: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('The recorded error is: $response');
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('The recorded error is: $response');
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
      body: Center(
        child: ElevatedButton(
          onPressed: openCheckout,
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
      ),
    );
  }

  Future<void> openCheckout() async {
    final user = await supabase.from('tbl_familymember').select().eq('familymember_id', supabase.auth.currentUser!.id).single();

    var options = {
      'key': 'rzp_test_565dkZaITtTfYu',
      'amount': widget.amt*100,
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
