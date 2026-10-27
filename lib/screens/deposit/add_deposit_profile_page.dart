import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_format.dart';
import '../../widgets/ui/app_ui.dart';

class AddDepositProfilePage extends StatefulWidget {
  final DepositProfile? profile; // For editing existing profile

  const AddDepositProfilePage({super.key, this.profile});

  @override
  State<AddDepositProfilePage> createState() => _AddDepositProfilePageState();
}

class _AddDepositProfilePageState extends State<AddDepositProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 30));

  bool get isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.profile!.name;
      _targetController.text = widget.profile!.targetAmount.toString();
      _noteController.text = widget.profile!.note;
      _selectedStartDate = widget.profile!.createdDate;
      _selectedEndDate = widget.profile!.deadline;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: _selectedEndDate,
    );
    if (picked != null) setState(() => _selectedStartDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _selectedEndDate = picked);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);

    final profile = DepositProfile(
      id: isEditing
          ? widget.profile!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      targetAmount: AppFormat.parseAmount(_targetController.text)!,
      // The deadline is the end of the saving period
      deadline: _selectedEndDate,
      createdDate: isEditing ? widget.profile!.createdDate : _selectedStartDate,
      note: _noteController.text.trim(),
      isCompleted: isEditing ? widget.profile!.isCompleted : false,
      completedDate: isEditing ? widget.profile!.completedDate : null,
    );
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);

    showAppSnack(context, isEditing ? l.profileUpdated : l.profileCreated);
    Navigator.pop(context);

    // Saved locally at once; the cloud copy syncs in the background
    try {
      if (isEditing) {
        await depositProvider.updateProfile(profile);
      } else {
        await depositProvider.addProfile(profile);
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final days = _selectedEndDate.difference(_selectedStartDate).inDays;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? l.editProfile : l.createProfile),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AmountField(
              controller: _targetController,
              label: l.targetAmount,
              color: scheme.primary,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l.pleaseEnterAmount;
                }
                final amount = AppFormat.parseAmount(value);
                if (amount == null || amount <= 0) {
                  return l.pleaseEnterValidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.profileName,
                hintText: l.profileNameHint,
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l.pleaseEnterName
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    label: l.startDate,
                    value: AppFormat.date(context, _selectedStartDate),
                    icon: Icons.play_circle_outline_rounded,
                    showChevron: false,
                    onTap: () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PickerField(
                    label: l.endDate,
                    value: AppFormat.date(context, _selectedEndDate),
                    icon: Icons.flag_outlined,
                    showChevron: false,
                    onTap: () => _selectEndDate(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                l.daysLeft(days),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.noteOptional,
                hintText: l.noteHint,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),
            SubmitButton(
              label: isEditing ? l.updateProfile : l.saveProfile,
              icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
