import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../controllers/pro_profile_controller.dart';
import '../../controllers/work_settings_controller.dart';
import '../../data/models/availability_schedule_model.dart';

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

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  late final WorkSettingsController _workController;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _nifCtrl;
  late final TextEditingController _bioCtrl;
  late List<String> _credentialUrls;

  double _radiusSlider = 25;
  late final TextEditingController _radiusCtrl;

  // Work hours state
  final Map<int, List<_TimeSlot>> _daySlots = {};
  final Set<int> _enabledDays = {};
  bool _workSettingsInitialized = false;

  // Location state
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  int _selectedDay = 0;

  bool _dirty = false;
  bool _profileInitialized = false;
  bool _initializing = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProProfileController();
    _ownsController = widget.controller == null;
    _workController = WorkSettingsController();

    final p = _controller.profile;
    _profileInitialized = p != null;
    _firstCtrl = TextEditingController(text: p?.firstName ?? '');
    _lastCtrl = TextEditingController(text: p?.lastName ?? '');
    _nifCtrl = TextEditingController(text: p?.nif ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _radiusSlider = (p?.serviceRadiusKm ?? 25).toDouble().clamp(5, 150);
    _radiusCtrl = TextEditingController(text: _radiusSlider.round().toString());
    _credentialUrls = List<String>.from(p?.credentialUrls ?? []);
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();

    _controller.addListener(_onChanged);
    _workController.addListener(_onWorkChanged);
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
      _radiusSlider = (p.serviceRadiusKm ?? 25).toDouble().clamp(5, 150);
      _radiusCtrl.text = _radiusSlider.round().toString();
      _credentialUrls = List<String>.from(p.credentialUrls);
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

  void _onWorkChanged() {
    if (!mounted) return;

    if (!_workSettingsInitialized && !_workController.isLoading) {
      _workSettingsInitialized = true;
      _applySchedules(_workController.schedules);
    }

    setState(() {});

    if (_workController.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_workController.error!)));
      _workController.clearError();
    }

    if (_workController.saved) {
      _workController.clearSaved();
    }
  }

  void _applySchedules(List<AvailabilityScheduleModel> schedules) {
    _daySlots.clear();
    _enabledDays.clear();
    for (final s in schedules) {
      _enabledDays.add(s.dayOfWeek);
      _daySlots.putIfAbsent(s.dayOfWeek, () => []);
      _daySlots[s.dayOfWeek]!.add(_TimeSlot(s.startTime, s.endTime));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _workController.removeListener(_onWorkChanged);
    if (_ownsController) _controller.dispose();
    _workController.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _nifCtrl.dispose();
    _bioCtrl.dispose();
    _radiusCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
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
      serviceRadiusKm: _radiusSlider.round(),
      credentialUrls: _credentialUrls,
    );
    await _saveWorkHours();
    final latText = _latCtrl.text.trim();
    final lngText = _lngCtrl.text.trim();
    if (latText.isNotEmpty && lngText.isNotEmpty) {
      await _saveLocation();
    }
  }

  Future<void> _saveWorkHours() async {
    final proId = '';
    final schedules = <AvailabilityScheduleModel>[];
    for (final day in _enabledDays) {
      for (final slot in _daySlots[day] ?? []) {
        schedules.add(AvailabilityScheduleModel(
          id: '',
          proId: proId,
          dayOfWeek: day,
          startTime: slot.start,
          endTime: slot.end,
        ));
      }
    }
    await _workController.setWorkHours(schedules);
  }

  Future<void> _saveLocation() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude')),
      );
      return;
    }
    await _workController.setLocation(latitude: lat, longitude: lng);
  }

  void _toggleDay(int day) {
    setState(() {
      if (_enabledDays.contains(day)) {
        _enabledDays.remove(day);
      } else {
        _enabledDays.add(day);
        if (_daySlots[day] == null || _daySlots[day]!.isEmpty) {
          _daySlots[day] = [
            _TimeSlot(const TimeOfDay(hour: 9, minute: 0),
                const TimeOfDay(hour: 17, minute: 0))
          ];
        }
      }
    });
    _markDirty();
  }

  void _addSlot(int day) {
    setState(() {
      _daySlots.putIfAbsent(day, () => []);
      _daySlots[day]!.add(_TimeSlot(const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 17, minute: 0)));
    });
    _markDirty();
  }

  void _removeSlot(int day, int index) {
    setState(() {
      _daySlots[day]?.removeAt(index);
      if (_daySlots[day]?.isEmpty == true) _enabledDays.remove(day);
    });
    _markDirty();
  }

  Future<void> _pickTime(int day, int slotIndex, bool isStart) async {
    final slot = _daySlots[day]![slotIndex];
    final picked = await showTimePicker(
        context: context, initialTime: isStart ? slot.start : slot.end);
    if (picked == null) return;
    setState(() {
      _daySlots[day]![slotIndex] =
          isStart ? _TimeSlot(picked, slot.end) : _TimeSlot(slot.start, picked);
    });
    _markDirty();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, maxWidth: 800, imageQuality: 85);
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
                      borderRadius: BorderRadius.circular(2)),
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
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                              _buildSectionLabel('Service radius'),
                              const SizedBox(height: 10),
                              _buildRadiusSlider(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Work hours'),
                              const SizedBox(height: 10),
                              _buildWorkHoursSection(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Base location'),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates of your service area centre',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: FieldifyColors.ink3),
                              ),
                              const SizedBox(height: 10),
                              _buildLocationSection(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Credentials'),
                              const SizedBox(height: 10),
                              _buildCredentialsField(),
                              const SizedBox(height: 20),
                              _buildSectionLabel('Bio'),
                              const SizedBox(height: 10),
                              _buildBioField(),
                              const SizedBox(height: 28),
                              _controller.isSaving || _workController.isSaving
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
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18)),
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
                          errorBuilder: (ctx, e, s) =>
                              _AvatarInitials(initials),
                        )
                      : _AvatarInitials(initials),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              key: const Key('proProfileAvatarEditButton'),
              onTap: _controller.isUploadingAvatar
                  ? null
                  : _showPhotoSourceSheet,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FieldifyColors.g700,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: FieldifyColors.surface, width: 2),
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
            color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
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
                    ? _LockedField(
                        value: _controller.profile?.firstName ?? '')
                    : TextFormField(
                        key: const Key('proProfileFirstNameField'),
                        controller: _firstCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(hint: 'Bruno'),
                        validator: (v) =>
                            _validateRequired(v, 'First name'),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Last name',
                child: isApproved
                    ? _LockedField(
                        value: _controller.profile?.lastName ?? '')
                    : TextFormField(
                        key: const Key('proProfileLastNameField'),
                        controller: _lastCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: FieldifyColors.ink),
                        decoration: authInputDecoration(hint: 'Silva'),
                        validator: (v) =>
                            _validateRequired(v, 'Last name'),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
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

  Widget _buildRadiusSlider() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FieldifyColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Radius',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: FieldifyColors.ink2)),
              SizedBox(
                width: 72,
                child: TextFormField(
                  key: const Key('proProfileRadiusField'),
                  controller: _radiusCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FieldifyColors.g700,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'km',
                    suffixStyle: GoogleFonts.dmSans(
                        fontSize: 12, color: FieldifyColors.g700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: FieldifyColors.g100,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 5 && parsed <= 150) {
                      setState(() => _radiusSlider = parsed.toDouble());
                      _markDirty();
                    }
                  },
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FieldifyColors.g700,
              thumbColor: FieldifyColors.g800,
              inactiveTrackColor: FieldifyColors.g100,
              overlayColor: FieldifyColors.g700.withAlpha(30),
              trackHeight: 4,
            ),
            child: Slider(
              key: const Key('proProfileRadiusSlider'),
              value: _radiusSlider,
              min: 5,
              max: 150,
              divisions: 29,
              onChanged: (v) {
                setState(() {
                  _radiusSlider = v;
                  _radiusCtrl.text = v.round().toString();
                });
                _markDirty();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 km',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: FieldifyColors.ink4)),
              Text('150 km',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: FieldifyColors.ink4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHoursSection() {
    final slots = _daySlots[_selectedDay] ?? [];
    final enabled = _enabledDays.contains(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('workHoursCalendarGrid'),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FieldifyColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 7-day calendar grid row
              Row(
                children: [
                  for (int day = 0; day < 7; day++)
                    Expanded(
                      child: GestureDetector(
                        key: Key('proProfileDay_$day'),
                        onTap: () => setState(() => _selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedDay == day
                                ? FieldifyColors.g800
                                : _enabledDays.contains(day)
                                    ? FieldifyColors.g100
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _dayLabels[day][0],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedDay == day
                                      ? Colors.white
                                      : _enabledDays.contains(day)
                                          ? FieldifyColors.g800
                                          : FieldifyColors.ink4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _enabledDays.contains(day)
                                      ? (_selectedDay == day
                                          ? Colors.white
                                          : FieldifyColors.g700)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0x14000000)),
              const SizedBox(height: 12),
              // Selected day editor
              Row(
                children: [
                  Text(
                    _dayLabels[_selectedDay],
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FieldifyColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    key: Key('proProfileDaySwitch_$_selectedDay'),
                    value: enabled,
                    onChanged: (_) => _toggleDay(_selectedDay),
                    activeThumbColor: FieldifyColors.g700,
                    activeTrackColor: FieldifyColors.g200,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 8),
                for (int i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _TimeChip(
                          label: slots[i].start.format(context),
                          onTap: () => _pickTime(_selectedDay, i, true),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('–',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: FieldifyColors.ink3)),
                        ),
                        _TimeChip(
                          label: slots[i].end.format(context),
                          onTap: () => _pickTime(_selectedDay, i, false),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _removeSlot(_selectedDay, i),
                          child: const Icon(Icons.remove_circle_outline,
                              size: 18, color: FieldifyColors.ink4),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: () => _addSlot(_selectedDay),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: FieldifyColors.g700),
                      const SizedBox(width: 4),
                      Text('Add slot',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: FieldifyColors.g700,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Off — enable the switch to set hours',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: FieldifyColors.ink4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Row(
      children: [
        Expanded(
          child: _LabeledField(
            label: 'Latitude',
            child: TextFormField(
              key: const Key('proProfileLatField'),
              controller: _latCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^-?\d{0,3}\.?\d*'))
              ],
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: FieldifyColors.ink),
              decoration: authInputDecoration(hint: '41.157944'),
              onChanged: (_) => _markDirty(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LabeledField(
            label: 'Longitude',
            child: TextFormField(
              key: const Key('proProfileLngField'),
              controller: _lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^-?\d{0,3}\.?\d*'))
              ],
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: FieldifyColors.ink),
              decoration: authInputDecoration(hint: '-8.629105'),
              onChanged: (_) => _markDirty(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsField() {
    final isApproved = _controller.profile?.isApproved ?? false;

    if (isApproved) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FieldifyColors.border),
        ),
        child: _credentialUrls.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                child: Text('—',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, color: FieldifyColors.ink3)),
              )
            : Column(
                children: [
                  for (int i = 0; i < _credentialUrls.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0x14000000)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 16, color: FieldifyColors.ink3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_credentialUrls[i],
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: FieldifyColors.ink3),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FieldifyColors.g100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Cannot change',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: FieldifyColors.g700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      );
    }

    return Column(
      children: [
        if (_credentialUrls.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FieldifyColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _credentialUrls.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0x14000000)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined,
                            size: 16, color: FieldifyColors.ink3),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_credentialUrls[i],
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: FieldifyColors.ink),
                              overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          key: Key('proProfileRemoveCredential_$i'),
                          icon: const Icon(Icons.close,
                              size: 16, color: FieldifyColors.ink3),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _credentialUrls.removeAt(i);
                              _dirty = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        _AddCredentialRow(
          onAdd: (url) {
            setState(() {
              _credentialUrls.add(url);
              _dirty = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      key: const Key('proProfileBioField'),
      controller: _bioCtrl,
      maxLines: 5,
      maxLength: 500,
      onChanged: (_) => _markDirty(),
      style: GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
      decoration: authInputDecoration(
        hint: 'Tell clients a bit about yourself…',
      ).copyWith(
        alignLabelWithHint: true,
        counterStyle: GoogleFonts.dmSans(
            fontSize: 11, color: FieldifyColors.ink3),
      ),
    );
  }

}

// ── Local state ────────────────────────────────────────────────────────────────

class _TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  const _TimeSlot(this.start, this.end);
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AvatarInitials extends StatelessWidget {
  final String initials;
  const _AvatarInitials(this.initials);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(initials,
          style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.g100)),
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
      children: [FieldLabel(label), const SizedBox(height: 6), child],
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
            child: Text(value.isEmpty ? '—' : value,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: FieldifyColors.ink3)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: FieldifyColors.g100,
                borderRadius: BorderRadius.circular(6)),
            child: Text('Cannot change',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.g700)),
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

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: FieldifyColors.g100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldifyColors.g200),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.g800)),
      ),
    );
  }
}

class _AddCredentialRow extends StatefulWidget {
  final void Function(String url) onAdd;
  const _AddCredentialRow({required this.onAdd});

  @override
  State<_AddCredentialRow> createState() => _AddCredentialRowState();
}

class _AddCredentialRowState extends State<_AddCredentialRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    widget.onAdd(url);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('proProfileAddCredentialField'),
            controller: _ctrl,
            keyboardType: TextInputType.url,
            style:
                GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink),
            decoration: authInputDecoration(hint: 'Credential URL…'),
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          key: const Key('proProfileAddCredentialButton'),
          onTap: _submit,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FieldifyColors.g800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: FieldifyColors.g100, size: 20),
          ),
        ),
      ],
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
