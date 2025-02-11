import 'dart:async';

import 'package:digitalnote/endpoints/get_messages.dart';
import 'package:digitalnote/net_interface/api_response.dart';
import 'package:flutter/foundation.dart';

class MessagesBloc {
  final MessagesEndpoint _messageList = MessagesEndpoint();
  bool first = true;
  List<dynamic>? _messages;

  StreamController<ApiResponse<List<dynamic>>>? _coinListController;

  StreamSink<ApiResponse<List<dynamic>>> get coinsListSink => _coinListController!.sink;

  Stream<ApiResponse<List<dynamic>>> get coinsListStream => _coinListController!.stream;

  MessagesBloc() {
    _coinListController = StreamController<ApiResponse<List<dynamic>>>();
    // fetchTransactions();
  }

  showWait() async {
    coinsListSink.add(ApiResponse.loading('Fetching All Messages'));
  }

  fetchMessages(String addr) async {
    try {
      if(first) {
        coinsListSink.add(ApiResponse.loading('Fetching All Messages'));

      }
      _messages = await _messageList.getMessages(addr);
      if (first) {
        if (_messages != null && _messages!.isNotEmpty) {
          coinsListSink.add(ApiResponse.completed(_messages));
        }
        await _messageList.refreshMessages(addr);
        _messages = await _messageList.getMessages(addr);
        coinsListSink.add(ApiResponse.completed(_messages));
        first = false;
      }
      if(_messages == null || _messages!.isEmpty) {
        await _messageList.refreshMessages(addr);
        _messages = await _messageList.getMessages(addr);
        coinsListSink.add(ApiResponse.completed(_messages));
      }
      coinsListSink.add(ApiResponse.completed(_messages));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!_coinListController!.isClosed) {
        coinsListSink.add(ApiResponse.error(e.toString()));
      }
      // print(e);
    }
  }

  refreshMessages(String addr) async {
    try {
      int i = await _messageList.refreshMessages(addr);
      // fetchMessages(addr);
      if (i > 0) {
        fetchMessages(addr);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      // print(e);
    }
  }

  dispose() {
    _coinListController?.close();
  }
}
