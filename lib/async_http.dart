library async_http;


import "dart:async";

import "dart:html" deferred as html;
import "package:http/browser_client.dart" deferred as browser_client;
import "dart:io" deferred as io;




class AsyncHttpConnection implements StreamSink<List<int>> {

  final Uri address;

  Future<Function> _requester;
  StreamController _responses;

  AsyncHttpConnection(Uri this.address) {
    _responses = new StreamController();

    // some fishy stuff to make it work in both io and html
    Completer<Function> requesterCompleter = new Completer<Function>();
    io.loadLibrary().then((_) {
      var client;
      try {
        client = new io.HttpClient();
      } catch (e) {return;}
      requesterCompleter.complete((List<int> data) {
        client.postUrl(address).then((request) {
          request.add(data);
          request.close().then((response) {
            _responses.addStream(response);
          });
        }, onError: (e) {
          completer.complete(e);
        });
      });
    }, onError: (e){});
    html.loadLibrary().then((_) {
      browser_client.loadLibrary().then((_) {
        requesterCompleter.complete((List<int> data) {
          var client = new browser_client.BrowserClient();
          client.post(address, body: data).then((response) {
            _responses.add(response.bodyBytes);
          });
        });
      });
    });
    _requester = requesterCompleter.future;
  }

  /**
   * A [StreamSink] to add requests to.
   */
  StreamSink<List<int>> get onRequest => this;

  /**
   * A [Stream] with responses.
   */
  Stream<List<int>> get onResponse => _responses.stream;

  // StreamSink bits
  Completer completer;

  @override
  void add(List<int> data) {
    _requester.then((Function requester) => requester(data));
  }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    completer.complete(errorEvent);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.listen((List<int> data) => add(data)).asFuture();
  }

  @override
  Future close() => completer.future;

  @override
  Future get done  => completer.future;

}