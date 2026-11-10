import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AuthService> freshAuth() async {
    final auth = AuthService();
    await auth.loaded;
    return auth;
  }

  test('signInWithGoogleAccount creates a signed-in user', () async {
    final auth = await freshAuth();
    await auth.signInWithGoogleAccount(
      name: 'Zain Ul Abidin',
      email: 'Zain@Example.com',
    );
    expect(auth.isSignedIn, isTrue);
    expect(auth.currentUser?.name, 'Zain Ul Abidin');
    // Email lowercase + trimmed save hoti hai.
    expect(auth.currentUser?.email, 'zain@example.com');
    expect(auth.currentUser?.initials, 'ZA');
  });

  test('signInWithGoogleAccount validation throws', () async {
    final auth = await freshAuth();
    expect(
      () => auth.signInWithGoogleAccount(name: 'Z', email: 'z@example.com'),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => auth.signInWithGoogleAccount(name: 'Zain', email: 'not-an-email'),
      throwsA(isA<AuthException>()),
    );
  });

  test('signInWithGoogle without OAuth setup throws AuthException', () async {
    // Test env me koi Google OAuth client nahi — MissingPluginException
    // AuthException me map honi chahiye, app crash nahi karni chahiye.
    final auth = await freshAuth();
    expect(
      () => auth.signInWithGoogle(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('not set up'),
        ),
      ),
    );
    expect(auth.isSignedIn, isFalse);
  });

  test('updateName changes name and persists', () async {
    final auth = await freshAuth();
    await auth.signInWithGoogleAccount(
      name: 'Zain',
      email: 'zain@example.com',
    );
    await auth.updateName('Zain Ul Abidin');
    expect(auth.currentUser?.name, 'Zain Ul Abidin');

    // Naya instance — prefs se wapas load ho.
    final auth2 = AuthService();
    await auth2.loaded;
    expect(auth2.isSignedIn, isTrue);
    expect(auth2.currentUser?.name, 'Zain Ul Abidin');
  });

  test('deleteAccount removes everything', () async {
    final auth = await freshAuth();
    await auth.signInWithGoogleAccount(
      name: 'Zain',
      email: 'zain@example.com',
    );
    await auth.deleteAccount();
    expect(auth.isSignedIn, isFalse);

    final auth2 = AuthService();
    await auth2.loaded;
    expect(auth2.isSignedIn, isFalse);
  });

  test('signOut clears the local session', () async {
    final auth = await freshAuth();
    await auth.signInWithGoogleAccount(
      name: 'Zain',
      email: 'zain@example.com',
    );
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);

    // Naya instance bhi signed out ho — session persist nahi hoti.
    final auth2 = AuthService();
    await auth2.loaded;
    expect(auth2.isSignedIn, isFalse);
  });
}
