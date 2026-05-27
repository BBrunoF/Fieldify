import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/utils/date_format_utils.dart';
import '../../../../../shared/widgets/fieldify_painters.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../../../shared/payments/data/models/payment_models.dart';
import '../../../../shared/payments/data/repositories/payment_repository.dart';
import '../../../../shared/payments/presentation/screens/payment_methods_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/location/location_constants.dart';
import '../../../../shared/location/data/location_service.dart';
import '../../../../shared/location/models/picked_location.dart';
import '../../../../shared/location/presentation/location_picker_screen.dart';
import '../../../../shared/location/presentation/static_map_view.dart';
import '../../controllers/request_controller.dart';
import '../../data/models/trade_model.dart';
import '../trade_icon_mapper.dart';

const _stepLabels = ['Category', 'Details', 'Location', 'Confirm'];
const _btnLabels = ['Continue', 'Continue', 'Continue', 'Submit request'];

// ── Screen ────────────────────────────────────────────────────────────────────

class RequestScreen extends StatefulWidget {
  final RequestController? controller;
  final int? initialTradeId;

  const RequestScreen({super.key, this.controller, this.initialTradeId});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  int _step = 1;
  int _cat = 0;
  bool _scheduled = false;
  final List<File> _photos = [];
  final _picker = ImagePicker();
  static const _maxPhotos = 3;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final LocationService _locationService = GeolocatorLocationService();
  LatLng _pickedLatLng = kDefaultLocation;
  late final RequestController _requestCtrl;
  late final bool _ownsController;

  final _paymentRepo = PaymentRepository.resolve();
  SavedCard? _defaultCard;
  bool _loadingCard = true;

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _requestCtrl = widget.controller ?? RequestController();
    _ownsController = widget.controller == null;
    _requestCtrl.addListener(_onRequestChanged);
    _requestCtrl.loadTrades();
    _loadDefaultCard();
  }

  Future<void> _loadDefaultCard() async {
    try {
      final cards = await _paymentRepo.fetchCards();
      if (!mounted) return;
      setState(() {
        _defaultCard = cards.isEmpty
            ? null
            : cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
        _loadingCard = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCard = false);
    }
  }

  Future<void> _openPaymentMethods() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
    setState(() => _loadingCard = true);
    await _loadDefaultCard();
  }

  bool _appliedInitialTrade = false;

  void _onRequestChanged() {
    setState(() {
      if (_requestCtrl.isSubmitted) _step = 5;

      // Deep-link: once trades load, preselect the requested trade and skip the
      // Category step straight to Details. Applied once; back still works.
      if (!_appliedInitialTrade &&
          widget.initialTradeId != null &&
          _requestCtrl.trades.isNotEmpty) {
        final idx = _requestCtrl.trades
            .indexWhere((t) => t.id == widget.initialTradeId);
        if (idx >= 0) {
          _cat = idx;
          _step = 2;
        }
        _appliedInitialTrade = true;
      }
    });
  }

  @override
  void dispose() {
    _requestCtrl.removeListener(_onRequestChanged);
    if (_ownsController) {
      _requestCtrl.dispose();
    }
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _submitRequest();
    }
  }

  Future<void> _submitRequest() async {
    DateTime? scheduledAt;
    if (_scheduled) {
      scheduledAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ).toUtc();
    }

    final trades = _requestCtrl.trades;
    if (_cat >= trades.length) return;
    await _requestCtrl.submit(
      tradeId: trades[_cat].id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      addressText: _addressCtrl.text.trim(),
      latitude: _pickedLatLng.latitude,
      longitude: _pickedLatLng.longitude,
      scheduledAt: scheduledAt,
      photos: _photos,
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          locationService: _locationService,
          initial: _pickedLatLng,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _pickedLatLng = LatLng(result.lat, result.lng);
      if (result.address.isNotEmpty) _addressCtrl.text = result.address;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
  if (_photos.length >= _maxPhotos) return;
  final picked = await _picker.pickImage(
    source: source,
    maxWidth: 2000,
    imageQuality: 80,
  );
  if (picked == null) return;
  setState(() => _photos.add(File(picked.path)));
}

void _removePhoto(int i) => setState(() => _photos.removeAt(i));

