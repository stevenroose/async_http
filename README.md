async_http
==========

An asynchronous HTTP client using dart:async API that works **both in the VM and in the browser**.


The `AsyncHttpConnection` class provides two main functionalities:

 * `onRequest`: a `StreamSink` to which new requests can be added
 * `onResponse`: a `Stream` in which responses will occur


The main purpose of this library is for usage for f.e. JSON-RPC clients, where command ID's are passed within each request and response.

(Keep in mind that data is handled binary so UTF8 conversion must be done beforehand.
Also, nothing is implemented to know which responses are from which requests.)

A usage example:

```dart

AsyncHttpConnection conn = new AsyncHttpConnection(Uri.parse("https://jsonapi.someprovider.com/"));

conn.onRequest.add(const Utf8Encoder().convert('
{
    "command": "get_some_data",
    "id": 1234567,
    "params": ["param1"]
}'));

conn.onResponse
  .transform(const Utf8Decoder())
  .transform(const JsonDecoder())
  .listen((response) {
    print(response["actual_data"]);
};
```