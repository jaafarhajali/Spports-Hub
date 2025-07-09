import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showLabel;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showLabel = true,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = ValidationUtils.getPasswordStrength(password);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          // Strength indicator bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: strength.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: strength.color,
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                Text(
                  strength.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strength.color,
                  ),
                ),
              ],
            ],
          ),
          
          if (showRequirements) ...[
            const SizedBox(height: 12),
            // Password requirements checklist
            _buildRequirementsList(isDarkMode),
          ],
        ],
      ],
    );
  }

  Widget _buildRequirementsList(bool isDarkMode) {
    final requirements = [
      _PasswordRequirement(
        'At least 8 characters',
        password.length >= 8,
      ),
      _PasswordRequirement(
        'One uppercase letter',
        RegExp(r'[A-Z]').hasMatch(password),
      ),
      _PasswordRequirement(
        'One lowercase letter',
        RegExp(r'[a-z]').hasMatch(password),
      ),
      _PasswordRequirement(
        'One number',
        RegExp(r'[0-9]').hasMatch(password),
      ),
      _PasswordRequirement(
        'One special character',
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((requirement) => 
            _buildRequirementItem(requirement, isDarkMode)
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(_PasswordRequirement requirement, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            requirement.isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: requirement.isMet 
                ? Colors.green 
                : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Text(
            requirement.text,
            style: TextStyle(
              fontSize: 12,
              color: requirement.isMet
                  ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                  : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              fontWeight: requirement.isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirement {
  final String text;
  final bool isMet;

  _PasswordRequirement(this.text, this.isMet);
}