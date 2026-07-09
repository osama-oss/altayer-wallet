import 'package:flutter/material.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../transfer/add_account_panel.dart';

class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'إضافة حساب جديد'
              : 'Add New Account',
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: AddAccountPanel(),
        ),
      ),
    );
  }
}
