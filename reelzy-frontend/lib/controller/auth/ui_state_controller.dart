import 'package:get/get.dart';

class UIStateController extends GetxController {
  RxBool isPasswordVisible = true.obs;
  RxBool isConfirmPasswordVisible = false.obs;
  RxBool isCurrentPasswordVisible = false.obs;
  RxBool isNewPasswordVisible = false.obs;

  RxBool rememberMe = false.obs;
  RxBool acceptTerms = false.obs;
  final RxString selectedTab = 'login'.obs;
  RxString selectedCountryCode = '+1'.obs;

  RxString verificationId = ''.obs;
  RxInt resendToken = 0.obs;
  RxBool isOtpSent = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  void toggleAcceptTerms() {
    acceptTerms.value = !acceptTerms.value;
  }

  void switchTab(String tab) {
    selectedTab.value = tab;
  }

  void setAuthMode(String mode) {
    selectedTab.value = mode;
  }

  void setCountryCode(String code) {
    selectedCountryCode.value = code;
  }

  void resetUIState() {
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
    isCurrentPasswordVisible.value = false;
    isNewPasswordVisible.value = false;
    acceptTerms.value = false;
    isOtpSent.value = false;
    verificationId.value = '';
    resendToken.value = 0;
  }
}