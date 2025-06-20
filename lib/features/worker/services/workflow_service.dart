import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workflow_model.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';

class WorkflowService {
  static const String baseUrl = ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Workflow?> getWorkflowForService(String serviceId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/workflow/workflows/$serviceId'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Workflow.fromJson(data['data']);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw data['message'] ?? 'Failed to fetch workflow';
    }
  }

  Future<Workflow> createWorkflow(String serviceId, List<WorkflowStep> steps) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/workflow/workflows'),
      headers: headers,
      body: jsonEncode({
        'service': serviceId,
        'steps': steps.map((e) => e.toJson()).toList(),
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Workflow.fromJson(data['data']);
    } else {
      throw data['message'] ?? 'Failed to create workflow';
    }
  }

  Future<Workflow> updateWorkflow(String workflowId, List<WorkflowStep> steps) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/workflow/workflows/$workflowId'),
      headers: headers,
      body: jsonEncode({
        'steps': steps.map((e) => e.toJson()).toList(),
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Workflow.fromJson(data['data']);
    } else {
      throw data['message'] ?? 'Failed to update workflow';
    }
  }

  Future<void> deleteWorkflow(String workflowId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/workflow/workflows/$workflowId'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    } else {
      throw data['message'] ?? 'Failed to delete workflow';
    }
  }
} 