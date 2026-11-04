import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'data/models/growth_config.dart';
import 'growth_config_controller.dart';

/// Reads the [GrowthConfigController] without crashing when it is not in the
/// tree (tests, isolated routes). Falls back to the global instance.
GrowthConfigController? growthControllerOf(
  BuildContext context, {
  bool listen = false,
}) {
  try {
    return Provider.of<GrowthConfigController>(context, listen: listen);
  } on ProviderNotFoundException {
    return GrowthConfigController.instance;
  }
}

/// Current growth flags; [GrowthConfig.disabled] when unavailable.
GrowthConfig growthConfigOf(BuildContext context, {bool listen = true}) {
  return growthControllerOf(context, listen: listen)?.config ??
      GrowthConfig.disabled;
}
