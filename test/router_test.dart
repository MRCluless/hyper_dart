import 'package:test/test.dart';
import 'package:hyper_dart/hyper_dart.dart'; // Imports your barrel file

void main() {
  group('RadixRouter', () {
    late RadixRouter router;
    setUp(() {
      router = RadixRouter();
    });

    test('matches a static GET route', () {
      router.get('/ping', (req, res) {});
      final match = router.search('GET|/ping');
      expect(match, isNotNull);
      expect(match!.params, isEmpty);
    });

    test('extracts dynamic URL parameters', () {
      router.get('/users/:id/profile', (req, res) {});

      final match = router.search('GET|/users/999/profile');

      expect(match, isNotNull);
      expect(match!.params['id'], equals('999'));
    });

    test('returns null (404) for non-existent routes', () {
      router.get('/users/:id', (req, res) {});
      final match1 = router.search('GET|/users'); 
      final match2 = router.search('GET|/admin'); 

      expect(match1, isNull);
      expect(match2, isNull);
    });

    test('differentiates between HTTP methods on the same path', () {
      router.get('/data', (req, res) {});
      router.post('/data', (req, res) {});

      final getMatch = router.search('GET|/data');
      final postMatch = router.search('POST|/data');
      final putMatch = router.search('PUT|/data'); // We didn't register this

      expect(getMatch, isNotNull);
      expect(postMatch, isNotNull);
      expect(putMatch, isNull);
    });

    test('attaches route-specific middleware correctly', () {
      Future<void> dummyMiddleware(req, res, next) async {}
      router.get('/secure', (req, res) {}, [dummyMiddleware]);
      router.get('/public', (req, res) {});

      final secureMatch = router.search('GET|/secure');
      final publicMatch = router.search('GET|/public');

      expect(secureMatch!.middlewares.length, equals(1));
      expect(publicMatch!.middlewares.length, equals(0));
    });
  });
}