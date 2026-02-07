import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shorts_app/controller/auth/main_auth_controller.dart';
import 'package:shorts_app/controller/home/home_controller.dart';
import 'package:shorts_app/controller/post/post_controller.dart';
import 'package:shorts_app/controller/profile/my_profile_controller.dart';
import 'package:shorts_app/screen/message/chat_screen.dart';
import 'package:shorts_app/screen/navigation/navigation.dart';
import 'package:shorts_app/service/calling_service.dart';
import 'package:shorts_app/service/chat_service.dart';
import 'package:shorts_app/service/notificationService.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Rx<User?> user = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
  }

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userId => _auth.currentUser?.uid;

  Future<User?> createAccount(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // await sendEmailVerification();

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e");
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;

      if (user != null && user.displayName == null) {
        final name =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? 'Apple login failed');
      return null;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return null;
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? 'Facebook login failed');
      return null;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return null;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      Get.snackbar("Error", "Google sign-in failed: $e");
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      Get.snackbar("Error", "Anonymous sign-in failed: $e");
      return null;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar("Success", "Password reset email sent to $email");
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to send password reset email: $e");
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar("Success", "Verification email sent to ${user.email}");
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to send verification email: $e");
      return false;
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<bool> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await reloadUser();
      Get.snackbar("Success", "Display name updated");
      return true;
    } catch (e) {
      Get.snackbar("Error", "Failed to update display name: $e");
      return false;
    }
  }

  Future<bool> updatePhotoURL(String photoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoURL);
      await reloadUser();
      Get.snackbar("Success", "Profile photo updated");
      return true;
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile photo: $e");
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      Get.snackbar("Success", "Password updated successfully");
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to change password: $e");
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();

      Get.snackbar("Success", "Account deleted successfully");
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to delete account: $e");
      return false;
    }
  }

Future<void> logout() async {
  try {

    final currentUser = _auth.currentUser;
    final providers = currentUser?.providerData.map((p) => p.providerId).toList() ?? [];
    
    print('Current providers: $providers');

  

    if (Get.isRegistered<ChatService>()) {
      try {
        Get.find<ChatService>().disconnect();
        print('Chat service disconnected');
      } catch (e) {
        print('Chat disconnect error: $e');
      }
    }

    if (Get.isRegistered<CallingService>()) {
      try {
        Get.find<CallingService>().reset();
        print('Calling service reset');
      } catch (e) {
        print('Calling reset error: $e');
      }
    }

    try {
      Get.delete<PostsController>(force: true);
      Get.delete<MyProfileController>(force: true);
      Get.delete<ChatListController>(force: true);
      Get.delete<NavigationController>(force: true);

      
    } catch (e) {
      print('Controller deletion error: $e');
    }

    if (providers.contains('google.com')) {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Google sign out error: $e');
      }
    }

    if (providers.contains('facebook.com')) {
      try {
        await FacebookAuth.instance.logOut();
        print('Facebook sign out');
      } catch (e) {
        print('Facebook sign out error: $e');
      }
    }

    await _auth.signOut();
    
    Get.snackbar("Success", "Logged out successfully");
    
  } catch (e) {
    print('Logout error: $e');
    
    Get.snackbar("Error", "Error logging out: $e");
  }
}

  
 

  void _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists for this email.';
        break;
      case 'user-not-found':
        message = 'No user found for this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      case 'requires-recent-login':
        message = 'Please log in again to perform this action.';
        break;
      default:
        message = 'error occurred: ${e.message}';
    }
    Get.snackbar("Authentication Error", message);
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  List<String> get providerIds =>
      _auth.currentUser?.providerData.map((info) => info.providerId).toList() ??
      [];

  String? get displayName => _auth.currentUser?.displayName;
  String? get photoURL => _auth.currentUser?.photoURL;
  String? get phoneNumber => _auth.currentUser?.phoneNumber;

  DateTime? get creationTime => _auth.currentUser?.metadata.creationTime;
  DateTime? get lastSignInTime => _auth.currentUser?.metadata.lastSignInTime;
}
