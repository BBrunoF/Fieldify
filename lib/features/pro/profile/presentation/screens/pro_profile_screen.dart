import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../controllers/pro_profile_controller.dart';

// ── Validation ─────────────────────────────────────────────────────────────────

String? _validateRequired(String? v, String label) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  if (v.trim().length < 2) return '$label is too short';
  return null;
}

String? _validateNif(String? v) {
  if (v == null || v.trim().isEmpty) return 'NIF is required';
  final digits = v.replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^\d{9}$').hasMatch(digits)) return 'NIF must be 9 digits';
  return null;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class ProProfileScreen extends StatefulWidget {
  final ProProfileController? controller;

  const ProProfileScreen({super.key, this.controller});

  @override
  State<ProProfileScreen> createState() => _ProProfileScreenState();
}

class _ProProfileScreenState extends State<ProProfileScreen> {
  late final ProProfileController _controller;
  late final bool _ownsController;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _nifCtrl;
  late final TextEditingController _bioCtrl;

  bool _dirty = false;
  bool _profileInitialized = false;
  bool _initializing = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProProfileController();
    _ownsController = widget.controller == null;

    final p = _controller.profile;
    _profileInitialized = p != null;
    _firstCtrl = TextEditingController(text: p?.firstName ?? '');
    _lastCtrl = TextEditingController(text: p?.lastName ?? '');
    _nifCtrl = TextEditingController(text: p?.nif ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');

    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;

    if (!_profileInitialized &&
        _controller.profile != null &&
        !_controller.isLoading &&
        !_dirty) {
      _profileInitialized = true;
      final p = _controller.profile!;
      _initializing = true;
      _firstCtrl.text = p.firstName;
      _lastCtrl.text = p.lastName;
      _nifCtrl.text = p.nif;
      _bioCtrl.text = p.bio;
      _initializing = false;
      setState(() => _dirty = false);
      return;
    }

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
    _nifCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_initializing) return;
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _controller.saveProfile(
      bio: _bioCtrl.text,
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      nif: _nifCtrl.text,
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _controller.uploadAvatar(File(picked.path));
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: FieldifyColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Photo library',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickAvatar(source);
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
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                        key: _formKey,
                        onChanged: _markDirty,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatar(),
                              const SizedBox(height: 16),
                              _buildStatusBadge(),
                              const SizedBox(height: 24),
                              _buildSectionLabel('Personal details'),
                              const SizedBox(height: 10),
                              _buildPersonalFields(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Trade & rate'),
                              const SizedBox(height: 10),
                              _buildTradeInfo(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Bio'),
                              const SizedBox(height: 10),
                              _buildBioField(),
                              const SizedBox(height: 28),
                              _controller.isSaving
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      key: const Key('proProfileSaveButton'),
                                      onPressed: _dirty ? _save : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FieldifyColors.g800,
                                        foregroundColor: FieldifyColors.g100,
                                        disabledBackgroundColor:
                                            FieldifyColors.ink4,
                                        minimumSize:
                                            const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withAlpha(51), width: 1.5),
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: FieldifyColors.g100, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'My profile',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
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

  Widget _buildAvatar() {
    final profile = _controller.profile;
    final initials = profile?.initials ?? '?';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FieldifyColors.g800,
              border: Border.all(color: FieldifyColors.surface, width: 3),
            ),
            child: ClipOval(
              child: _controller.isUploadingAvatar
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: FieldifyColors.g100,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _controller.avatarSignedUrl != null
                      ? Image.network(
                          _controller.avatarSignedUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) => _AvatarInitials(initials),
                        )
                      : _AvatarInitials(initials),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _controller.isUploadingAvatar ? null : _showPhotoSourceSheet,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FieldifyColors.g700,
                  shape: BoxShape.circle,
                  border: Border.all(color: FieldifyColors.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _controller.profile?.verificationStatus ?? 'pending';
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case 'approved':
        label = 'Verified';
        bg = const Color(0xFFD6F5E3);
        fg = const Color(0xFF1A6B3A);
      case 'rejected':
        label = 'Not approved';
        bg = const Color(0xFFFFE4E1);
        fg = const Color(0xFFC0392B);
      default:
        label = 'Under review';
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF7D5A00);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: FieldifyColors.ink3,
        letterSpacing: 0.44,
      ),
    );
  }

  Widget _buildPersonalFields() {
    final isApproved = _controller.profile?.isApproved ?? false;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'First name',
                child: isApproved
                    ? _LockedField(value: _controller.profile?.firstName ?? '')
                    : TextFormField(
                        key: const Key('proProfileFirstNameField'),
                        controller: _firstCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(hint: 'Bruno'),
                        validator: (v) => _validateRequired(v, 'First name'),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Last name',
                child: isApproved
                    ? _LockedField(value: _controller.profile?.lastName ?? '')
                    : TextFormField(
                        key: const Key('proProfileLastNameField'),
                        controller: _lastCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(hint: 'Silva'),
                        validator: (v) => _validateRequired(v, 'Last name'),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'NIF',
          child: isApproved
              ? _LockedField(value: _controller.profile?.nif ?? '')
              : TextFormField(
                  key: const Key('proProfileNifField'),
                  controller: _nifCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: FieldifyColors.ink),
                  decoration: authInputDecoration(hint: '123456789'),
                  validator: _validateNif,
                ),
        ),
      ],
    );
  }

  Widget _buildTradeInfo() {
    final profile = _controller.profile;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FieldifyColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Trade',
            value: profile?.tradeName.isEmpty == false
                ? profile!.tradeName
                : '—',
          ),
          const Divider(height: 1, color: Color(0x14000000)),
          _InfoRow(
            label: 'Standard rate',
            value: profile != null && profile.standardRate > 0
                ? '€${profile.standardRate}/h'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      key: const Key('proProfileBioField'),
      controller: _bioCtrl,
      maxLines: 5,
      maxLength: 500,
      style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
      decoration: authInputDecoration(
        hint: 'Tell clients a bit about yourself…',
      ).copyWith(
        alignLabelWithHint: true,
        counterStyle:
            GoogleFonts.dmSans(fontSize: 11, color: FieldifyColors.ink3),
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _AvatarInitials extends StatelessWidget {
  final String initials;
  const _AvatarInitials(this.initials);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: FieldifyColors.g100,
        ),
      ),
    );
  }
}

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

class _LockedField extends StatelessWidget {
  final String value;
  const _LockedField({required this.value});

  @override
  Widget build(BuildContext context) {
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
              value.isEmpty ? '—' : value,
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: FieldifyColors.ink3),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: FieldifyColors.g100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Cannot change',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.g700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: FieldifyColors.ink2)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.ink)),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FieldifyColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: FieldifyColors.ink2),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: FieldifyColors.ink)),
          ],
        ),
      ),
    );
  }
}
