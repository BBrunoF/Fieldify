import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_shared.dart';
import '../../shared/fieldify_painters.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _Cat {
  final String name, desc;
  final int rate;
  final ServiceIconType icon;
  const _Cat(this.name, this.desc, this.rate, this.icon);
}

const _cats = [
  _Cat('Plumbing',   'Leaks, pipes, drains',       35, ServiceIconType.plumbing),
  _Cat('Electrical', 'Wiring, outlets, fuses',      40, ServiceIconType.electrical),
  _Cat('Carpentry',  'Furniture, doors, floors',    35, ServiceIconType.carpentry),
  _Cat('HVAC',       'AC, heating, ventilation',    45, ServiceIconType.hvac),
  _Cat('Painting',   'Interior, exterior',          30, ServiceIconType.painting),
  _Cat('Other',      'Anything else',               35, ServiceIconType.other),
];

// trade_id matches seed order in public.trades
const _tradeIds = [1, 2, 3, 4, 5, 6];

const _stepLabels   = ['Category', 'Details', 'Location', 'Confirm'];
const _btnLabels    = ['Continue', 'Continue', 'Continue', 'Submit request'];

// ── Screen ────────────────────────────────────────────────────────────────────

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  int _step = 1;
  int _cat  = 0;
  bool _scheduled = false;
  bool _loading = false;
  String? _error;

  final _titleCtrl   = TextEditingController(text: 'Leaking pipe under kitchen sink');
  final _descCtrl    = TextEditingController(text: 'Water dripping from pipe joint for 2 days. Slowly pooling in the cabinet below.');
  final _addressCtrl = TextEditingController(text: 'Rua do Heroísmo 42, Porto');
  final _floorCtrl   = TextEditingController();

  DateTime _date = DateTime(2025, 4, 18);
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
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
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;

      // Build scheduled_at if user picked a specific time
      DateTime? scheduledAt;
      if (_scheduled) {
        scheduledAt = DateTime(
          _date.year, _date.month, _date.day,
          _time.hour, _time.minute,
        ).toUtc();
      }

      // Hardcoded Porto coords until Google Maps geocoding is wired up
      const lat = 41.1579;
      const lng = -8.6291;

      await Supabase.instance.client.from('service_requests').insert({
        'client_id':    user.id,
        'trade_id':     _tradeIds[_cat],
        'title':        _titleCtrl.text.trim(),
        'description':  _descCtrl.text.trim(),
        'address_text': _addressCtrl.text.trim(),
        'location':     'POINT($lng $lat)',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'photo_urls':   [],
      });

      if (mounted) setState(() => _step = 5);
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  onTap: _back,
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
                Expanded(
                  child: Text(
                    'New request',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
                Text(
                  '$_step / 4',
                  style: GoogleFonts.dmMono(
                      fontSize: 12, color: FieldifyColors.g200),
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
                    valueColor: const AlwaysStoppedAnimation(FieldifyColors.g200),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_stepLabels.length, (i) {
                    final isDone   = _step > i + 1;
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
                          color: color),
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
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: const Color(0xFFC0392B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: FieldifyColors.g100,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _btnLabels[_step - 1],
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g100),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('What do you need?',
            'Pick a category — the rate is set per service.'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: List.generate(_cats.length, (i) {
            final c = _cats[i];
            final selected = _cat == i;
            return GestureDetector(
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
                                icon: c.icon,
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
                                    width: 1.5),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 10, color: FieldifyColors.g100)
                              : null,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(c.name,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: FieldifyColors.ink)),
                    const SizedBox(height: 2),
                    Text(c.desc,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: FieldifyColors.ink3,
                            height: 1.4)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FieldifyColors.g100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '€${c.rate} / h',
                        style: GoogleFonts.dmMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FieldifyColors.g800),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Step 2: Details ──────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Describe the job',
            'Help the professional understand what\'s needed before they arrive.'),
        _FormField(
          label: 'Title',
          child: TextFormField(
            controller: _titleCtrl,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'e.g. Leaking pipe under sink'),
          ),
        ),
        _FormField(
          label: 'Description',
          child: TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'What exactly is the issue?'),
          ),
        ),
        _FormField(
          label: 'Photos',
          labelSuffix: ' — optional',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0x21000000),
                  style: BorderStyle.solid,
                  width: 1.5),
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
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 20, color: FieldifyColors.g800),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add photos',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: FieldifyColors.ink2)),
                    Text('JPEG or PNG · max 10MB each',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: FieldifyColors.ink4)),
                  ],
                ),
              ],
            ),
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
        _StepTitle('Where is the job?',
            'We\'ll match you with professionals nearby.'),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: MapPainter(vw: 350, vh: 120),
                  ),
                ),
                const Center(child: MapPin(size: 24)),
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FieldifyColors.g200),
                    ),
                    child: Text('Change',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FieldifyColors.g800)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _FormField(
          label: 'Address',
          child: TextFormField(
            controller: _addressCtrl,
            style: _inputTextStyle,
            decoration: authInputDecoration(hint: 'Street and number'),
          ),
        ),
        _FormField(
          label: 'Floor / apartment',
          labelSuffix: ' (optional)',
          child: TextFormField(
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
                    _TimeOpt('As soon as possible', !_scheduled,
                        () => setState(() => _scheduled = false)),
                    _TimeOpt('Schedule', _scheduled,
                        () => setState(() => _scheduled = true)),
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
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 90)),
                                );
                                if (d != null) setState(() => _date = d);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0x21000000)),
                                ),
                                child: Text(
                                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
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
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _time,
                                );
                                if (t != null) setState(() => _time = t);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0x21000000)),
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
    final cat = _cats[_cat];
    final whenText = _scheduled
        ? '${_date.day}/${_date.month}/${_date.year} at ${_time.format(context)}'
        : 'As soon as possible';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Review & submit',
            'Your card won\'t be charged until the professional is on their way.'),
        _ConfirmCard(
          heading: 'Job details',
          rows: [
            ('Category', cat.name, null),
            ('Title', _titleCtrl.text, null),
            ('Address', _addressCtrl.text, null),
            ('When', whenText, FieldifyColors.g700),
          ],
        ),
        const SizedBox(height: 12),
        _buildPaymentCard(),
        const SizedBox(height: 12),
        _buildPriceBreak(cat.rate),
        const SizedBox(height: 12),
        _Notice(
          type: _NoticeType.warn,
          text: 'Cancellations after the professional marks "On my way" will incur a cancellation fee.',
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
                const Icon(Icons.credit_card_outlined,
                    color: FieldifyColors.g100, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment method',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    Text('Saved to your account',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: FieldifyColors.g200)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF173404),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
                  child: Text('•••• •••• •••• 4821',
                      style: GoogleFonts.dmMono(
                          fontSize: 13,
                          color: FieldifyColors.g200,
                          letterSpacing: 1.6)),
                ),
                Text('VISA',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g200.withAlpha(153))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: FieldifyColors.ink3, height: 1.6),
                children: const [
                  TextSpan(text: 'Your card will be '),
                  TextSpan(
                    text: 'authorised but not charged',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.ink2),
                  ),
                  TextSpan(
                      text:
                          ' when the professional marks "On my way". The final charge is calculated from actual time worked.'),
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
          _PriceRow('Platform fee', '10%'),
          const Divider(height: 1, color: Color(0x14000000)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(
              'You are charged for actual time worked — from when the professional marks In progress to Complete. No estimate needed.',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: FieldifyColors.ink3, height: 1.6),
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
                      child: const Icon(Icons.check,
                          color: FieldifyColors.g800, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text('Request submitted',
                        style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'Professionals nearby are being notified.\nFirst to accept gets the job.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: FieldifyColors.g200,
                          height: 1.5),
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
                  Text('What happens next',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.ink2)),
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FieldifyColors.g800,
                    foregroundColor: FieldifyColors.g100,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Track job',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.g100)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0x21000000)),
                  ),
                  child: Text('Back to home',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FieldifyColors.ink3)),
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
        Text(title,
            style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink,
                letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(sub,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: FieldifyColors.ink3, height: 1.5)),
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
          letterSpacing: 0.44),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String? labelSuffix;
  final Widget child;
  const _FormField({required this.label, this.labelSuffix, required this.child});

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
                Text(labelSuffix!,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: FieldifyColors.ink4)),
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
  const _TimeOpt(this.label, this.active, this.onTap);

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
                color: active ? FieldifyColors.g100 : FieldifyColors.ink3),
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
            child: Text(heading.toUpperCase(),
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink3,
                    letterSpacing: 0.6)),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: Color(0x14000000)))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: FieldifyColors.ink3)),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(rows[i].$2,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: rows[i].$3 ?? FieldifyColors.ink)),
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
          border: Border(bottom: BorderSide(color: Color(0x14000000)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: FieldifyColors.ink3)),
          Text(value,
              style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.ink)),
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
                  color: isInfo
                      ? FieldifyColors.g800
                      : const Color(0xFF854F0B),
                  height: 1.5),
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
  _TimelineItem('Request posted',
      'Nearby professionals are being notified now.',
      _DotState.done),
  _TimelineItem('Professional accepts',
      'You\'ll get a push notification with their name and ETA.',
      _DotState.active),
  _TimelineItem('On the way',
      'Your card is authorised at this point. If it fails, the job is cancelled automatically.',
      _DotState.pending),
  _TimelineItem('In progress',
      'Timer starts. You\'ll see the live duration in the app.',
      _DotState.pending),
  _TimelineItem('Complete & payment',
      'Charged for actual time worked × €35/h. Funds released to professional after 24h.',
      _DotState.pending,
      hasLine: false),
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
                          height: 1.4),
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
          _DotState.done    => FieldifyColors.g800,
          _DotState.active  => FieldifyColors.g100,
          _DotState.pending => Colors.white,
        },
        border: switch (state) {
          _DotState.done    => null,
          _DotState.active  => Border.all(color: FieldifyColors.g800, width: 2),
          _DotState.pending => Border.all(color: const Color(0x21000000), width: 2),
        },
      ),
      child: switch (state) {
        _DotState.done => const Icon(Icons.check,
            size: 12, color: FieldifyColors.g100),
        _DotState.active => Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: FieldifyColors.g800, shape: BoxShape.circle),
            ),
          ),
        _DotState.pending => null,
      },
    );
  }
}

// ── Shared text style ─────────────────────────────────────────────────────────

final _inputTextStyle =
    GoogleFonts.dmSans(fontSize: 15, color: FieldifyColors.ink);