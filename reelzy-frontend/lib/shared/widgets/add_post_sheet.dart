import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/service/authentication.dart';

class AddPostController extends GetxController {
  final TextEditingController postController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  var selectedImage = Rxn<String>();
  var selectedLink = Rxn<String>();
  var isLinkPreview = false.obs;
  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;

  // Backend API configuration
  final baseUrl = Get.find<ApiController>().baseUrl;

  @override
  void onClose() {
    postController.dispose();
    locationController.dispose();
    linkController.dispose();
    super.onClose();
  }

  Future<void> selectImage({bool fromCamera = true}) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = image.path;
        Get.snackbar(
          'Image Selected',
          'You have selected an image for your post',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      print('Error selecting image: $e');
      Get.snackbar(
        'Error',
        'Failed to select image: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // Upload image to S3 via backend
  Future<String?> uploadImageToS3(String imagePath) async {
    try {
      uploadProgress.value = 0.0;

      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      request.fields['userId'] = currentUser.uid;

      // Add a caption (you can make this customizable)
      request.fields['caption'] =
          postController.text.trim().isEmpty
              ? 'Post image'
              : postController.text.trim();

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imagePath,
        contentType: MediaType('image', imagePath.split('.').last),
      );

      request.files.add(multipartFile);

      print('Uploading image to S3...');
      print('File path: $imagePath');
      print('File size: ${await imageFile.length()} bytes');
      print('UserId: ${currentUser.uid}');

      // Send request with progress tracking
      var streamedResponse = await request.send();

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          uploadProgress.value = 1.0;
          final imageUrl = responseData['file']['url'];

          print('Image uploaded successfully: $imageUrl');

          Get.snackbar(
            'Upload Success',
            'Image uploaded to cloud storage',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          );

          return imageUrl;
        } else {
          throw Exception(responseData['error'] ?? 'Upload failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error during upload');
      }
    } catch (error) {
      print('Image upload error: $error');

      Get.snackbar(
        'Upload Error',
        'Failed to upload image: ${error.toString()}',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

      return null;
    }
  }

  void addLink() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: linkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter URL...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (linkController.text.isNotEmpty) {
                          selectedLink.value = linkController.text;
                          isLinkPreview.value = true;
                          Get.back();
                          Get.snackbar(
                            'Link Added',
                            'Link preview added to your post',
                            backgroundColor: Colors.blue.withOpacity(0.8),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void removeImage() {
    selectedImage.value = null;
  }

  void removeLink() {
    selectedLink.value = null;
    isLinkPreview.value = false;
    linkController.clear();
  }

  // Create post with S3 image upload
  Future<void> createPost() async {
    if (postController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please write something to share',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;
    String? uploadedImageUrl;

    try {
      if (selectedImage.value != null && selectedImage.value!.isNotEmpty) {
        Get.snackbar(
          'Uploading',
          'Uploading image to cloud storage...',
          backgroundColor: Colors.blue.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );

        uploadedImageUrl = await uploadImageToS3(selectedImage.value!);

        if (uploadedImageUrl == null) {
          // Upload failed, stop here
          isLoading.value = false;
          return;
        }

        print('Image uploaded to S3: $uploadedImageUrl');
      }

      // Step 2: Create post with the uploaded image URL
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final postData = {
        'userId': currentUser.uid,
        'username': currentUser.displayName ?? 'Anonymous',
        'content': postController.text.trim(),
        'location': locationController.text.trim(),
        'mediaUrl': uploadedImageUrl ?? '',
        'mediaType': _getMediaType(uploadedImageUrl),
        'linkUrl': selectedLink.value ?? '',
        'linkTitle': _getLinkTitle(),
      };

      print('Creating post with data: $postData');

      // Make HTTP POST request to backend
      final response = await http.post(
        Uri.parse('$baseUrl/addPost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Parse successful response
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Success - close modal and show success message
          Get.back();
          Get.snackbar(
            'Success',
            'Your post has been shared!',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );

          // Clear form
          _clearForm();

          print('Post created successfully: ${responseData['data']}');
        } else {
          throw Exception(responseData['error'] ?? 'Unknown error occurred');
        }
      } else {
        // Handle HTTP error responses
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error occurred');
      }
    } catch (error) {
      print('Create post error: $error');

      String errorMessage = 'Failed to create post. Please try again.';

      if (error.toString().contains('authenticated')) {
        errorMessage = 'Please sign in to create a post.';
      } else if (error.toString().contains('userId') ||
          error.toString().contains('username') ||
          error.toString().contains('content')) {
        errorMessage =
            'Missing required information. Please check your inputs.';
      } else if (error.toString().contains('SocketException') ||
          error.toString().contains('HandshakeException')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else if (error.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (error.toString().contains('FormatException')) {
        errorMessage = 'Server response error. Please try again.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  String _getMediaType(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return 'none';
    }

    // Check file extension
    String extension = mediaUrl.split('.').last.toLowerCase();
    if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
      return 'video';
    }

    return 'image';
  }

  String _getLinkTitle() {
    if (selectedLink.value == null || selectedLink.value!.isEmpty) {
      return '';
    }

    // Extract title from URL or return the URL itself
    try {
      Uri uri = Uri.parse(selectedLink.value!);
      return uri.host;
    } catch (e) {
      return selectedLink.value!;
    }
  }

  void _clearForm() {
    postController.clear();
    locationController.clear();
    linkController.clear();
    selectedImage.value = null;
    selectedLink.value = null;
    isLinkPreview.value = false;
    uploadProgress.value = 0.0;
  }
}

class AddPostSheet extends StatelessWidget {
  const AddPostSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddPostController());
    final auth = Get.find<AuthenticationService>();

    // Theme Colors for Light Mode
    const Color bgWhite = Colors.white;
    const Color textDark = Color(0xFF1A1A1A);
    const Color textGrey = Color(0xFF6B7280);
    const Color inputFill = Color(0xFFF3F4F6); // Very light grey

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: bgWhite, // Light background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: textDark, // Dark icon
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'New Post',
                  style: TextStyle(
                    color: textDark, // Dark text
                    fontWeight: FontWeight.w800,
                    fontSize: 20, // Slightly smaller for elegance
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => GestureDetector(
                    onTap:
                        controller.isLoading.value
                            ? null
                            : controller.createPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            controller.isLoading.value
                                ? LinearGradient(
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[400]!,
                                  ],
                                )
                                : const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFFEC4899),
                                  ], // Keep vibrant gradient for primary action
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                        borderRadius: BorderRadius.circular(30), // Pill shape
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          controller.isLoading.value
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Post',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey,
                            backgroundImage: NetworkImage(
                              auth.photoURL!,
                            ), // Example image
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName!, // Dynamic user name here
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.public, size: 12, color: textGrey),
                                const SizedBox(width: 4),
                                Text(
                                  'Public',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Post text input
                  Container(
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: controller.postController,
                      maxLines: 6,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'What\'s happening?',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF), // Lighter grey
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location input (if needed)
                  Container(
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: controller.locationController,
                      style: const TextStyle(color: textDark, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Add location',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFEF4444), // Red icon
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Media options Label
                  const Text(
                    'Add to your post',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Media Buttons Row
                  Row(
                    children: [
                      _buildMediaOption(
                        icon: Icons.image_rounded,
                        label: 'Photo',
                        color: const Color(0xFF10B981), // Emerald Green
                        bgColor: const Color(0xFFD1FAE5),
                        onTap: () => controller.selectImage(fromCamera: false),
                      ),

                      const SizedBox(width: 12),
                      _buildMediaOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: const Color(0xFF3B82F6), // Blue
                        bgColor: const Color(0xFFDBEAFE),
                        onTap: () => controller.selectImage(fromCamera: true),
                      ),

                      const SizedBox(width: 12),
                      _buildMediaOption(
                        icon: Icons.link_rounded,
                        label: 'Link',
                        color: const Color(0xFFF59E0B), // Amber
                        bgColor: const Color(0xFFFEF3C7),
                        onTap: controller.addLink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Selected image preview
                  Obx(
                    () =>
                        controller.selectedImage.value != null
                            ? Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      File(controller.selectedImage.value!),
                                      width: double.infinity,
                                      height: 250,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: double.infinity,
                                          height: 250,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.grey[400],
                                              size: 48,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Remove Image Button
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: controller.removeImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black87,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Loading Indicator Overlay
                                  Obx(() {
                                    if (controller.isLoading.value &&
                                        controller.uploadProgress.value > 0 &&
                                        controller.uploadProgress.value < 1) {
                                      return Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: LinearProgressIndicator(
                                          value:
                                              controller.uploadProgress.value,
                                          backgroundColor: Colors.white54,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFF8B5CF6)),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            )
                            : const SizedBox(),
                  ),

                  // Link preview
                  Obx(
                    () =>
                        controller.isLinkPreview.value
                            ? Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEFF6FF,
                                ), // Light Blue tint
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.link,
                                      color: Color(0xFF3B82F6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Link Attached',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          controller.selectedLink.value ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: controller.removeLink,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFEE2E2,
                                        ), // Light Red
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : const SizedBox(),
                  ),

                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            // No border for cleaner look in light mode
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color, // Match text color to icon
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
