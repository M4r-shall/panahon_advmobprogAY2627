import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Extracted from signin_screen so the same InputDecoration is not repeated for
// every field. The signup screen alone needs eight of them.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    OutlineInputBorder borderWith(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: color),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: theme.hintColor),
        hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        filled: true,
        fillColor: theme.cardColor,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Hide the "0/15" counter that maxLength adds by default.
        counterText: '',
        border: borderWith(theme.cardColor),
        enabledBorder: borderWith(theme.cardColor),
        disabledBorder: borderWith(theme.cardColor),
        focusedBorder: borderWith(theme.colorScheme.primary),
        errorBorder: borderWith(Colors.redAccent),
        focusedErrorBorder: borderWith(Colors.redAccent),
      ),
    );
  }
}
