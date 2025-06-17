import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final List<WorkflowStep> _steps = [];
  final _stepController = TextEditingController();

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _addStep() {
    if (_stepController.text.isNotEmpty) {
      setState(() {
        _steps.add(WorkflowStep(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _stepController.text,
          description: '',
          icon: Icons.cleaning_services,
        ));
        _stepController.clear();
      });
    }
  }

  void _removeStep(String id) {
    setState(() {
      _steps.removeWhere((step) => step.id == id);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Workflow Setup',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_steps.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                // TODO: Save workflow
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Your Workflow',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add steps to your workflow. These will be shown to customers to track their order progress.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stepController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter step name (e.g., Washing, Drying)',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add_circle),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              onReorder: _reorderSteps,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Card(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        step.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Step ${index + 1}: ${step.title}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            // TODO: Edit step
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeStep(step.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
} 