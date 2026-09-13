import 'dart:io';
import 'dart:isolate';
import 'worker.dart';
import 'router.dart';

class HyperServer {
  static Future<void> listen({
    required int port, 
    required void Function(RadixRouter) routeBuilder
  }) async {
    int coreCount = Platform.numberOfProcessors;
    ReceivePort mainReceivePort = ReceivePort();
    List<SendPort> workerSendPorts = [];
    
    int activeWorkers = 0;
    bool isShuttingDown = false;

    print('Booting up HyperServer on port $port with $coreCount cores...');
    for (int i = 0; i < coreCount; i++) {
      final config = WorkerConfig(mainReceivePort.sendPort, port, routeBuilder);
      
      await Isolate.spawn(
        startWorker, 
        config,
        debugName: 'Worker-$i',
      );
    }

    mainReceivePort.listen((message) {
      if (message is SendPort) {
        workerSendPorts.add(message);
        activeWorkers++;
        
        if (activeWorkers == coreCount) {
          print('\n All $coreCount workers active and listening on port $port.');
          print('Press Ctrl+C to initiate graceful shutdown.');
        }
      } else if (message == 'shutdown_complete') {
        activeWorkers--;
        print('Worker confirmed shutdown. Remaining: $activeWorkers');
        
        if (isShuttingDown && activeWorkers == 0) {
          print('\n[Main] All workers safely terminated. Exiting cleanly.');
          exit(0);
        }
      }
    });
   ProcessSignal.sigint.watch().listen((signal) {
      if (isShuttingDown) return; 
      isShuttingDown = true;
      print('\n[Main] SIGINT received. Telling workers to shut down...');
      if (activeWorkers == 0) {
        print('[Main] No active workers found. Exiting cleanly.');
        exit(0);
      }
      for (var workerPort in workerSendPorts) {
        workerPort.send('shutdown');
      }
    });
  }
}