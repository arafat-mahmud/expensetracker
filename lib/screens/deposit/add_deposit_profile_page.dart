import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';

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

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
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
      _selectedDeadline = widget.profile!.deadline;
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

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: _selectedEndDate,
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        // Update deadline to match end date
        _selectedDeadline = _selectedEndDate;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        // Update deadline to match end date
        _selectedDeadline = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final localizations = AppLocalizations.of(context);

      final profile = DepositProfile(
        id: isEditing
            ? widget.profile!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        targetAmount: double.parse(_targetController.text.trim()),
        deadline: _selectedDeadline,
        createdDate: isEditing ? widget.profile!.createdDate : _selectedStartDate,
        note: _noteController.text.trim(),
        isCompleted: isEditing ? widget.profile!.isCompleted : false,
        completedDate: isEditing ? widget.profile!.completedDate : null,
      );

      final depositProvider =
          Provider.of<DepositProvider>(context, listen: false);

      // Show instant feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(isEditing
                    ? localizations.profileUpdated
                    : localizations.profileCreated),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Close the page immediately
      if (mounted) Navigator.pop(context);

      // Save in background
      try {
        if (isEditing) {
          await depositProvider.updateProfile(profile);
        } else {
          await depositProvider.addProfile(profile);
        }
      } catch (e) {
        print('Background sync error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue,
        title: Text(
          isEditing ? localizations.editProfile : localizations.createProfile,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    _buildFormCard(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.profileName,
                          hintText: 'e.g., Emergency Fund',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.savings_rounded,
                                color: Colors.blue[600]),
                          ),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizations.pleaseEnterName;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Amount Field
                    _buildFormCard(
                      child: TextFormField(
                        controller: _targetController,
                        decoration: InputDecoration(
                          labelText: localizations.targetAmount,
                          hintText: '0.00',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.attach_money_rounded,
                                color: Colors.green[600]),
                          ),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizations.pleaseEnterAmount;
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return localizations.pleaseEnterValidAmount;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date Picker
                    _buildFormCard(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.play_arrow_rounded,
                                    color: Colors.green[600]),
                              ),
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(_selectedStartDate),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date Picker
                    _buildFormCard(
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.stop_rounded,
                                    color: Colors.red[600]),
                              ),
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(_selectedEndDate),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${_selectedEndDate.difference(_selectedStartDate).inDays} days',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note Field
                    _buildFormCard(
                      child: TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: localizations.noteOptional,
                          hintText: 'Add a note...',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.note_rounded,
                                color: Colors.purple[600]),
                          ),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.blue.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saveProfile,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing
                                      ? Icons.update_rounded
                                      : Icons.save_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing
                                      ? localizations.updateProfile
                                      : localizations.saveProfile,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}
