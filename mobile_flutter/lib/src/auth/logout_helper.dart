import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'supabase_auth_provider.dart';

void logout(BuildContext context) async {
  final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
  await auth.logout();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
