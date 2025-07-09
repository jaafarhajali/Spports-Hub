import 'package:flutter/material.dart';

class FormValidationSummary extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<String> customErrors;
  final bool showOnlyIfErrors;

  const FormValidationSummary({
    super.key,
    required this.formKey,
    this.customErrors = const [],
    this.showOnlyIfErrors = true,
  });

  @override
  Widget build(BuildContext context) {
    final errors = _getFormErrors();
    
    if (showOnlyIfErrors && errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errors.isEmpty 
            ? (isDarkMode ? Colors.green.shade800.withOpacity(0.2) : Colors.green.shade50)
            : (isDarkMode ? Colors.red.shade800.withOpacity(0.2) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errors.isEmpty 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errors.isEmpty ? Icons.check_circle : Icons.error,
                color: errors.isEmpty ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                errors.isEmpty 
                    ? 'Form is valid and ready to submit'
                    : 'Please fix the following issues:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: errors.isEmpty 
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  List<String> _getFormErrors() {
    final errors = <String>[];
    
    // Add custom errors first
    errors.addAll(customErrors);
    
    // Get form validation errors
    if (formKey.currentState != null) {
      final form = formKey.currentState!;
      
      // We need to validate to get the errors
      if (!form.validate()) {
        // Unfortunately, Flutter doesn't provide a direct way to get all validation errors
        // This is a limitation of the FormState API
        // For now, we'll show a generic message if there are form validation errors
        if (errors.isEmpty) {
          errors.add('Please check all required fields and fix any validation errors');
        }
      }
    }
    
    return errors;
  }
}

/// A helper widget that can be used to collect and display validation errors
class ValidationErrorCollector extends StatefulWidget {
  final Widget child;
  final Function(List<String>) onErrorsChanged;

  const ValidationErrorCollector({
    super.key,
    required this.child,
    required this.onErrorsChanged,
  });

  @override
  State<ValidationErrorCollector> createState() => _ValidationErrorCollectorState();
}

class _ValidationErrorCollectorState extends State<ValidationErrorCollector> {
  final List<String> _errors = [];

  void addError(String error) {
    if (!_errors.contains(error)) {
      setState(() {
        _errors.add(error);
      });
      widget.onErrorsChanged(_errors);
    }
  }

  void removeError(String error) {
    setState(() {
      _errors.remove(error);
    });
    widget.onErrorsChanged(_errors);
  }

  void clearErrors() {
    setState(() {
      _errors.clear();
    });
    widget.onErrorsChanged(_errors);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Enhanced TextFormField with better error display
class EnhancedTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final String? helperText;
  final int? maxLength;

  const EnhancedTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.helperText,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSaved: onSaved,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon != null 
                ? Icon(
                    prefixIcon,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  )
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: enabled 
                ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50)
                : (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Enhanced error style
            errorStyle: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            helperStyle: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          style: TextStyle(
            color: enabled 
                ? (isDarkMode ? Colors.white : Colors.black87)
                : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}