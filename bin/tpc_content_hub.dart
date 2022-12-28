import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as sio;
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_plus/shelf_plus.dart';

import 'api/blueprints.dart';
import 'api/levels.dart';
import 'api/servers.dart';
import 'api/users.dart';
import 'db/user.dart';

const Duration sessionTimeout = Duration(days: 2);

void main(List<String> arguments) {
  withHotreload(createServer, logLevel: Level.WARNING);
}

final Map<String, User> sessions = {};
final Map<String, Timer> sessionTimers = {};

void handleSessionTimeout(String id) {
  sessionTimers[id] = Timer.periodic(sessionTimeout, (timer) {
    sessions.remove(id);
    timer.cancel();
  });
}

Future<HttpServer> createServer() async {
  final router = Router().plus;

  router.get('/', (Request _) => Response.ok('I am alive'));

  loadUserRoutes(router);
  loadLevelsRoutes(router);
  loadBlueprintsRoutes(router);
  loadServersRoutes(router);

  print('Running the server on http://0.0.0.0:3000');
  return sio.serve(router, '0.0.0.0', 3000);
}
