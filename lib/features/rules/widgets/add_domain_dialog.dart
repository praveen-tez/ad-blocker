import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/filter_rule.dart';

class AddDomainDialog extends StatefulWidget {
  final Function(String domain, RuleType type, String note) onAdd;

  const AddDomainDialog({super.key, required this.onAdd});

  @override
  State<AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<AddDomainDialog> {
  final _domainController = TextEditingController();
  final _noteController = TextEditingController();
  RuleType _selectedType = RuleType.block;
  String? _errorMessage;

  @override
  void dispose() {
    _domainController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final domain = _domainController.text.trim().toLowerCase();
    final domainRegex = RegExp(
      r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
    );

    if (domain.isEmpty) {
      setState(() => _errorMessage = 'Domain cannot be empty');
      return;
    }

    if (!domainRegex.hasMatch(domain)) {
      setState(() => _errorMessage = 'Enter a valid domain (e.g., ads.example.com)');
      return;
    }

    widget.onAdd(domain, _selectedType, _noteController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Add Custom Domain Rule',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select rule policy:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    type: RuleType.block,
                    label: 'Block Domain',
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeOption(
                    type: RuleType.allow,
                    label: 'Allow (Bypass)',
                    color: AppColors.activeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_selectedType == RuleType.allow)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.activeGreen.withAlpha(50)),
                ),
                child: const Text(
                  'Note: Allowlist rules strictly override all blocklist categories and custom block rules.',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.activeGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextField(
              controller: _domainController,
              autocorrect: false,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., tracker.domain.com',
                labelText: 'Domain Name',
                errorText: _errorMessage,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Optional label or reason',
                labelText: 'Label / Note',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _selectedType == RuleType.block
                ? AppColors.errorRed
                : AppColors.activeGreen,
          ),
          child: const Text('Add Rule'),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required RuleType type,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
