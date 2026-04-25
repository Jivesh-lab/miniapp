import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      if (icon != null) {
        return OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIconOrLoader(),
          label: Text(label),
        );
      }
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChildOrLoader(),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: _buildIconOrLoader(),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildChildOrLoader(),
    );
  }

  Widget _buildIconOrLoader() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(icon);
  }

  Widget _buildChildOrLoader() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(label);
  }
}
