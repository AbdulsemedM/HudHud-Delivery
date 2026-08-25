import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';

void main() {
  test('notifyRefresh calls registered listeners', () {
    var count = 0;
    void listener() => count++;

    CourierHomeRefresh.instance.addListener(listener);
    CourierHomeRefresh.instance.notifyRefresh();
    CourierHomeRefresh.instance.removeListener(listener);

    expect(count, 1);
  });
}
