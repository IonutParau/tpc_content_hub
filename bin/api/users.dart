import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';

import '../db/user.dart';
import '../tpc_content_hub.dart';

void loadUserRoutes(RouterPlus router) {
// Just basic user authentication
  router.post('/new-user', (Request request) {
    if (request.headers['name'] == null || request.headers['raw-pass'] == null) return Response.badRequest();

    if (User.lookByName(request.headers['name']!) != null) return Response.forbidden('Cannot create new user of duplicate name');

    final user = User.create(request.headers['name']!, request.headers['raw-pass']!);

    return Response.ok(user.id);
  });

  router.post('/login-as/<id>', (Request request, String id) {
    if (request.headers['raw-pass'] == null) {
      return Response.badRequest();
    }

    if (!User.exists(id)) {
      return Response.notFound('Database does not contain user of ID $id');
    }

    final user = User(id);
    final pass = request.headers['raw-pass']!;

    final isValid = user.validate(pass);

    late String? session;

    if (isValid) {
      session = uuid.v4();

      // Bind user to Session ID.
      sessions[session] = user;
      handleSessionTimeout(session);
    }

    return isValid ? Response.ok(session) : Response.unauthorized('Password does not match hash');
  });

  router.post('/login', (Request request) {
    if (request.headers['raw-pass'] == null) {
      return Response.badRequest();
    }
    if (request.headers['name'] == null) {
      return Response.badRequest();
    }

    final name = request.headers['name']!;
    final pass = request.headers['raw-pass']!;

    final user = User.lookByName(name);

    if (user == null) return Response.notFound('Could not find user named $name');

    final isValid = user.validate(pass);

    late String? session;

    if (isValid) {
      session = uuid.v4();

      // Bind user to Session ID.
      sessions[session] = user;
      handleSessionTimeout(session);
    }

    return isValid ? Response.ok(session) : Response.unauthorized('Password does not match hash');
  });

  router.get('/user-id', (Request request) {
    if (request.headers['name'] == null) return Response.badRequest();

    final user = User.lookByName(request.headers['name']!);

    if (user == null) return Response.notFound('Could not find user named ${request.headers['name']}');

    return Response.ok(user.id);
  });

  router.get('/user-info/<id>', (Request request, String id) {
    if (!User.exists(id)) {
      return Response.notFound('Requested user not in database.');
    }

    final user = User(id);

    final map = {...user.map};
    map.remove("passhash");

    return Response.ok(jsonEncode(map));
  });

  router.post('/user-man/set-bio', (Request request) async {
    final session = request.headers['session'];
    final bio = request.body;

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.notFound('Specified session already expired');

    user.bio = await bio.asString;

    return Response.ok('Updated bio');
  });

  router.post('/user-man/set-name', (Request request) async {
    final session = request.headers['session'];
    final name = request.body;

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Specified session already expired');

    user.name = await name.asString;

    return Response.ok('Updated name');
  });

  router.post('/user-man/set-pass', (Request request) async {
    final session = request.headers['session'];
    final newpass = request.body;

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Specified session already expired');

    user.changePassword(await newpass.asString);

    return Response.ok('Updated password');
  });

  router.delete('/user-man/del-user', (Request request) async {
    final session = request.headers['session'];

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Specified session already expired');

    User.delete(user);
    sessions.remove(session);
    sessionTimers.remove(session)?.cancel();

    return Response.ok("User has been deleted");
  });
}
