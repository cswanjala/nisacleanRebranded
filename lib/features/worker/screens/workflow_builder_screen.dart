import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _WorkflowBuilderScreenState extends State<WorkflowBuilderScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _stepController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fetchWorkflow();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _stepController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        throw 'Authentication token not found';
      }

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
            _steps = workflow.map((step) => {
              'title': step['title'] ?? '',
              'description': step['description'] ?? '',
            }).toList();
            _isLoading = false;
          });
        } else {
      setState(() {
            _steps = [];
        _isLoading = false;
      });
        }
      } else {
        throw 'Failed to fetch workflow: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addStep() {
    if (_stepController.text.trim().isNotEmpty) {
      setState(() {
        _steps.add({
          'title': _stepController.text.trim(),
          'description': _descriptionController.text.trim(),
        });
        _stepController.clear();
        _descriptionController.clear();
      });
    }
  }

  void _removeStepAt(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _editStep(int index) {
    final step = _steps[index];
    _stepController.text = step['title'] ?? '';
    _descriptionController.text = step['description'] ?? '';
    
    _showEditStepDialog(index);
  }

  Future<void> _saveWorkflow() async {
    setState(() { 
      _isSaving = true; 
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw 'Authentication token not found';
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/service/create-workflow/${widget.serviceId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'workflow': _steps,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Workflow saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else {
        throw data['message'] ?? 'Failed to save workflow';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save workflow: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() { 
        _isSaving = false; 
      });
    }
  }

  Future<void> _deleteWorkflow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Workflow',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this workflow? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { 
        _isSaving = true; 
      });
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token == null) {
          throw 'Authentication token not found';
        }

        // Clear the workflow by setting it to an empty array
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
          if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Workflow deleted successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        } else {
          throw data['message'] ?? 'Failed to delete workflow';
        }
      } catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to delete workflow: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } finally {
        setState(() { 
          _isSaving = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workflow Builder',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              _steps.isEmpty 
                  ? widget.serviceName
                  : '${widget.serviceName} • ${_steps.length} step${_steps.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_steps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isSaving ? null : _deleteWorkflow,
              tooltip: 'Delete Workflow',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: _steps.isEmpty
                              ? _buildEmptyState()
                              : _buildWorkflowList(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _steps.isEmpty ? null : Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181A20),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddStepDialog,
                  icon: Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.primary),
                  label: Text('Add Step', style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  )),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveWorkflow,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 20),
                  label: Text(_isSaving ? 'Saving...' : 'Save Workflow', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.assignment,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  children: [
                  Text(
                    '${_steps.length} Workflow Steps',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_steps.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Add more steps to complete your workflow',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
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
            child: Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Workflow Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding workflow steps\nto define your service process',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddStepDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Step'),
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

  Widget _buildWorkflowList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: _steps.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final step = _steps[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _editStep(index),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                step['title'] ?? 'Untitled Step',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _editStep(index),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.edit, color: Colors.white54, size: 19),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _removeStepAt(index),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.delete, color: Colors.red[400], size: 19),
                              ),
                            ),
                          ],
                        ),
                        if (step['description']?.toString().isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            step['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 13.2,
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isSaving ? null : _saveWorkflow,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: _isSaving 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save),
      label: Text(
        _isSaving ? 'Saving...' : 'Save Workflow',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something Went Wrong',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _fetchWorkflow,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
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

  void _showAddStepDialog() {
    _showStepFormDialog(null);
  }

  void _showEditStepDialog(int index) {
    _showStepFormDialog(index);
  }

  void _showStepFormDialog(int? index) {
    final isEditing = index != null;
    if (isEditing) {
      final step = _steps[index!];
      _stepController.text = step['title'] ?? '';
      _descriptionController.text = step['description'] ?? '';
    } else {
      _stepController.clear();
      _descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            isEditing ? 'Edit Step' : 'Add Workflow Step ${_steps.length + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            isEditing 
                                ? 'Update step details'
                                : 'Step ${_steps.length + 1} of your workflow',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        controller: _stepController,
                        label: isEditing ? 'Step Title' : 'Step ${_steps.length + 1} Title',
                        hint: 'e.g., Initial Assessment, Deep Cleaning',
                        icon: Icons.title,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _descriptionController,
                        label: 'Step Description',
                        hint: 'Describe what this step involves...',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                      onPressed: () {
                          if (_stepController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Step title is required'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (isEditing) {
                            setState(() {
                              _steps[index!] = {
                                'title': _stepController.text.trim(),
                                'description': _descriptionController.text.trim(),
                              };
                            });
                          } else {
                        _addStep();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Step ${_steps.length} added successfully!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing ? 'Update Step' : 'Add Step',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
} 