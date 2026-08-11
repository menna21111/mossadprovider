import 'package:flutter/material.dart';

import '../../services/presentation/add_address_screen.dart';

class LocationSetupScreen extends StatelessWidget {
  const LocationSetupScreen({super.key, this.canSkip = false});

  final bool canSkip;

  @override
  Widget build(BuildContext context) {
    return AddAddressScreen(canSkip: canSkip);
  }
}
