import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../../../auth/data/services/profile_service.dart';

// ── Validation ────────────────────────────────────────────────────────────────

String? _validateRequired(String? v, String label) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  if (v.trim().length < 2) return '$label is too short';
  return null;
}

String? _validatePhone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Phone is required';
  final digits = v.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  if (!RegExp(r'^\d{9,15}$').hasMatch(digits)) return 'Invalid phone number';
  return null;
}

String? _validateAddress(String? v) {
  if (v == null || v.trim().isEmpty) return 'Address cannot be empty';
  if (v.trim().length < 8) return 'Address is too short';
  if (!RegExp(r'\d').hasMatch(v)) return 'Include a street number';
  return null;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;

  late List<String> _addresses;

  bool _loading = false;
  bool _dirty = false;
  String? _saveError;
  String? _saveSuccess;

  @override
  void initState() {
    super.initState();
    final parts = _service.fullName.split(' ');
    _firstCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _lastCtrl  = TextEditingController(text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _phoneCtrl = TextEditingController(text: _service.phone);
    _addresses = List<String>.from(_service.addresses);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() { _dirty = true; _saveSuccess = null; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _saveError = null; _saveSuccess = null; });
    try {
      await _service.updatePersonalDetails(
        firstName: _firstCtrl.text,
        lastName: _lastCtrl.text,
        phone: _phoneCtrl.text,
      );
      await _service.updateAddresses(_addresses);
      if (!mounted) return;
      setState(() { _dirty = false; _saveSuccess = 'Profile updated'; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addAddress() {
    _showAddressSheet(null, (addr) {
      setState(() { _addresses.add(addr); _dirty = true; _saveSuccess = null; });
    });
  }

  void _editAddress(int index) {
    _showAddressSheet(_addresses[index], (addr) {
      setState(() { _addresses[index] = addr; _dirty = true; _saveSuccess = null; });
    });
  }

  void _removeAddress(int index) {
    setState(() { _addresses.removeAt(index); _dirty = true; _saveSuccess = null; });
  }

  void _showAddressSheet(String? initial, void Function(String) onSave) {
    final ctrl = TextEditingController(text: initial);
    final sheetFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: FieldifyColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: sheetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FieldifyColors.ink4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  initial == null ? 'Add address' : 'Edit address',
                  style: GoogleFonts.dmSans(
                      fontSize: 17, fontWeight: FontWeight.w500, color: FieldifyColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Include street, number and city.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
                  decoration: authInputDecoration(hint: 'Rua do Heroísmo 42, Porto'),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (!sheetFormKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    onSave(ctrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: FieldifyColors.g100,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    initial == null ? 'Add' : 'Save',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w500, color: FieldifyColors.g100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: FieldifyColors.g800,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FieldifyColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  onChanged: _markDirty,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('Personal details', _buildPersonalFields()),
                        const SizedBox(height: 20),
                        _buildSection('Email', _buildEmailRow()),
                        const SizedBox(height: 20),
                        _buildAddressSection(),
                        const SizedBox(height: 28),
                        if (_saveError != null) ...[
                          _buildFeedback(_saveError!, isError: true),
                          const SizedBox(height: 12),
                        ],
                        if (_saveSuccess != null) ...[
                          _buildFeedback(_saveSuccess!, isError: false),
                          const SizedBox(height: 12),
                        ],
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                key: const Key('profileSaveButton'),
                                onPressed: _dirty ? _save : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FieldifyColors.g800,
                                  foregroundColor: FieldifyColors.g100,
                                  disabledBackgroundColor: FieldifyColors.ink4,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Save changes',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: FieldifyColors.g100),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: FieldifyColors.g800,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
                    ),
                    child: const Icon(Icons.chevron_left, color: FieldifyColors.g100, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'My profile',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 18,
            color: FieldifyColors.g800,
            child: Container(
              decoration: const BoxDecoration(
                color: FieldifyColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink3,
              letterSpacing: 0.44),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildPersonalFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'First name',
                child: TextFormField(
                  key: const Key('profileFirstNameField'),
                  controller: _firstCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
                  decoration: authInputDecoration(hint: 'Bruno'),
                  validator: (v) => _validateRequired(v, 'First name'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Last name',
                child: TextFormField(
                  key: const Key('profileLastNameField'),
                  controller: _lastCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
                  decoration: authInputDecoration(hint: 'Silva'),
                  validator: (v) => _validateRequired(v, 'Last name'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Phone',
          child: TextFormField(
            key: const Key('profilePhoneField'),
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
            decoration: authInputDecoration(hint: '+351 912 345 678'),
            validator: _validatePhone,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FieldifyColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _service.email,
              style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink3),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: FieldifyColors.g100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Cannot change',
              style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w500, color: FieldifyColors.g700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ADDRESSES',
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.ink3,
                  letterSpacing: 0.44),
            ),
            GestureDetector(
              key: const Key('profileAddAddressButton'),
              onTap: _addAddress,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: FieldifyColors.g700),
                  const SizedBox(width: 3),
                  Text(
                    'Add',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w500, color: FieldifyColors.g700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FieldifyColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: FieldifyColors.ink4),
                const SizedBox(width: 10),
                Text(
                  'No saved addresses',
                  style: GoogleFonts.dmSans(fontSize: 14, color: FieldifyColors.ink4),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FieldifyColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _addresses.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0x14000000)),
                  _AddressRow(
                    address: _addresses[i],
                    onEdit: () => _editAddress(i),
                    onDelete: () => _removeAddress(i),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeedback(String msg, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFDECEA) : FieldifyColors.g100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? const Color(0xFFC0392B) : FieldifyColors.g800,
          ),
          const SizedBox(width: 8),
          Text(
            msg,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isError ? const Color(0xFFC0392B) : FieldifyColors.g800),
          ),
        ],
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AddressRow({required this.address, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18, color: FieldifyColors.g700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              address,
              style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.edit_outlined, size: 16, color: FieldifyColors.ink3),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }
}
