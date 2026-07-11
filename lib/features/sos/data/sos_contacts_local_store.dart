import 'dart:convert';

import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosContactsLocalStore {
  static const _prefsKey = 'sos_emergency_contacts';

  Future<List<EmergencyContactModel>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => EmergencyContactModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveContact(EmergencyContactModel contact) async {
    final contacts = await getContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index >= 0) {
      contacts[index] = contact;
    } else {
      contacts.add(contact);
    }
    await _persist(contacts);
  }

  Future<void> removeContact(int id) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.id == id);
    await _persist(contacts);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _persist(List<EmergencyContactModel> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
