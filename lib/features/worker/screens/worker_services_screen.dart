import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerServicesScreen extends StatefulWidget {
  const WorkerServicesScreen({super.key});

  @override
  State<WorkerServicesScreen> createState() => _WorkerServicesScreenState();
}

class _WorkerServicesScreenState extends State<WorkerServicesScreen> {
  // TODO: Replace with actual data from API
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'name': 'Laundry Services',
      'description': 'Professional laundry and ironing services',
      'category': 'Laundry',
      'items': [
        {'name': 'Shirts Ironing', 'price': 50.0},
        {'name': 'Trousers Ironing', 'price': 50.0},
        {'name': 'Suits Ironing', 'price': 150.0},
        {'name': 'Dresses Ironing', 'price': 100.0},
        {'name': 'Regular Clothes (per kg)', 'price': 100.0},
        {'name': 'Delicate Items (per kg)', 'price': 150.0},
        {'name': 'Bed Sheets', 'price': 200.0},
        {'name': 'Duvet Covers', 'price': 250.0},
        {'name': 'Suits Dry Cleaning', 'price': 300.0},
        {'name': 'Coats Dry Cleaning', 'price': 250.0},
        {'name': 'Formal Dresses Dry Cleaning', 'price': 350.0},
      ],
    },
    {
      'id': '2',
      'name': 'House Cleaning',
      'description': 'Complete house cleaning services',
      'category': 'Cleaning',
      'items': [
        {'name': '1 Bedroom Regular Cleaning', 'price': 1500.0},
        {'name': '2 Bedrooms Regular Cleaning', 'price': 2000.0},
        {'name': '3 Bedrooms Regular Cleaning', 'price': 2500.0},
        {'name': '4+ Bedrooms Regular Cleaning', 'price': 3000.0},
        {'name': '1 Bedroom Deep Cleaning', 'price': 2500.0},
        {'name': '2 Bedrooms Deep Cleaning', 'price': 3000.0},
        {'name': '3 Bedrooms Deep Cleaning', 'price': 3500.0},
        {'name': '4+ Bedrooms Deep Cleaning', 'price': 4000.0},
        {'name': 'Window Cleaning', 'price': 500.0},
        {'name': 'Fridge Cleaning', 'price': 800.0},
        {'name': 'Oven Cleaning', 'price': 1000.0},
      ],
    },
    {
      'id': '3',
      'name': 'Garden Maintenance',
      'description': 'Professional garden and lawn care services',
      'category': 'Outdoor',
      'items': [
        {'name': 'Small Garden (up to 100 sqm)', 'price': 1500.0},
        {'name': 'Medium Garden (100-300 sqm)', 'price': 2500.0},
        {'name': 'Large Garden (300+ sqm)', 'price': 3500.0},
        {'name': 'Hedge Trimming', 'price': 800.0},
        {'name': 'Tree Pruning', 'price': 1200.0},
        {'name': 'Flower Bed Maintenance', 'price': 1000.0},
      ],
    },
  ];

  void _showAddServiceDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedCategory = 'Laundry';
    final List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add New Service',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    hintText: 'e.g., Laundry Services',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your service...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: ['Laundry', 'Cleaning', 'Outdoor', 'Other']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Service Items',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            hintText: 'e.g., Shirts Ironing',
                          ),
                          onChanged: (value) {
                            item['name'] = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Price (KES)',
                            hintText: '0.00',
                            prefixText: 'KES ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            item['price'] = double.tryParse(value) ?? 0.0;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      items.add({
                        'name': '',
                        'price': 0.0,
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle adding new service
                Navigator.pop(context);
              },
              child: const Text('Add Service'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                service['name'] as String,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(service['description'] as String),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service['category'] as String,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              children: [
                ...(service['items'] as List).map((item) {
                  return ListTile(
                    title: Text(item['name'] as String),
                    trailing: Text(
                      'KES ${(item['price'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
                ButtonBar(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Handle service editing
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Handle service deletion
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceDialog,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
} 