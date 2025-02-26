import 'dart:async';

import 'package:digitalnote/endpoints/get_contacts.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:digitalnote/models/Contact.dart';
import 'package:flutter/foundation.dart';

class ContactBloc {
  final ContactEndpoint _contactList = ContactEndpoint();
  List<Contact>? _contacts;

  StreamController<ApiResponse<List<Contact>?>>? _coinListController;

  StreamSink<ApiResponse<List<Contact>?>> get coinsListSink => _coinListController!.sink;

  Stream<ApiResponse<List<Contact>?>> get coinsListStream => _coinListController!.stream;

  ContactBloc() {
    _coinListController = StreamController<ApiResponse<List<Contact>?>>();
    // fetchTransactions();
  }

  showWait() async {
    coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
  }

  fetchContacts() async {

    try {
      if (!_coinListController!.isClosed) {
        coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
        _contacts = await _contactList.fetchDBContacts();
        coinsListSink.add(ApiResponse.completed(_contacts));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!_coinListController!.isClosed) {
        coinsListSink.add(ApiResponse.error(e.toString()));
      }
    }
  }

  searchContacts(String query) async {
    try {
      coinsListSink.add(ApiResponse.loading('Fetching All Coins'));
      _contacts= await _contactList.searchContacts(query);
      coinsListSink.add(ApiResponse.completed(_contacts));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!_coinListController!.isClosed) {
        coinsListSink.add(ApiResponse.error(e.toString()));
      }
    }
  }

  dispose() {
    _coinListController?.close();
  }
}
