import 'package:banksync_app/core/widgets/uff_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the registration-form alignment bug: showing a `مطلوب`
/// validator message under one field must NOT change that field's height, so a
/// neighbouring field in the same [Row] stays vertically aligned.
///
/// The fix lives in the shared [uffInputDecoration] (`reserveErrorSpace`), so
/// these tests exercise it directly rather than the whole screen.
void main() {
  const fieldAKey = Key('field-a');
  const fieldBKey = Key('field-b');

  Widget harness({required bool reserveErrorSpace, required GlobalKey<FormState> formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: fieldAKey,
                    decoration: uffInputDecoration(
                      context,
                      label: 'A',
                      reserveErrorSpace: reserveErrorSpace,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: fieldBKey,
                    decoration: uffInputDecoration(
                      context,
                      label: 'B',
                      reserveErrorSpace: reserveErrorSpace,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'reserveErrorSpace keeps the field height constant and the two fields aligned',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(harness(reserveErrorSpace: true, formKey: formKey));

    final heightABefore = tester.getSize(find.byKey(fieldAKey)).height;
    final heightBBefore = tester.getSize(find.byKey(fieldBKey)).height;
    // Both fields start at the same top and same height (reserved slot present).
    expect(heightABefore, heightBBefore);
    expect(tester.getTopLeft(find.byKey(fieldAKey)).dy,
        tester.getTopLeft(find.byKey(fieldBKey)).dy);

    // Trigger validation — field A now shows "مطلوب".
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('مطلوب'), findsOneWidget);

    final heightAAfter = tester.getSize(find.byKey(fieldAKey)).height;
    final heightBAfter = tester.getSize(find.byKey(fieldBKey)).height;

    // The errored field did not grow, and the neighbour still matches it.
    expect(heightAAfter, heightABefore);
    expect(heightAAfter, heightBAfter);
    expect(tester.getTopLeft(find.byKey(fieldAKey)).dy,
        tester.getTopLeft(find.byKey(fieldBKey)).dy);
  });

  testWidgets(
      'without reserveErrorSpace the errored field grows (documents the original bug)',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(harness(reserveErrorSpace: false, formKey: formKey));

    final heightBefore = tester.getSize(find.byKey(fieldAKey)).height;
    formKey.currentState!.validate();
    await tester.pump();
    final heightAfter = tester.getSize(find.byKey(fieldAKey)).height;

    // The error text inflates the field height — the root cause of the
    // misalignment the shared fix removes.
    expect(heightAfter, greaterThan(heightBefore));
  });
}
