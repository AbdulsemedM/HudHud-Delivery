import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';

void main() {
  test('parses add contact response', () {
    final contact = EmergencyContactModel.fromJson({
      'id': 2,
      'user_id': 36,
      'name': 'John Doe',
      'phone': '+1234567890',
      'email': 'john.doe@example.com',
      'relationship': 'Brother',
      'is_primary': true,
      'is_active': true,
      'created_at': '2026-05-28T08:24:29.000000Z',
      'updated_at': '2026-05-28T08:24:29.000000Z',
    });

    expect(contact.id, 2);
    expect(contact.name, 'John Doe');
    expect(contact.isPrimary, isTrue);
    expect(contact.toCreateBody()['name'], 'John Doe');
  });
}
