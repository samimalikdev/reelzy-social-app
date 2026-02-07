import 'package:get/get.dart';
import 'auth_actions_controller.dart';
import 'form_validation_controller.dart';
import 'ui_state_controller.dart';


class MainAuthController extends GetxController {
  late final AuthActionsController _authActions;
  late final FormValidationController _formValidation;
  late final UIStateController _uiState;

  AuthActionsController get auth => _authActions;
  FormValidationController get form => _formValidation;
  UIStateController get ui => _uiState;

  bool get isLoading => _authActions.isLoading.value;
  bool get isEmailVerified => _authActions.isEmailVerified.value;

  @override
  void onInit() {
    super.onInit();
    
    _authActions = Get.put(AuthActionsController());
    _formValidation = Get.put(FormValidationController());
    _uiState = Get.put(UIStateController());
  }

  Future<void> login() => _authActions.login();
  Future<void> signup() => _authActions.signup();
  Future<void> loginWithGoogle() => _authActions.loginWithGoogle();
  Future<void> loginWithFacebook() => _authActions.loginWithFacebook();
Future<void> loginWithApple() => _authActions.loginWithApple();
  

  


  void onLoginPressed() => _authActions.onLoginPressed();
  void onSignupPressed() => _authActions.onSignupPressed();
  void onGoogleSignInPressed() => _authActions.onGoogleSignInPressed();
  void onForgotPasswordPressed() => _authActions.onForgotPasswordPressed();

}