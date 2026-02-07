import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class StoryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxString selectedMediaPath = ''.obs;
  final RxString mediaType = ''.obs;
  final RxBool isMediaInitialized = false.obs;
  final RxList<dynamic> storiesFeed = <dynamic>[].obs;

  VideoPlayerController? videoController;
  final ImagePicker _picker = ImagePicker();
  final ApiController _apiController = Get.find<ApiController>();

  @override
  void onClose() {
    videoController?.pause();
    videoController?.dispose();
    videoController = null;
    super.onClose();
  }

  Future<void> selectImage() async {
    try {
      isLoading.value = true;
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        selectedMediaPath.value = image.path;
        mediaType.value = 'image';
        isMediaInitialized.value = true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to select image: $e');
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> captureImage() async {
    try {
      isLoading.value = true;
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        selectedMediaPath.value = image.path;
        mediaType.value = 'image';
        isMediaInitialized.value = true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image: $e');
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectVideo() async {
    try {
      isLoading.value = true;
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        selectedMediaPath.value = video.path;
        mediaType.value = 'video';
        await _initializeVideoPlayer();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to select video: $e');
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordVideo() async {
    try {
      isLoading.value = true;
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);

      if (video != null) {
        selectedMediaPath.value = video.path;
        mediaType.value = 'video';
        await _initializeVideoPlayer();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to record video: $e');
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (selectedMediaPath.value.isNotEmpty && mediaType.value == 'video') {
      videoController?.dispose();
      videoController = VideoPlayerController.file(
        File(selectedMediaPath.value),
      );

      await videoController!.initialize();
      videoController!.setLooping(true);
      isMediaInitialized.value = true;
    }
  }

  void toggleVideoPlayPause() {
    if (videoController != null) {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
    }
  }

  void clearMedia() {
    videoController?.dispose();
    videoController = null;
    selectedMediaPath.value = '';
    mediaType.value = '';
    isMediaInitialized.value = false;
  }

  Future<void> uploadStory() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'User is not logged in');
      return;
    }

    if (selectedMediaPath.value.isEmpty || mediaType.value.isEmpty) {
      Get.snackbar('Error', 'Please select media first');
      return;
    }

    try {
      isUploading.value = true;

      final File mediaFile = File(selectedMediaPath.value);
      if (!mediaFile.existsSync()) {
        Get.snackbar('Error', 'Selected media file does not exist');
        return;
      }

      print('Starting upload...');
      print('File: ${mediaFile.path}');
      print('Media Type: ${mediaType.value}');

      final fullUrl = '${_apiController.baseUrl}/upload-story';
      print('URL: $fullUrl');

      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      request.fields['userId'] = currentUser.uid;
      request.fields['mediaType'] = mediaType.value;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          filename: mediaFile.path.split('/').last,
        ),
      );

      print('Fields: ${request.fields}');

      final res = await request.send();
      final response = await http.Response.fromStream(res);

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          Get.snackbar('Success', 'Story uploaded successfully');
          clearMedia();
          Get.back();
        } else {
          Get.snackbar('Error', responseData['error'] ?? 'Upload failed');
        }
      } else {
        Get.snackbar('Error', 'Failed to upload story');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload story: $e');
      print('Error: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> getStoriesFeed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'User is not logged in');
      return;
    }

    try {
      isLoading.value = true;

      final fullUrl = '${_apiController.baseUrl}/feed/${currentUser.uid}';
      print('Fetching feed from: $fullUrl');

      final response = await http.get(Uri.parse(fullUrl));

      print('Feed Status: ${response.statusCode}');
      print('Feed Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          storiesFeed.value = responseData['stories'] ?? [];
          print('Loaded ${storiesFeed.length} stories');
        } else {
          Get.snackbar('Error', 'Failed to load stories');
        }
      } else if (response.statusCode == 404) {
        Get.snackbar('Error', 'User not found');
      } else {
        Get.snackbar('Error', 'Failed to fetch stories');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch stories: $e');
      print('Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStories() async {
    await getStoriesFeed();
  }
}