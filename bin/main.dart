import 'package:hyper_dart/hyper_dart.dart';

void setupRoutes(RadixRouter app) {
  app.get('/users/:id', (req, res) {
    String userId = req.params['id']!;

    res.json({'status': 'success', 'userId': userId});
  });
}

void main() async {
  await HyperServer.listen(port: 3000, routeBuilder: setupRoutes);
}