Future<void> _showPhotoSourceSheet() async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source != null) await _pickPhoto(source);
}

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: FieldifyColors.g800,
        statusBarIconBrightness: Brightness.light,
      ),
      child: _step == 5 ? _buildSubmitted() : _buildForm(),
    );
  }

  // ── Multi-step form layout ────────────────────────────────────────────────

  Widget _buildForm() {
    return Scaffold(
      key: const Key('requestFormScreen'),
      backgroundColor: FieldifyColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopChrome(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: _buildStep(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top chrome: back btn + title + progress ───────────────────────────────

  Widget _buildTopChrome() {
    final pct = _step / 4;
    return Container(
      color: FieldifyColors.g800,
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              children: [
                GestureDetector(
                  key: const Key('requestBackButton'),
                  onTap: _back,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(51),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: FieldifyColors.g100,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'New request',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$_step / 4',
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: FieldifyColors.g200,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar + labels
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withAlpha(38),
                    valueColor: const AlwaysStoppedAnimation(
                      FieldifyColors.g200,
                    ),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_stepLabels.length, (i) {
                    final isDone = _step > i + 1;
                    final isActive = _step == i + 1;
                    final color = isActive
                        ? FieldifyColors.g200
                        : isDone
                        ? Colors.white.withAlpha(128)
                        : Colors.white.withAlpha(89);
                    return Text(
                      _stepLabels[i],
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Curved transition
          SizedBox(
            height: 18,
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

  // ── Bottom action bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: _requestCtrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_requestCtrl.error != null) ...[
                  Text(
                    _requestCtrl.error!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFFC0392B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton(
                  key: const Key('requestPrimaryButton'),
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: FieldifyColors.g100,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _btnLabels[_step - 1],
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.g100,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Step router ──────────────────────────────────────────────────────────

  Widget _buildStep() {
    return switch (_step) {
      1 => _buildStep1(),
      2 => _buildStep2(),
      3 => _buildStep3(),
      _ => _buildStep4(),
    };
  }

  // ── Step 1: Category ─────────────────────────────────────────────────────

  Widget _buildStep1() {
    final trades = _requestCtrl.trades;
    Widget body;
    if (_requestCtrl.isLoadingTrades && trades.isEmpty) {
      body = const Padding(
        key: Key('requestCategoriesLoading'),
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_requestCtrl.tradesError != null && trades.isEmpty) {
      body = Padding(
        key: const Key('requestCategoriesError'),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            _requestCtrl.tradesError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFFC0392B),
            ),
          ),
        ),
      );
    } else {
      body = GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: List.generate(trades.length, (i) {
          final c = trades[i];
          final selected = _cat == i;
            return GestureDetector(
              key: Key('requestCategoryCard_$i'),
              onTap: () => setState(() => _cat = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? FieldifyColors.g100 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? FieldifyColors.g800
                        : const Color(0x21000000),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? FieldifyColors.g800
                                : FieldifyColors.g100,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(22, 22),
                              painter: ServiceIconPainter(
                                icon: iconForTrade(c.slug),
                                color: selected
                                    ? FieldifyColors.g100
                                    : FieldifyColors.g800,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: selected
                                ? FieldifyColors.g800
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: selected
                                ? null
                                : Border.all(
                                    color: const Color(0x21000000),
                                    width: 1.5,
                                  ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: FieldifyColors.g100,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      c.displayName,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: FieldifyColors.g100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '€${c.standardRate} / h',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.g800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          'What do you need?',
          'Pick a category — the rate is set per service.',
        ),
        body,
      ],
    );
  }

  // ── Step 2: Details ──────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          'Describe the job',
          'Help the professional understand what\'s needed before they arrive.',
        ),
        _FormField(
          label: 'Title',
          child: TextFormField(
            key: const Key('requestTitleField'),
            controller: _titleCtrl,
            style: _inputTextStyle,
            decoration: authInputDecoration(
              hint: 'e.g. Leaking pipe under sink',
            ),
          ),
        ),
        _FormField(
          label: 'Description',
          child: TextFormField(
            key: const Key('requestDescriptionField'),
            controller: _descCtrl,
            maxLines: 4,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'What exactly is the issue?'),
          ),
        ),
        _FormField(
          label: 'Photos',
          labelSuffix: ' — optional (max $_maxPhotos)',
          child: Column(
            key: const Key('requestPhotosSection'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _photos[i],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            key: Key('requestPhotoRemove_$i'),
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_photos.isNotEmpty) const SizedBox(height: 10),
              if (_photos.length < _maxPhotos)
                GestureDetector(
                  key: const Key('requestAddPhotoButton'),
                  onTap: _showPhotoSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x21000000),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: FieldifyColors.g100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 20,
                            color: FieldifyColors.g800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _photos.isEmpty ? 'Add photos' : 'Add another',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: FieldifyColors.ink2,
                              ),
                            ),
                            Text(
                              '${_photos.length} / $_maxPhotos · JPEG/PNG/WebP',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: FieldifyColors.ink4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Location & time ──────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          'Where is the job?',
          'We\'ll match you with professionals nearby.',
        ),
        GestureDetector(
          key: const Key('requestMapPreview'),
          onTap: _openLocationPicker,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: StaticMapView(position: _pickedLatLng, height: 120),
          ),
        ),
        const SizedBox(height: 14),
        _FormField(
          label: 'Address',
          child: TextFormField(
            key: const Key('requestAddressField'),
            controller: _addressCtrl,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'Street and number'),
          ),
        ),
        _FormField(
          label: 'Floor / apartment',
          labelSuffix: ' (optional)',
          child: TextFormField(
            key: const Key('requestFloorField'),
            controller: _floorCtrl,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'e.g. 3rd floor, apt 12'),
          ),
        ),
        _FormField(
          label: 'When?',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x21000000)),
                ),
                child: Row(
                  children: [
                    _TimeOpt(
                      'As soon as possible',
                      !_scheduled,
                      () => setState(() => _scheduled = false),
                      key: const Key('requestAsapOption'),
                    ),
                    _TimeOpt(
                      'Schedule',
                      _scheduled,
                      () => setState(() => _scheduled = true),
                      key: const Key('requestScheduleOption'),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _scheduled
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Date'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              key: const Key('requestDateButton'),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 90),
                                  ),
                                );
                                if (d != null) setState(() => _date = d);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x21000000),
                                  ),
                                ),
                                child: Text(
                                  formatDateYmd(_date),
                                  style: _inputTextStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Time'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              key: const Key('requestTimeButton'),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _time,
                                );
                                if (t != null) setState(() => _time = t);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x21000000),
                                  ),
                                ),
                                child: Text(
                                  _time.format(context),
                                  style: _inputTextStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Confirm ──────────────────────────────────────────────────────

  Widget _buildStep4() {
    final trades = _requestCtrl.trades;
    final Trade? cat = (_cat < trades.length) ? trades[_cat] : null;
    final whenText = _scheduled
        ? '${_date.day}/${_date.month}/${_date.year} at ${_time.format(context)}'
        : 'As soon as possible';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          'Review & submit',
          'Your card won\'t be charged until the professional is on their way.',
        ),
        _ConfirmCard(
          heading: 'Job details',
          rows: [
            ('Category', cat?.displayName ?? '—', null),
            ('Title', _titleCtrl.text, null),
            ('Address', _addressCtrl.text, null),
            ('When', whenText, FieldifyColors.g700),
          ],
        ),
        const SizedBox(height: 12),
        _buildPaymentCard(),
        const SizedBox(height: 12),
        _buildPriceBreak(cat?.standardRate ?? 0),
        const SizedBox(height: 12),
        _Notice(
          type: _NoticeType.warn,
          text:
              'Cancellations after the professional marks "On my way" will incur a cancellation fee.',
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: FieldifyColors.g800,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.credit_card_outlined,
                  color: FieldifyColors.g100,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _defaultCard == null
                            ? 'Tap to add a card'
                            : 'Saved to your account',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: FieldifyColors.g200,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  key: const Key('requestPaymentManageButton'),
                  onTap: _openPaymentMethods,
                  child: Text(
                    _defaultCard == null ? 'Add' : 'Change',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.g100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _defaultCard == null ? _openPaymentMethods : null,
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF173404),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _loadingCard
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(FieldifyColors.g200),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading your card…',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: FieldifyColors.g200),
                        ),
                      ],
                    )
                  : _defaultCard == null
                      ? Row(
                          children: [
                            const Icon(Icons.add_card_outlined,
                                size: 20, color: FieldifyColors.g200),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No card saved — add one to pay for jobs',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, color: FieldifyColors.g200),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 28,
                              height: 20,
                              decoration: BoxDecoration(
                                color: FieldifyColors.g200.withAlpha(179),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _defaultCard!.masked,
                                style: GoogleFonts.dmMono(
                                  fontSize: 13,
                                  color: FieldifyColors.g200,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                            Text(
                              _defaultCard!.brandLabel.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: FieldifyColors.g200.withAlpha(153),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: FieldifyColors.ink3,
                  height: 1.6,
                ),
                children: const [
                  TextSpan(text: 'Your card will be '),
                  TextSpan(
                    text: 'authorised but not charged',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' when the professional marks "On my way". The final charge is calculated from actual time worked.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreak(int rate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: Column(
        children: [
          _PriceRow('Rate', '€$rate / h'),
          _PriceRow('Platform fee', '${Trade.platformFeePercent}%'),
          const Divider(height: 1, color: Color(0x14000000)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(
              'You are charged for actual time worked — from when the professional marks In progress to Complete. No estimate needed.',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: FieldifyColors.ink3,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Submitted ────────────────────────────────────────────────────

  Widget _buildSubmitted() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      key: const Key('requestSubmittedScreen'),
      backgroundColor: FieldifyColors.surface,
      body: Column(
        children: [
          Container(
            color: FieldifyColors.g800,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: FieldifyColors.g100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: FieldifyColors.g800,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Request submitted',
                      key: const Key('requestSubmittedTitle'),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professionals nearby are being notified.\nFirst to accept gets the job.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: FieldifyColors.g200,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Timeline(),
                  const SizedBox(height: 4),
                  const _Notice(
                    type: _NoticeType.info,
                    text:
                        'If no professional accepts within 30 minutes, your request expires and no charge is made.',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0x14000000))),
            ),
            child: Column(
              children: [
                ElevatedButton(
                  key: const Key('trackJobButton'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: FieldifyColors.g100,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Track job',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.g100,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('backToHomeButton'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: Color(0x21000000)),
                  ),
                  child: Text(
                    'Back to home',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable small widgets ────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String title, sub;
  const _StepTitle(this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: FieldifyColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: FieldifyColors.ink3,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: FieldifyColors.ink3,
        letterSpacing: 0.44,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String? labelSuffix;
  final Widget child;
  const _FormField({
    required this.label,
    this.labelSuffix,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelSuffix == null)
            _FieldLabel(label)
          else
            Row(
              children: [
                _FieldLabel(label),
                Text(
                  labelSuffix!,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: FieldifyColors.ink4,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _TimeOpt extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TimeOpt(this.label, this.active, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? FieldifyColors.g800 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? FieldifyColors.g100 : FieldifyColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final String heading;
  final List<(String, String, Color?)> rows;
  const _ConfirmCard({required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: FieldifyColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0x14000000))),
            ),
            child: Text(
              heading.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0x14000000)))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: FieldifyColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: rows[i].$3 ?? FieldifyColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3),
          ),
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

enum _NoticeType { info, warn }

class _Notice extends StatelessWidget {
  final _NoticeType type;
  final String text;
  const _Notice({required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final isInfo = type == _NoticeType.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isInfo ? FieldifyColors.g100 : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isInfo ? Icons.info_outline : Icons.warning_amber_rounded,
            size: 16,
            color: isInfo ? FieldifyColors.g800 : const Color(0xFF854F0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isInfo ? FieldifyColors.g800 : const Color(0xFF854F0B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline (step 5) ─────────────────────────────────────────────────────────

enum _DotState { done, active, pending }

class _TimelineItem {
  final String label, sub;
  final _DotState dot;
  final bool hasLine;
  const _TimelineItem(this.label, this.sub, this.dot, {this.hasLine = true});
}

const _timelineItems = [
  _TimelineItem(
    'Request posted',
    'Nearby professionals are being notified now.',
    _DotState.done,
  ),
  _TimelineItem(
    'Professional accepts',
    'You\'ll get a push notification with their name and ETA.',
    _DotState.active,
  ),
  _TimelineItem(
    'On the way',
    'Your card is authorised at this point. If it fails, the job is cancelled automatically.',
    _DotState.pending,
  ),
  _TimelineItem(
    'In progress',
    'Timer starts. You\'ll see the live duration in the app.',
    _DotState.pending,
  ),
  _TimelineItem(
    'Complete & payment',
    'Charged for actual time worked × €35/h. Funds released to professional after 24h.',
    _DotState.pending,
    hasLine: false,
  ),
];

class _Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: _timelineItems.map((item) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  _buildDot(item.dot),
                  if (item.hasLine)
                    Container(
                      width: 2,
                      height: 36,
                      color: item.dot == _DotState.done
                          ? FieldifyColors.g800
                          : const Color(0x21000000),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: item.dot == _DotState.pending
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: item.dot == _DotState.pending
                            ? FieldifyColors.ink4
                            : FieldifyColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sub,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: item.dot == _DotState.pending
                            ? FieldifyColors.ink4
                            : FieldifyColors.ink3,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDot(_DotState state) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          _DotState.done => FieldifyColors.g800,
          _DotState.active => FieldifyColors.g100,
          _DotState.pending => Colors.white,
        },
        border: switch (state) {
          _DotState.done => null,
          _DotState.active => Border.all(color: FieldifyColors.g800, width: 2),
          _DotState.pending => Border.all(
            color: const Color(0x21000000),
            width: 2,
          ),
        },
      ),
      child: switch (state) {
        _DotState.done => const Icon(
          Icons.check,
          size: 12,
          color: FieldifyColors.g100,
        ),
        _DotState.active => Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: FieldifyColors.g800,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _DotState.pending => null,
      },
    );
  }
}

// ── Shared text style ─────────────────────────────────────────────────────────

final _inputTextStyle = GoogleFonts.dmSans(
  fontSize: 15,
  color: FieldifyColors.ink,
);
