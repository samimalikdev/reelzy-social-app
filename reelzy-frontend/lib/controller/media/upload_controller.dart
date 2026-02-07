import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/profile/my_profile_controller.dart';
import 'package:shorts_app/service/user_video_service.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';

class UploadController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString selectedVideoPath = ''.obs;
  final RxString description = ''.obs;
  final RxString musicTitle = 'Original Audio'.obs;
  final RxList<String> hashtags = <String>[].obs;
  final RxBool isVideoInitialized = false.obs;

  VideoPlayerController? videoController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController hashtagController = TextEditingController();
  final ApiController _apiController = Get.find<ApiController>();

  final RxString thumbnailPath = ''.obs;
RxBool showPauseIcon = false.obs;

  final UserVideosService _videosService = UserVideosService();


  @override
  void onClose() {
    videoController?.pause();
    videoController?.dispose();
    videoController = null;

    descriptionController.dispose();
    hashtagController.dispose();

    super.onClose();
  }

  Future<void> generateThumbnail(String videoPath) async {
    try {
      final temp = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: temp.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbPath != null) {
        thumbnailPath.value = thumbPath;
        print('Generated at: $thumbPath');
      }
    } catch (e) {
      print('error: $e');
    }
  }

  Future<void> selectVideo() async {
    try {
      isLoading.value = true;
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        selectedVideoPath.value = video.path;
        await _initializeVideoPlayer();
        await generateThumbnail(video.path);
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
        selectedVideoPath.value = video.path;
        await _initializeVideoPlayer();
        await generateThumbnail(video.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to record video: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (selectedVideoPath.value.isNotEmpty) {
      videoController?.dispose();
      videoController = VideoPlayerController.file(
        File(selectedVideoPath.value),
      );

      await videoController!.initialize();
      videoController!.setLooping(true);
      //  videoController!.play();
      isVideoInitialized.value = true;
    }
  }

  void toggleVideoPlayPause() {
    if (videoController != null) {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
        showPauseIcon.value = true;
      } else {
        videoController!.play();
        showPauseIcon.value = false; 
      }
    }
  }

  void addHashtag() {
    if (hashtagController.text.isNotEmpty) {
      hashtags.add(hashtagController.text.trim());
      hashtagController.clear();
    }
  }

  void removeHashtag(int index) {
    hashtags.removeAt(index);
  }

  void clearVideo() {
    videoController?.dispose();
    videoController = null;
    selectedVideoPath.value = '';
    isVideoInitialized.value = false;
    description.value = '';
    thumbnailPath.value = '';
    hashtags.clear();
    descriptionController.clear();
    uploadProgress.value = 0.0;
  }

  Future<void> uploadVideo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'User is not logged in');
      return;
    }

    try {
      isUploading.value = true;

      final File videoFile = File(selectedVideoPath.value);
      if (!videoFile.existsSync()) {
        Get.snackbar('Error', 'Selected video file does not exist');
        return;
      }

      print('Starting upload');
      print('File: ${videoFile.path}');

      final fullUrl = '${_apiController.baseUrl}/upload';
      print('URL: $fullUrl');

      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      request.fields['userId'] = currentUser.uid;
      request.fields['caption'] = descriptionController.text;
      request.fields['hashtags'] = jsonEncode(hashtags.toList());

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      );

      if (thumbnailPath.value.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            thumbnailPath.value,
            filename: thumbnailPath.value.split('/').last,
          ),
        );
      }

      print('Fields: ${request.fields}');

      final res = await request.send();
      final response = await http.Response.fromStream(res);

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        Get.snackbar('Success', responseData['message']);

        clearVideo();
        Get.back();
          final myProfileController = Get.find<MyProfileController>();
         final videos = await _videosService.getUserVideos(currentUser.uid);
          myProfileController.myVideos.assignAll(videos);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload video: $e');
      print('Error: $e');
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }
}
