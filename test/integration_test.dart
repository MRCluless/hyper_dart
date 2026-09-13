import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('HyperServer Black-Box Integration', () {
    late Process serverProcess;
    final client = HttpClient();

    setUpAll(() async {
      print('Starting server process...');
      serverProcess = await Process.start('dart', ['run', 'bin/main.dart']);
      await for (var line in serverProcess.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        print('[Server Log] $line');
        if (line.contains('active and listening')) {
          print('Test setup complete. Server is ready!');
          break; 
        }
      }
    });

    tearDownAll(() async {
      print('\nSending SIGINT to server...');
      
      serverProcess.kill(ProcessSignal.sigint);
      
      final exitCode = await serverProcess.exitCode;
      if (Platform.isWindows) {
        expect(exitCode, equals(-1), reason: 'Windows forcefully kills processes');
      } else {
        expect(exitCode, equals(0), reason: 'Server did not exit cleanly');
      }
      
      client.close();
      print('Integration tests completed safely.');
    });


    test('GET /home returns 200 OK and valid JSON', () async {
  
      final request = await client.get('localhost', 3000, '/home');
      final response = await request.close();
      
      final bodyString = await response.transform(utf8.decoder).join();
      final bodyJson = jsonDecode(bodyString);

      expect(response.statusCode, equals(200));
      expect(bodyJson['message'], equals('Welcome to the public home page'));
      expect(response.headers.contentType?.mimeType, equals('application/json'));
    });

    test('GET /dashboard is protected by route-specific middleware (401)', () async {
   
      
      final request = await client.get('localhost', 3000, '/dashboard');
      final response = await request.close();
      
      final bodyString = await response.transform(utf8.decoder).join();
      final bodyJson = jsonDecode(bodyString);

      expect(response.statusCode, equals(401));
      expect(bodyJson['error'], contains('Unauthorized'));
    });
    
    test('Returns 404 Not Found for unregistered routes', () async {
      final request = await client.get('localhost', 3000, '/does-not-exist');
      final response = await request.close();
      
      expect(response.statusCode, equals(404));
    });
  });
}