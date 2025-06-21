import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workflow_model.dart';
import '../services/workflow_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';

class WorkflowBuilderScreen extends StatefulWidget {
  final String serviceName;
  final String serviceId;

  const WorkflowBuilderScreen({
    super.key,
    required this.serviceName,
    required this.serviceId,
  });

  @override
  State<WorkflowBuilderScreen> createState() => _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends State<WorkflowBuilderScreen> {
  final WorkflowService _workflowService = WorkflowService();
  Workflow? _workflow;
  List<WorkflowStep> _steps = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _stepController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWorkflow();
  }

  Future<void> _fetchWorkflow() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _error = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      // Use the new dedicated workflow endpoint
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/service/workflow/${widget.serviceId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final workflow = data['data']['workflow'] as List<dynamic>? ?? [];
          setState(() {
            _steps = workflow.map((step) => WorkflowStep(
              title: step['title'] ?? '',
              description: step['description'] ?? '',
              order: _steps.length + 1,
            )).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _steps = [];
            _isLoading = false;
          });
        }
      } else {
      setState(() {
          _error = 'Failed to fetch workflow: ${response.statusCode}';
        _isLoading = false;
      });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _addStep() {
    if (_stepController.text.isNotEmpty) {
      setState(() {
        _steps.add(WorkflowStep(
          title: _stepController.text,
          description: _descriptionController.text,
          order: _steps.length + 1,
        ));
        _stepController.clear();
        _descriptionController.clear();
      });
    }
  }

  void _removeStepAt(int index) {
    setState(() {
      _steps.removeAt(index);
      // Reorder
      for (var i = 0; i < _steps.length; i++) {
        _steps[i] = WorkflowStep(
          id: _steps[i].id,
          title: _steps[i].title,
          description: _steps[i].description,
          order: i + 1,
        );
      }
    });
  }

  Future<void> _saveWorkflow() async {
    setState(() { _isSaving = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw 'Authentication token not found';
      }

      // Convert steps to the format expected by the API
      final workflowSteps = _steps.map((step) => {
        'title': step.title,
        'description': step.description,
      }).toList();

      // Use the new dedicated workflow creation endpoint
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/service/create-workflow/${widget.serviceId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'workflow': workflowSteps,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow saved successfully!'), backgroundColor: Colors.green),
        );
      } else {
        throw data['message'] ?? 'Failed to save workflow';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save workflow: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  Future<void> _deleteWorkflow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Workflow', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this workflow?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { _isSaving = true; });
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token == null) {
          throw 'Authentication token not found';
        }

        // Clear the workflow by setting it to an empty array using the new endpoint
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/service/create-workflow/${widget.serviceId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'workflow': [],
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _steps = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workflow deleted successfully!'), backgroundColor: Colors.green),
        );
        } else {
          throw data['message'] ?? 'Failed to delete workflow';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete workflow: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 8),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workflow Builder', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(widget.serviceName, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w400, fontSize: 14)),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: GoogleFonts.poppins(color: Colors.redAccent)))
              : Column(
                  children: [
                    const Divider(height: 1, color: Colors.white12, thickness: 1),
                    if (_workflow == null && _steps.isEmpty)
                      Expanded(child: _buildEmptyState())
                    else ...[
                      _buildHeaderActions(),
                      Expanded(child: _buildStepper()),
                    ],
                  ],
                ),
      floatingActionButton: _steps.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveWorkflow,
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('No Workflow Yet', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Tap below to create a workflow for this service.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() { _steps = []; }),
            icon: const Icon(Icons.add),
            label: const Text('Create Workflow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text('${_steps.length} step${_steps.length == 1 ? '' : 's'}', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 15)),
          const Spacer(),
          if (_workflow != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete Workflow',
              onPressed: _isSaving ? null : _deleteWorkflow,
            ),
          FloatingActionButton.small(
            onPressed: () => _showAddStepDialog(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
            heroTag: 'addStep',
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${index + 1}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23262F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(step.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                              tooltip: 'Edit Step',
                              onPressed: () => _showEditStepDialog(context, step, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              tooltip: 'Delete Step',
                              onPressed: () => _removeStepAt(index),
                            ),
                          ],
                        ),
                        if (step.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(step.description, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddStepDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Workflow Step', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        Text('Step ${_steps.length + 1} of your workflow', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _stepController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Step Title',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Step Description (Optional)',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _stepController.clear();
                        _descriptionController.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 14)),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _addStep();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: const Text('Add Step'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStepDialog(BuildContext context, WorkflowStep step, int index) {
    final titleController = TextEditingController(text: step.title);
    final descriptionController = TextEditingController(text: step.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Step ${index + 1}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Step Title',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Step Description',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _steps[index] = WorkflowStep(
                  id: step.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  order: step.order,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 