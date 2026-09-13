import 'dart:io';
import 'dart:isolate';
import 'worker.dart';

class HyperServer {
  static Future<void> start() async {
    int coreCount = Platform.numberOfProcessors;
    ReceivePort mainReceivePort = ReceivePort();
    List<SendPort> workerSendPorts = [];
    
    int activeWorkers = 0;
    bool isShuttingDown = false;

    print('Starting with $coreCount cores...');

    for (int i = 0; i < coreCount; i++) {
      await Isolate.spawn(
        startWorker, 
        mainReceivePort.sendPort,
        debugName: 'Worker-$i',
      );
    }

    mainReceivePort.listen((message) {
      if (message is SendPort) {
        workerSendPorts.add(message);
        activeWorkers++;
        
        if (activeWorkers == coreCount) {
          print('\n All $coreCount workers active and listening.');
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

      for (var workerPort in workerSendPorts) {
        workerPort.send('shutdown');
      }
    });
  }
}