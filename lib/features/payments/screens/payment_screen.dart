import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:nisacleanv1/core/utils/error_handler.dart';
import 'package:nisacleanv1/features/payments/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String reference;
  final String description;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.reference,
    required this.description,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Timer? _statusCheckTimer;
  final _paymentService = PaymentService(Dio());

  @override
  void dispose() {
    _phoneController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _paymentService.initiateMpesaPayment(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        reference: widget.reference,
        description: widget.description,
      );

      if (response.success) {
        _startStatusCheck();
      } else {
        setState(() {
          _error = response.error ?? 'Failed to initiate payment';
          _isLoading = false;
        });
      }
    } on AppError catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await _paymentService.checkPaymentStatus(widget.reference);
        
        if (response.success && response.data?['status'] == 'success') {
          timer.cancel();
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else if (response.success && response.data?['status'] == 'failed') {
          timer.cancel();
          setState(() {
            _error = 'Payment failed. Please try again.';
            _isLoading = false;
          });
        }
      } catch (e) {
        // Don't show error for status check failures
        // Just continue polling
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: 'e.g. 254712345678',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your M-Pesa phone number';
                  }
                  if (!RegExp(r'^254[0-9]{9}$').hasMatch(value)) {
                    return 'Please enter a valid M-Pesa phone number starting with 254';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Waiting for M-Pesa prompt...',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your phone and enter your M-Pesa PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _initiatePayment,
                  child: const Text('Pay Now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 