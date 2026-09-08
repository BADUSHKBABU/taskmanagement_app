import 'package:flutter/material.dart';
import 'package:test1/core/constants/app_colors.dart';

class SyncIndicator extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;

  const SyncIndicator({
    super.key,
    required this.isOnline,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: AppColors.warningLight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'Offline Mode - Local changes will sync when connected',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (isSyncing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Syncing with Cloud Firestore...',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
