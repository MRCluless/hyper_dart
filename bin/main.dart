import 'dart:io';

import 'package:hyper_dart/hyper_dart.dart';
import 'package:hyper_dart/src/router.dart';

void setupRoutes(RadixRouter app) {
  app.get('/ping', (req, params) {
    req.response
      ..statusCode = HttpStatus.ok
      ..write('Pong')
      ..close();
  });
}

void main() async {
  await HyperServer.listen(port: 3000, routeBuilder: setupRoutes);
}
