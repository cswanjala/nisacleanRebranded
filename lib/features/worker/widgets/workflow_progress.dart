import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkflowProgress extends StatelessWidget {
  final List<WorkflowStep> steps;
  final int currentStepIndex;

  const WorkflowProgress({
    super.key,
    required this.steps,
    required this.currentStepIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
              'Order Progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCompleted = index < currentStepIndex;
                final isCurrent = index == currentStepIndex;
                final isUpcoming = index > currentStepIndex;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : isCurrent
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : Text(
                                    '${index + 1}',
                                    style: GoogleFonts.poppins(
                                      color: isCurrent
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: GoogleFonts.poppins(
                                  color: isCompleted
                                      ? Colors.white
                                      : isCurrent
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white70,
                                  fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (step.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  step.description,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'In Progress',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Container(
                          width: 2,
                          height: 24,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
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