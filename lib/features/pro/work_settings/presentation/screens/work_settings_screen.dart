import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/auth/presentation/widgets/auth_shared.dart';
import '../../controllers/work_settings_controller.dart';
import '../../data/models/availability_schedule_model.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class WorkSettingsScreen extends StatefulWidget {
  final WorkSettingsController? controller;

  const WorkSettingsScreen({super.key, this.controller});

  @override
  State<WorkSettingsScreen> createState() => _WorkSettingsScreenState();
}

class _WorkSettingsScreenState extends State<WorkSettingsScreen> {
  late final WorkSettingsController _controller;
  late final bool _ownsController;

  // Work hours state: dayOfWeek → list of (start, end) slots
  final Map<int, List<_TimeSlot>> _daySlots = {};
  final Set<int> _enabledDays = {};
  int _selectedDay = 0;

  // Service radius state
  late double _radius;

  // Location state
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  bool _settingsInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WorkSettingsController();
    _ownsController = widget.controller == null;
    _radius = _controller.radiusKm.toDouble();
    _latCtrl = TextEditingController(
        text: _controller.latitude != null
            ? _controller.latitude!.toStringAsFixed(6)
            : '');
    _lngCtrl = TextEditingController(
        text: _controller.longitude != null
            ? _controller.longitude!.toStringAsFixed(6)
            : '');

    _initFromController();
    _controller.addListener(_onControllerChanged);
  }

  void _initFromController() {
    if (_controller.isLoading) return;
    _applySchedules(_controller.schedules);
    _radius = _controller.radiusKm.toDouble();
    _settingsInitialized = true;
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

  void _onControllerChanged() {
    if (!mounted) return;

    if (!_settingsInitialized && !_controller.isLoading) {
      setState(() {
        _applySchedules(_controller.schedules);
        _radius = _controller.radiusKm.toDouble();
        if (_controller.latitude != null) {
          _latCtrl.text = _controller.latitude!.toStringAsFixed(6);
        }
        if (_controller.longitude != null) {
          _lngCtrl.text = _controller.longitude!.toStringAsFixed(6);
        }
        _settingsInitialized = true;
      });
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
            content: Text('Settings saved'),
            backgroundColor: FieldifyColors.g700,
          ),
        );
      _controller.clearSaved();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
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
  }

  void _addSlot(int day) {
    setState(() {
      _daySlots.putIfAbsent(day, () => []);
      _daySlots[day]!.add(
        _TimeSlot(const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 17, minute: 0)),
      );
    });
  }

  void _removeSlot(int day, int index) {
    setState(() {
      _daySlots[day]?.removeAt(index);
      if (_daySlots[day]?.isEmpty == true) {
        _enabledDays.remove(day);
      }
    });
  }

  Future<void> _pickTime(int day, int slotIndex, bool isStart) async {
    final slot = _daySlots[day]![slotIndex];
    final initial = isStart ? slot.start : slot.end;
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _daySlots[day]![slotIndex] = _TimeSlot(picked, slot.end);
      } else {
        _daySlots[day]![slotIndex] = _TimeSlot(slot.start, picked);
      }
    });
  }

  List<AvailabilityScheduleModel> _buildSchedules() {
    final proId = '';
    final result = <AvailabilityScheduleModel>[];
    for (final day in _enabledDays) {
      final slots = _daySlots[day] ?? [];
      for (int i = 0; i < slots.length; i++) {
        result.add(AvailabilityScheduleModel(
          id: '',
          proId: proId,
          dayOfWeek: day,
          startTime: slots[i].start,
          endTime: slots[i].end,
        ));
      }
    }
    return result;
  }

  Future<void> _saveWorkHours() async {
    await _controller.setWorkHours(_buildSchedules());
  }

  Future<void> _saveRadius() async {
    await _controller.setServiceRadius(_radius.round());
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
    await _controller.setLocation(latitude: lat, longitude: lng);
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
                    : SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Work hours'),
                            const SizedBox(height: 10),
                            _buildWorkHoursSection(),
                            const SizedBox(height: 24),
                            _buildSectionLabel('Service radius'),
                            const SizedBox(height: 10),
                            _buildRadiusSection(),
                            const SizedBox(height: 24),
                            _buildSectionLabel('Base location'),
                            const SizedBox(height: 4),
                            Text(
                              'Coordinates of your service area centre',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: FieldifyColors.ink3),
                            ),
                            const SizedBox(height: 10),
                            _buildLocationSection(),
                          ],
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
                  'Work settings',
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

  Widget _buildWorkHoursSection() {
    final slots = _daySlots[_selectedDay] ?? [];
    final enabled = _enabledDays.contains(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('workSettingsCalendarGrid'),
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
                        key: Key('workSettingsDay_$day'),
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
                    key: Key('workSettingsDaySwitch_$_selectedDay'),
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
        const SizedBox(height: 14),
        _controller.isSaving
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                key: const Key('workSettingsSaveHoursButton'),
                onPressed: _saveWorkHours,
                style: _saveButtonStyle(),
                child: Text('Save work hours',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g100)),
              ),
      ],
    );
  }

  Widget _buildRadiusSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FieldifyColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: FieldifyColors.ink2),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FieldifyColors.g100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_radius.round()} km',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FieldifyColors.g700,
                  ),
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
              key: const Key('workSettingsRadiusSlider'),
              value: _radius,
              min: 5,
              max: 150,
              divisions: 29,
              onChanged: (v) => setState(() => _radius = v),
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
          const SizedBox(height: 8),
          _controller.isSaving
              ? const SizedBox(
                  height: 42,
                  child: Center(child: CircularProgressIndicator()))
              : ElevatedButton(
                  key: const Key('workSettingsSaveRadiusButton'),
                  onPressed: _saveRadius,
                  style: _saveButtonStyle(),
                  child: Text('Save radius',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.g100)),
                ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Latitude',
                child: TextFormField(
                  key: const Key('workSettingsLatField'),
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
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Longitude',
                child: TextFormField(
                  key: const Key('workSettingsLngField'),
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
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _controller.isSaving
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                key: const Key('workSettingsSaveLocationButton'),
                onPressed: _saveLocation,
                style: _saveButtonStyle(),
                child: Text('Save location',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g100)),
              ),
      ],
    );
  }

  ButtonStyle _saveButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: FieldifyColors.g800,
      foregroundColor: FieldifyColors.g100,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    );
  }
}

// ── Local state helpers ────────────────────────────────────────────────────────

class _TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  const _TimeSlot(this.start, this.end);
}

// ── Widgets ───────────────────────────────────────────────────────────────────

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
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FieldifyColors.g800,
          ),
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
