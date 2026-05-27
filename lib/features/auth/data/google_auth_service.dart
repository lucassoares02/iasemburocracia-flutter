import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '549669468108-vkq356vb6o50j6gh2opr6b5ntgvjn266.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  static Future<String?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.accessToken;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }
}
