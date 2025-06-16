import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/services/mpesa_service.dart';

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
  String? _checkoutRequestId;
  bool _isPolling = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Get MpesaService from provider
      // final mpesaService = context.read<MpesaService>();
      // final response = await mpesaService.initiateSTKPush(
      //   phoneNumber: _phoneController.text,
      //   amount: widget.amount,
      //   accountReference: widget.reference,
      //   transactionDesc: widget.description,
      // );

      // setState(() {
      //   _checkoutRequestId = response['CheckoutRequestID'];
      //   _isPolling = true;
      // });

      // _startPolling();
    } catch (e) {
      // TODO: Show error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startPolling() async {
    while (_isPolling) {
      await Future.delayed(const Duration(seconds: 5));

      try {
        // TODO: Get MpesaService from provider
        // final mpesaService = context.read<MpesaService>();
        // final response = await mpesaService.checkTransactionStatus(_checkoutRequestId!);

        // if (response['status'] == 'success') {
        //   setState(() => _isPolling = false);
        //   if (mounted) {
        //     Navigator.pop(context, true);
        //   }
        // } else if (response['status'] == 'failed') {
        //   setState(() => _isPolling = false);
        //   // TODO: Show error
        // }
      } catch (e) {
        // TODO: Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Amount: KES ${widget.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: 'e.g. 254712345678',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^254[0-9]{9}$').hasMatch(value)) {
                    return 'Please enter a valid phone number (e.g. 254712345678)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || _isPolling ? null : _initiatePayment,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isPolling ? 'Processing...' : 'Pay Now'),
              ),
              if (_isPolling) ...[
                const SizedBox(height: 16),
                const Text(
                  'Please check your phone for the M-Pesa prompt',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 