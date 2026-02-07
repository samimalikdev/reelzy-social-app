import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/auth/form_validation_controller.dart';
import 'package:shorts_app/controller/auth/ui_state_controller.dart';
import 'package:shorts_app/screen/email_verification/verification_screen.dart';
import 'package:shorts_app/screen/home/home_screen.dart';
import 'package:shorts_app/screen/login/login_screen.dart';
import 'package:shorts_app/screen/navigation/navigation.dart';
import 'package:shorts_app/service/calling_service.dart';
import 'package:shorts_app/service/chat_service.dart';
import 'base_auth_controller.dart';

class AuthActionsController extends BaseAuthController {
  final FormValidationController _formController = Get.put(
    FormValidationController(),
  );
  final UIStateController _uiController = Get.put(UIStateController());

  FormValidationController get formController => _formController;
  UIStateController get uiController => _uiController;
  final ApiController _apiController = Get.find<ApiController>();

  Future<void> login() async {
    final form = _formController.loginFormKey.currentState;
    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;

      User? user = await authService.loginWithEmail(
        _formController.emailController.text.trim(),
        _formController.passwordController.text,
      );

      if (user != null) {
      

        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          _apiController.post('/save-fcm-token', {
            'userId': FirebaseAuth.instance.currentUser!.uid,
            'fcmToken': token,
          });
        }

        final chatService = Get.find<ChatService>();
        final callingService = Get.find<CallingService>();


        chatService.connect(user.uid);
        callingService.init(sharedSocket: chatService.socket, userId: user.uid);

        _clearAllControllers();
        Get.offAll(Navigation());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup() async {
    final form = _formController.signupFormKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_uiController.acceptTerms.value) {
      Get.snackbar('Error', 'Please accept terms and conditions');
      return;
    }

    try {
      isLoading.value = true;

      User? user = await authService.createAccount(
        _formController.emailController.text.trim(),
        _formController.passwordController.text,
      );

      if (user != null) {
        await user.updateDisplayName(
          _formController.nameController.text.trim(),
        );
        await user.reload();

        print('username is ${user.displayName}');

        final api = ApiController();

        await api.post('/create-user', {
          'userId': user.uid,
          'email': user.email,
          'username': _formController.nameController.text.trim(),
          'profilePic': user.photoURL ?? '',
        });

        _clearAllControllers();

        Get.offAll(LoginScreen());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
  try {
    isLoading.value = true;

    User? user = await authService.signInWithGoogle();
    if (user == null) {
      print('Google signin failed');
      return;
    }

    print('Google signin successful: ${user.uid}');

    final createRes = await _apiController.post('/create-user', {
      'userId': user.uid,
      'email': user.email,
      'username': user.displayName ?? '',
      'profilePic': user.photoURL ?? '',
    }).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('Create user API timeout');
        return {'success': true};
      },
    );

    print('Create user response: $createRes');

    if (createRes == null) {
      print('Firebase auth succeeded');
    } else if (createRes['success'] != true && 
               createRes['message']?.contains('already exists') != true) {
      Get.snackbar(
        'Error',
        createRes['message'] ?? 'Account creation failed',
        duration: Duration(seconds: 3),
      );
      await authService.logout();
      return;
    }

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');

      if (fcmToken != null) {
        await _apiController.postT('/save-fcm-token', {
          'userId': user.uid,
          'fcmToken': fcmToken,
        }).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('FCM token save timeout');
            return {'success': true};
          },
        );
      }
    } catch (e) {
      print('FCM token error: $e');
    }

    try {
      final chatService = Get.find<ChatService>();
      final callingService = Get.find<CallingService>();
      
      chatService.connect(user.uid);
      callingService.init(sharedSocket: chatService.socket, userId: user.uid);
      print('Services initialized successfully');
    } catch (e) {
      print('Service error: $e');
    }

    _clearAllControllers();
    Get.offAll(Navigation());
    
    
  } catch (e) {
    print('Login error: $e');
    Get.snackbar(
      'Login Failed', 
      e.toString(),
      duration: Duration(seconds: 3),
    );
  } finally {
    isLoading.value = false;
  }
}

  Future<void> loginWithFacebook() async {
    try {
      isLoading.value = true;

      User? user = await authService.signInWithFacebook();
      if (user == null) return;

      final createRes = await _apiController.post('/create-user', {
        'userId': user.uid,
        'email': user.email,
        'username': user.displayName ?? '',
        'profilePic': user.photoURL ?? '',
        'provider': 'facebook',
      });

      if (createRes == null || createRes['success'] != true) {
        Get.snackbar(
          'Error',
          createRes?['message'] ?? 'Account create nahi hua',
        );
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await _apiController.post('/save-fcm-token', {
          'userId': user.uid,
          'fcmToken': fcmToken,
        });
      }

      _clearAllControllers();
      Get.offAll(() => Navigation());
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    try {
      isLoading.value = true;

      User? user = await authService.signInWithApple();
      if (user == null) return;

      final createRes = await _apiController.post('/create-user', {
        'userId': user.uid,
        'email': user.email,
        'username': user.displayName ?? '',
        'profilePic': user.photoURL ?? '',
        'provider': 'apple',
      });

      if (createRes == null || createRes['success'] != true) {
        Get.snackbar(
          'Error',
          createRes?['message'] ?? 'Account create nahi hua',
        );
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await _apiController.post('/save-fcm-token', {
          'userId': user.uid,
          'fcmToken': fcmToken,
        });
      }

      _clearAllControllers();
      Get.offAll(() => Navigation());
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (!_formController.resetPasswordFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      bool success = await authService.resetPassword(
        _formController.resetEmailController.text.trim(),
      );

      if (success) {
        _formController.resetEmailController.clear();
        _uiController.selectedTab.value = 'login';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    if (!_formController.changePasswordFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      bool success = await authService.changePassword(
        _formController.currentPasswordController.text,
        _formController.newPasswordController.text,
      );

      if (success) {
        _formController.currentPasswordController.clear();
        _formController.newPasswordController.clear();
        Get.back();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;

      final user = authService.currentUser;
      if (user != null) {

        bool success = await authService.deleteAccount(
          _formController.currentPasswordController.text,
        );

        if (success) {
          _clearAllControllers();
          Get.offAllNamed('/login');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _clearAllControllers() {
    _formController.clearControllers();
    _uiController.resetUIState();
  }

  void onLoginPressed() => login();
  void onSignupPressed() => signup();
  void onGoogleSignInPressed() => loginWithGoogle();
  void onForgotPasswordPressed() => resetPassword();
}
