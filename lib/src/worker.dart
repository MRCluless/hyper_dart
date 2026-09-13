import 'dart:io';
import 'dart:isolate';

import 'router.dart';

class WorkerConfig {
  final SendPort mainSendPort;
  final int port;
  final void Function(RadixRouter) routeBuilder;

  WorkerConfig(this.mainSendPort, this.port, this.routeBuilder);
}

void startWorker(WorkerConfig config) async {
  try {
    ReceivePort workerReceivePort = ReceivePort();

    config.mainSendPort.send(workerReceivePort.sendPort);

    final router = RadixRouter();

    config.routeBuilder(router);

    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      config.port,
      shared: true,
    );
    print(
      'Isolate [${Isolate.current.debugName}] listening on port ${server.port}',
    );

    server.listen((HttpRequest request) {
      final path = request.uri.path;
      final match = router.search('${request.method}|$path');

      if (match != null) {
        match.handler(request, match.params);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('404 Not Found\n')
          ..close();
      }
    });

    workerReceivePort.listen((message) async {
      if (message == 'shutdown') {
        await server.close();
        workerReceivePort.close();
        config.mainSendPort.send('shutdown_complete');
      }
    });
  } catch (e, stacktrace) {
    print('\n CRASH in ${Isolate.current.debugName}:\n$e\n$stacktrace');
  }
}
