import 'package:digitalnote/support/AppDatabase.dart';
import 'package:digitalnote/models/Contact.dart';

class ContactEndpoint {

  Future<List<Contact>?> fetchDBContacts() async {
    var res = await AppDatabase().getContacts();
    return List.generate(res.length, (i) {
      return Contact(
        id: res[i]['id'] as int,
        name: res[i]['name'] as String,
        addr: res[i]['addr'] as String,
      );
    });
  }

  Future<List<Contact>?> searchContacts(String query) async {
    var d = await AppDatabase().searchContact(query);
    return d;

  }


}