import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shorts_app/controller/auth/main_auth_controller.dart';
import 'package:shorts_app/screen/forgetpass/forgetpass_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D7A4F);
  final Color secondaryGreen = const Color(0xFF3B9A65);
  final Color darkText = const Color(0xFF1A1A1A);
  final Color lightText = const Color(0xFF9FA5AA);
  final Color backgroundColor = const Color(0xFFF8FBF9);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MainAuthController>()) {
      Get.put(MainAuthController());
    }
    
    final controller = Get.find<MainAuthController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),


              _buildHeader(),

              const SizedBox(height: 50),


              _buildTabSelector(controller),

              const SizedBox(height: 40),


              _buildLoginForm(controller),

              const SizedBox(height: 30),


              _buildLoginButton(controller),

              const SizedBox(height: 30),


              _buildDivider(),

              const SizedBox(height: 30),


              _buildSocialLogin(controller),

              const SizedBox(height: 40),


              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
           color: primaryGreen,
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
                'assets/logo/reelzy.png',
                fit: BoxFit.contain,
              ),
        ),

        const SizedBox(height: 24),


        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            color: darkText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Sign in to continue your journey',
          style: GoogleFonts.inter(
            color: lightText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(MainAuthController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('Login', 'login', controller)),
          Expanded(child: _buildTabItem('Sign Up', 'signup', controller)),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      String title, String value, MainAuthController controller) {
    return Obx(() {
      final isSelected = controller.ui.selectedTab.value == value;

      return GestureDetector(
        onTap: () {
          final currentTab = controller.ui.selectedTab.value;
          if (currentTab != value) {
            controller.ui.switchTab(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [primaryGreen, secondaryGreen])
                : null,
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? null : Colors.transparent,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : lightText,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoginForm(MainAuthController controller) {
    return Obx(() {
      if (controller.ui.selectedTab.value == 'login') {
        return Form(
          key: controller.form.loginFormKey,
          child: _buildLoginFields(controller),
        );
      } else {
        return Form(
          key: controller.form.signupFormKey,
          child: _buildSignupFields(controller),
        );
      }
    });
  }

  Widget _buildLoginFields(MainAuthController controller) {
    return Column(
      children: [

        _buildInputField(
          controller: controller.form.emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          focusedController: controller.form.emailFocused,
          onFocusChange: controller.form.focusEmailField,
        ),

        const SizedBox(height: 20),

        Obx(
          () => _buildInputField(
            controller: controller.form.passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: controller.ui.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.ui.isPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: lightText,
              ),
              onPressed: controller.ui.togglePasswordVisibility,
            ),
            focusedController: controller.form.passwordFocused,
            onFocusChange: controller.form.focusPasswordField,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => GestureDetector(
                onTap: controller.ui.toggleRememberMe,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: controller.ui.rememberMe.value
                            ? primaryGreen
                            : Colors.transparent,
                        border: Border.all(
                            color: controller.ui.rememberMe.value
                                ? primaryGreen
                                : lightText),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: controller.ui.rememberMe.value
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.inter(
                        color: lightText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.to(() => const ForgetPasswordScreen());
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  color: primaryGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignupFields(MainAuthController controller) {
    return Column(
      children: [
        _buildInputField(
          controller: controller.form.nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          focusedController: controller.form.nameFocused,
          onFocusChange: controller.form.focusNameField,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          controller: controller.form.emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          focusedController: controller.form.emailFocused,
          onFocusChange: controller.form.focusEmailField,
        ),

        const SizedBox(height: 20),

        Obx(
          () => _buildInputField(
            controller: controller.form.passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: controller.ui.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.ui.isPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: lightText,
              ),
              onPressed: controller.ui.togglePasswordVisibility,
            ),
            focusedController: controller.form.passwordFocused,
            onFocusChange: controller.form.focusPasswordField,
          ),
        ),

        const SizedBox(height: 20),

        Obx(
          () => _buildInputField(
            controller: controller.form.confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            isPassword: true,
  obscureText: controller.ui.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.ui.isPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: lightText,
              ),
              onPressed: controller.ui.togglePasswordVisibility,
            ),
            focusedController: controller.form.passwordFocused,
            onFocusChange: controller.form.focusPasswordField,
          ),
        ),

        const SizedBox(height: 20),

        Obx(
          () => GestureDetector(
            onTap: controller.ui.toggleAcceptTerms,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: controller.ui.acceptTerms.value
                        ? primaryGreen
                        : Colors.transparent,
                    border: Border.all(
                        color: controller.ui.acceptTerms.value
                            ? primaryGreen
                            : lightText),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: controller.ui.acceptTerms.value
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: lightText,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: GoogleFonts.inter(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    required Rx<bool> focusedController,
    required Function(bool) onFocusChange,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: focusedController.value
              ? primaryGreen.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Focus(
        onFocusChange: onFocusChange,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(
              color: darkText, fontSize: 16, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(
              color: focusedController.value ? primaryGreen : lightText,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: focusedController.value ? primaryGreen : lightText,
              size: 22,
            ),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(MainAuthController controller) {
    return Obx(() {
      final isLogin = controller.ui.selectedTab.value == 'login';

      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen, secondaryGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              if (isLogin) {
                controller.onLoginPressed();
              } else {
                controller.onSignupPressed();
              }
            },
            child: Center(
              child: controller.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLogin ? 'Login' : 'Create Account',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              color: lightText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin(MainAuthController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            'Google',
            Icons.g_mobiledata,
            Colors.red,
            () {
              controller.loginWithGoogle();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            'Apple',
            Icons.apple,
            Colors.black,
            () {
              controller.loginWithApple();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            'Facebook',
            Icons.facebook,
            Colors.blue,
            () {
              controller.loginWithFacebook();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Obx(() {
      final isLogin =
          Get.find<MainAuthController>().ui.selectedTab.value == 'login';

      return Column(
        children: [
          Text(
            isLogin ? 'Don\'t have an account?' : 'Already have an account?',
            style: GoogleFonts.inter(
              color: lightText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              final controller = Get.find<MainAuthController>();
              controller.ui.switchTab(isLogin ? 'signup' : 'login');
            },
            child: Text(
              isLogin ? 'Sign Up Now' : 'Login Instead',
              style: GoogleFonts.inter(
                color: primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    });
  }
}