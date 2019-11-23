import 'package:faui/FauiUser.dart';
import 'package:faui/src/06_auth/FauiExceptionAnalyser.dart';
import 'package:faui/src/06_auth/AuthConnector.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

final uuid = new Uuid();
final apiKey = "AIzaSyA3hshWKqeogfYiklVCCtDaWJW8TfgWgB4";

void main() {
  test('Register, sign-in, send reset, delete and delete', () async {
    final String id = uuid.v4();
    final String email = "_test_$id@fakedomain.com";

    await AuthConnector.registerUser(
        apiKey: apiKey, email: email, password: id);

    FauiUser user = await AuthConnector.signInUser(
        apiKey: apiKey, email: email, password: id);

    expect(user.userId == null, false);
    expect(user.email, email);
    expect(user.token == null, false);
    await AuthConnector.sendResetLink(apiKey: apiKey, email: email);
    await AuthConnector.deleteUserIfExists(apiKey: apiKey, idToken: user.token);
    await AuthConnector.deleteUserIfExists(apiKey: apiKey, idToken: user.token);
  });

  test('Refresh token', () async {
    final String id = uuid.v4();
    final String email = "_test_$id@fakedomain.com";

    await AuthConnector.registerUser(
        apiKey: apiKey, email: email, password: id);

    FauiUser user1 = await AuthConnector.signInUser(
        apiKey: apiKey, email: email, password: id);

    expect(user1.userId == null, false);
    expect(user1.email, email);
    expect(user1.token == null, false);

    FauiUser user2 =
        await AuthConnector.refreshToken(apiKey: apiKey, user: user1);

    expect(user2.userId, user1.userId);
    expect(user2.email, user1.email);
    expect(user2.token != null, true);
  });

  test('Registration fails if user exists', () async {
    final String id = uuid.v4();
    final String email = "_test_$id@fakedomain.com";

    await AuthConnector.registerUser(
        apiKey: apiKey, email: email, password: id);

    try {
      await AuthConnector.registerUser(apiKey: apiKey, email: email);
      expect(true, false);
    } on Exception catch (exception) {
      expect(
          FauiExceptionAnalyser.toUiMessage(exception)
              .contains("already registered"),
          true);
    }

    FauiUser user = await AuthConnector.signInUser(
        apiKey: apiKey, email: email, password: id);
    await AuthConnector.deleteUserIfExists(apiKey: apiKey, idToken: user.token);
  });

  test('Token validation', () async {
    final String id = uuid.v4();
    final String email = "_test_$id@fakedomain.com";

    await AuthConnector.registerUser(
        apiKey: apiKey, email: email, password: id);
    FauiUser user1 = await AuthConnector.signInUser(
        apiKey: apiKey, email: email, password: id);
    FauiUser user2 =
        await AuthConnector.verifyToken(apiKey: apiKey, token: user1.token);

    expect(user2.email, email);
    expect(user2.userId, user1.userId);

    await AuthConnector.deleteUserIfExists(
        apiKey: apiKey, idToken: user1.token);
  });
}
