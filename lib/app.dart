import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/omarchy_theme.dart';
import 'ui/clipboard_overlay_page.dart';

class ClipmApp extends StatelessWidget {
  const ClipmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: OmarchyTheme.build(),
      home: const ClipboardOverlayPage(),
    );
  }
}
