import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shorts_app/service/authentication.dart';

class BaseAuthController extends GetxController {
  final AuthenticationService _authService = Get.put(AuthenticationService());

  RxBool isLoading = false.obs;
  RxBool isEmailVerified = false.obs;

  AuthenticationService get authService => _authService;


  @override
  void onInit() {
    super.onInit();
    checkAuthState();
    
    ever(_authService.user, (User? user) {
      if (user != null) {
        isEmailVerified.value = user.emailVerified;
        _handleAuthStateChange(user);
      } else {
        isEmailVerified.value = false;
      }
    });
  }

  void checkAuthState() {
    User? user = _authService.currentUser;
    if (user != null) {
      isEmailVerified.value = user.emailVerified;
      _handleAuthStateChange(user);
    }
  }

  void _handleAuthStateChange(User user) {
    if (user.emailVerified) {
    } else if (!user.isAnonymous) {
    }
  }


}