import 'package:hyper_dart/src/context.dart';

typedef NextFunction = Future<void> Function();

typedef Middleware = Future<void> Function(
  HyperRequest req,
  HyperResponse res,
  NextFunction next,
);

typedef RequestHandler = Function(HyperRequest req, HyperResponse res);

class RouteMatch {
  final RequestHandler handler;
  final Map<String, String> params;

  RouteMatch(this.handler, this.params);
}

class RouteNode {
  final String segment;
  final bool isParam;
  RequestHandler? handler;
  final Map<String, RouteNode> children = {};

  RouteNode? paramChild;

  RouteNode(this.segment) : isParam = segment.startsWith(":");
}

class RadixRouter {
  final RouteNode _root = RouteNode("");

  final List<Middleware> _middlewares = [];

  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  List<Middleware> get middlewares => _middlewares;

  List<String> _splitPath(String path) {
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }

  void insert(String path, RequestHandler handler) {
    final segments = _splitPath(path);
    RouteNode current = _root;

    for (String segment in segments) {
      if (segment.startsWith(':')) {
        current.paramChild ??= RouteNode(segment);
        current = current.paramChild!;
      } else {
        if (!current.children.containsKey(segment)) {
          current.children[segment] = RouteNode(segment);
        }
        current = current.children[segment]!;
      }
    }

    current.handler = handler;
  }

  RouteMatch? search(String path) {
    final segments = _splitPath(path);
    RouteNode current = _root;
    Map<String, String> extractedParams = {};

    for (String segment in segments) {
      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else if (current.paramChild != null) {
        current = current.paramChild!;

        String paramName = current.segment.substring(1);
        extractedParams[paramName] = segment;
      } else {
        return null;
      }
    }

    if (current.handler != null) {
      return RouteMatch(current.handler!, extractedParams);
    }

    return null;
  }

  void get(String path, RequestHandler handler) {
    insert('GET|$path', handler);
  }

  void post(String path, RequestHandler handler) {
    insert('POST|$path', handler);
  }

  void put(String path, RequestHandler handler) {
    insert('PUT|$path', handler);
  }

  void patch(String path, RequestHandler handler) {
    insert('PATCH|$path', handler);
  }

  void delete(String path, RequestHandler handler) {
    insert('DELETE|$path', handler);
  }
}
