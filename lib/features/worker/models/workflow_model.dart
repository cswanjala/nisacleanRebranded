import 'package:flutter/foundation.dart';

class Workflow {
  final String id;
  final String service;
  final List<WorkflowStep> steps;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workflow({
    required this.id,
    required this.service,
    required this.steps,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['_id'] as String,
      service: json['service'] as String,
      steps: (json['steps'] as List)
          .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'service': service,
      'steps': steps.map((e) => e.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class WorkflowStep {
  final String? id;
  final String title;
  final String description;
  final int order;

  WorkflowStep({
    this.id,
    required this.title,
    required this.description,
    required this.order,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'description': description,
      'order': order,
    };
  }
} 