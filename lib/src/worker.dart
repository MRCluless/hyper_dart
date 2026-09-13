import 'dart:io';
import 'dart:isolate';

void startWorker(SendPort mainSendPort) async {
  ReceivePort workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080, shared: true);

  server.listen((HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..write('Handled by Isolate: ${Isolate.current.debugName}!\n')
      ..close();
  });

  workerReceivePort.listen((message) async {
    if (message == 'shutdown') {
      await server.close(); 
      workerReceivePort.close(); 
      mainSendPort.send('shutdown_complete'); 
    }
  });
}