import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../controllers/profile_controller.dart';

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
  final ProfileController? controller;

  const ProfileScreen({super.key, this.controller});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  late final bool _ownsController;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  late List<String> _addresses;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProfileController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);

    final p = _controller.profile;
    _firstCtrl = TextEditingController(text: p?.firstName ?? '');
    _lastCtrl  = TextEditingController(text: p?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _addresses = List<String>.from(p?.addresses ?? []);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});

    if (_controller.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.error!)));
      _controller.clearError();
    }

    if (_controller.saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: FieldifyColors.g700,
          ),
        );
      setState(() => _dirty = false);
      _controller.clearSaved();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _controller.saveAll(
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      phone: _phoneCtrl.text,
      addresses: _addresses,
    );
  }

  void _addAddress() {
    _showAddressSheet(null, (addr) {
      setState(() { _addresses.add(addr); _dirty = true; });
    });
  }

  void _editAddress(int i) {
    _showAddressSheet(_addresses[i], (addr) {
      setState(() { _addresses[i] = addr; _dirty = true; });
    });
  }

  void _removeAddress(int i) {
    setState(() { _addresses.removeAt(i); _dirty = true; });
  }

  void _showAddressSheet(String? initial, void Function(String) onSave) {
    final ctrl = TextEditingController(text: initial);
    final key  = GlobalKey<FormState>();

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
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
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
                    if (!key.currentState!.validate()) return;
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
                        _buildSectionLabel('Personal details'),
                        const SizedBox(height: 10),
                        _buildPersonalFields(),
                        const SizedBox(height: 20),
                        _buildSectionLabel('Email'),
                        const SizedBox(height: 10),
                        _buildEmailRow(),
                        const SizedBox(height: 20),
                        _buildAddressSection(),
                        const SizedBox(height: 28),
                        _controller.isSaving
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
                                    color: FieldifyColors.g100,
                                  ),
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
                    width: 34, height: 34,
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

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: FieldifyColors.ink3, letterSpacing: 0.44,
      ),
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
    final email = _controller.profile?.email ?? '';
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
            child: Text(email,
                style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink3)),
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
            _buildSectionLabel('Addresses'),
            GestureDetector(
              key: const Key('profileAddAddressButton'),
              onTap: _addAddress,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: FieldifyColors.g700),
                  const SizedBox(width: 3),
                  Text('Add',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w500, color: FieldifyColors.g700)),
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
                Text('No saved addresses',
                    style: GoogleFonts.dmSans(fontSize: 14, color: FieldifyColors.ink4)),
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
            child: Text(address,
                style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink, height: 1.4)),
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
