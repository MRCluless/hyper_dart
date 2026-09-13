import 'package:hyper_dart/hyper_dart.dart';

// Mock authentication middleware
Future<void> requireAuth(HyperRequest req, HyperResponse res, NextFunction next) async {
  bool hasToken = false; 
  
  if (!hasToken) {
    return res.json({'error': 'Unauthorized! Token missing.'}, status: 401);
  }
}

void setupRoutes(RadixRouter app) {
  app.get('/home', (req, res) {
    res.json({'message': 'Welcome to the public home page'});
  });

  app.get('/dashboard', (req, res) {
    res.json({'message': 'Welcome to the highly secure admin dashboard'});
  }, [requireAuth]);
}

void main() async {
  await HyperServer.listen(
    port: 3000,
    routeBuilder: setupRoutes,
  );
}