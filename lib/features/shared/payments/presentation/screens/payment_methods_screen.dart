import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/payment_methods_controller.dart';
import '../../data/models/payment_models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final PaymentMethodsController? controller;
  const PaymentMethodsScreen({super.key, this.controller});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final PaymentMethodsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? PaymentMethodsController();
    _controller.addListener(_onChange);
    _controller.load();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _addCard() async {
    final added = await _controller.addCard();
    if (!mounted) return;
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card saved')),
      );
    } else if (_controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('paymentMethodsScreen'),
      backgroundColor: FieldifyColors.surface,
      appBar: AppBar(
        backgroundColor: FieldifyColors.surface,
        foregroundColor: FieldifyColors.ink,
        elevation: 0,
        title: Text(
          'Payment methods',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: FieldifyColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _list()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _AddCardButton(
                busy: _controller.isAddingCard,
                onTap: _controller.isAddingCard ? null : _addCard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    if (_controller.isLoading && _controller.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = _controller.cards;
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card_off_outlined,
                  size: 40, color: FieldifyColors.ink3),
              const SizedBox(height: 12),
              Text(
                'No cards saved yet.\nAdd one to pay for jobs.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: FieldifyColors.ink3),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: cards.length,
      itemBuilder: (_, i) => _CardTile(
        card: cards[i],
        onTap: cards[i].isDefault ? null : () => _controller.setDefault(cards[i].id),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final SavedCard card;
  final VoidCallback? onTap;
  const _CardTile({required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: card.isDefault ? FieldifyColors.g800 : FieldifyColors.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, color: FieldifyColors.ink2, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.brandLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink,
                    ),
                  ),
                  Text(
                    card.masked,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      color: FieldifyColors.ink3,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (card.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FieldifyColors.g100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Default',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.g800,
                  ),
                ),
              )
            else
              Text(
                'Set default',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.g700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _AddCardButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('paymentMethodsAddCardButton'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FieldifyColors.g800,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(FieldifyColors.g100),
                ),
              )
            : Text(
                'Add card',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.g100,
                ),
              ),
      ),
    );
  }
}
