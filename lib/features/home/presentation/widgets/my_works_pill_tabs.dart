import 'package:flutter/material.dart';

import '../../../../core/widgets/mosaed_pill_tabs.dart';

/// Alias kept for existing call sites — same design as mossad task details.
class MyWorksPillTabs extends StatelessWidget {
  const MyWorksPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MosaedPillTabs(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      fontSize: labels.length > 2 ? 11 : 13,
    );
  }
}
