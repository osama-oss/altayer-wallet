import 'package:flutter/material.dart';

import '../kyc_document.dart';
import '../kyc_form_data.dart';
import '../kyc_status.dart';
import 'kyc_capture_view.dart';
import 'kyc_data_form_view.dart';

/// The full account-verification journey for a customer who still needs to
/// verify: step 1 collects the identity + residence details ([KycDataFormView]),
/// step 2 captures and submits the documents ([KycCaptureView]).
///
/// Both steps stay mounted in an [IndexedStack] so returning to edit the form
/// never loses entered text or already-captured photos. The capture view is
/// keyed by the chosen identity type: switching national-ID ↔ passport rebuilds
/// it with the correct document set (and discards captures from the other set).
class KycFlow extends StatefulWidget {
  const KycFlow({
    super.key,
    required this.profile,
    required this.onSubmitted,
  });

  final KycProfile profile;
  final Future<void> Function(KycProfile profile) onSubmitted;

  @override
  State<KycFlow> createState() => _KycFlowState();
}

class _KycFlowState extends State<KycFlow> {
  int _step = 0;
  KycIdType _idType = KycIdType.nationalId;
  KycFormData _data = const KycFormData();

  void _onFormContinue(KycIdType idType, KycFormData data) {
    setState(() {
      _idType = idType;
      _data = data;
      _step = 1;
    });
  }

  void _onBack() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _step,
      sizing: StackFit.expand,
      children: [
        KycDataFormView(
          initialIdType: _idType,
          initialData: _data,
          onContinue: _onFormContinue,
        ),
        KycCaptureView(
          key: ValueKey(_idType),
          profile: widget.profile,
          initialIdType: _idType,
          formData: _data,
          onBack: _onBack,
          onSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}
