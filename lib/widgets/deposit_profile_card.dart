import 'package:flutter/material.dart';
import '../models/deposit_model.dart';
import '../providers/deposit_provider.dart';
import 'package:provider/provider.dart';

class DepositProfileCard extends StatelessWidget {
  final DepositProfile profile;
  final VoidCallback onTap;

  const DepositProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final balance = depositProvider.getProfileBalance(profile.id);
    final progress = depositProvider.getProfileProgress(profile.id);
    final daysRemaining = depositProvider.getDaysRemaining(profile.id);
    final isOnTrack = depositProvider.isOnTrack(profile.id);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine status color
    Color statusColor;
    if (profile.isCompleted) {
      statusColor = Colors.green;
    } else if (daysRemaining < 0) {
      statusColor = Colors.red; // Overdue
    } else if (isOnTrack) {
      statusColor = Colors.blue; // On track
    } else {
      statusColor = Colors.orange; // Behind
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: profile.isCompleted
                ? LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile name
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  if (profile.isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    )
                  else
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Balance / Target
              Text(
                '${balance.toStringAsFixed(0)} / ${profile.targetAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),

              // Days remaining or status
              if (profile.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      daysRemaining < 0
                          ? Icons.warning_rounded
                          : Icons.timer_outlined,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      daysRemaining < 0
                          ? '${daysRemaining.abs()} days overdue'
                          : '$daysRemaining days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
