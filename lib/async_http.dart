library async_http;


import "dart:async";

import "dart:html" deferred as html;
import "package:http/browser_client.dart" deferred as browser_client;
import "dart:io" deferred as io;




class AsyncHttpConnection extends Stream implements StreamSink {

  final Uri endpoint;

  Future<Function> _requester;
  StreamController _responses;

  AsyncHttpConnection(String address) : endpoint = Uri.parse(address) {
    _responses = new StreamController();

    // some fishy stuff to make it work in both io and html
    Completer<Function> requesterCompleter = new Completer<Function>();
    io.loadLibrary().then((_) {
      var client;
      try {
        client = new io.HttpClient();
      } catch (e) {return;}
      requesterCompleter.complete((data) {
        client.postUrl(endpoint).then((request) {
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
        requesterCompleter.complete((data) {
          var client = new browser_client.BrowserClient();
          client.post(endpoint, body: data).then((response) {
            _responses.add(response.bodyBytes);
          });
        });
      });
    });
    _requester = requesterCompleter.future;
  }


  /* Stream methods */

  StreamSubscription listen(void onData(event),
                            { Function onError,
                              void onDone(),
                              bool cancelOnError}) =>
      _responses.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);


  /* StreamSink methods */

  Completer completer;

  @override
  void add(data) {
    _requester.then((Function requester) => requester(data));
  }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    completer.completeError(errorEvent);
  }

  @override
  Future addStream(Stream stream) {
    return stream.listen((data) => add(data)).asFuture();
  }

  @override
  Future close() {
    completer.complete();
    return completer.future;
  }

  @override
  Future get done  => completer.future;

}