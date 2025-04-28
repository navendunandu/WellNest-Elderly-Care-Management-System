import 'package:flutter/material.dart';
import 'package:caretaker_wellnest/main.dart'; // Ensure supabase is initialized here

class ApplyLeave extends StatefulWidget {
  const ApplyLeave({super.key});

  @override
  State<ApplyLeave> createState() => _ApplyLeaveState();
}

class _ApplyLeaveState extends State<ApplyLeave> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? ((_startDate != null && _startDate!.isAfter(now))
              ? _startDate!
              : now)
          : ((_endDate != null && _endDate!.isAfter(now))
              ? _endDate!
              : (_startDate != null && _startDate!.isAfter(now)
                  ? _startDate!
                  : now)),
      firstDate: now, // Restricts to current day and future
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date exists and is before the new start date, reset it
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          // Ensure end date isn't before start date
          if (_startDate != null && picked.isBefore(_startDate!)) {
            // You could either show an error message or automatically set end date equal to start date
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('End date cannot be before start date')));
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select both start and end dates')),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await supabase.from('tbl_leave').insert({
          'leave_reason': _reasonController.text,
          'leave_fromdate': _startDate!.toIso8601String(),
          'leave_todate': _endDate!.toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Leave application submitted successfully')),
        );

        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting leave application: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application',style: TextStyle(color:Colors.white),),
        backgroundColor: Color.fromARGB(255, 0, 36, 90), // AppBar color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(230, 255, 252, 197),
              Color.fromARGB(230, 255, 252, 197),
              Color.fromARGB(230, 255, 252, 197)
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  color: Color.fromARGB(230, 172, 210, 253),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            // labelText: 'Reason for Leave',
                            hintText: 'Enter your reason for leave',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a reason for leave';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    // labelText: 'Start Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? '${_startDate!.toLocal()}'
                                            .split(' ')[0]
                                        : 'Select Start Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _startDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    // labelText: 'End Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  child: Text(
                                    _endDate != null
                                        ? '${_endDate!.toLocal()}'.split(' ')[0]
                                        : 'Select End Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _endDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(230, 172, 210, 253), // Button color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold
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
