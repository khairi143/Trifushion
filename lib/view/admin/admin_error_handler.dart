import 'package:flutter/material.dart';

class AdminErrorHandler {
  static void showControlledError(
    BuildContext context, 
    String message, {
    bool isSuccess = false,
    Duration? duration,
  }) {
    if (!context.mounted) return;
    
    // Clear any existing SnackBars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show controlled error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: duration ?? Duration(seconds: isSuccess ? 2 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    // Log error for debugging
    print('Admin Error: $error');
    
    // Show user-friendly message
    String message = customMessage ?? 'An error occurred. Please try again.';
    showControlledError(context, message, isSuccess: false);
  }
  
  static void showSuccess(
    BuildContext context,
    String message,
  ) {
    showControlledError(context, message, isSuccess: true);
  }
  
  // Silent error logging (no UI display)
  static void logError(String operation, dynamic error) {
    print('[$operation] Error: $error');
    // Could also send to crash reporting service here
  }
} 