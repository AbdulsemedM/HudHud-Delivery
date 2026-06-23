import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/sos/data/sos_contacts_local_store.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load contacts round-trip', () async {
    final store = SosContactsLocalStore();
    const contact = EmergencyContactModel(
      id: 1,
      name: 'Jane',
      phone: '+1234567890',
      relationship: 'Sister',
      isPrimary: true,
    );

    await store.saveContact(contact);
    final loaded = await store.getContacts();

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Jane');

    await store.removeContact(1);
    expect(await store.getContacts(), isEmpty);
  });
}
