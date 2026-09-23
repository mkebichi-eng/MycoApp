import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MycoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;
  final double height;

  const MycoButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = AppConstants.primaryGreen,
    this.textColor = Colors.white,
    this.isLoading = false,
    this.height = 56.0, // Touch target confortable pour les ouvriers et livreurs
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24, color: textColor),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
