import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shorts_app/controller/story/story_contoller.dart';
import 'package:video_player/video_player.dart';

class AddStorySheet extends StatelessWidget {
  AddStorySheet({super.key});

  final StoryController storyController = Get.find<StoryController>();
  final Color tealDark = const Color(0xFF1F4E56);
  final Color tealLight = const Color(0xFF4A848F);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Story',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    storyController.clearMedia();
                    Get.back();
                  },
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Obx(() {
              if (!storyController.isMediaInitialized.value) {
                return _buildMediaOptions(context);
              }

              return _buildMediaPreview(context);
            }),
          ),

          Obx(() {
            if (!storyController.isMediaInitialized.value) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: storyController.isUploading.value
                        ? null
                        : () => storyController.uploadStory(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: storyController.isUploading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Share Story',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMediaOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tealLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 60,
              color: tealDark,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Choose Media',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Share a photo or video to your story',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          _buildOptionCard(
            icon: Icons.photo_library_outlined,
            title: 'Photo from Gallery',
            subtitle: 'Choose from your photos',
            onTap: () => storyController.selectImage(),
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photo',
            subtitle: 'Capture a new photo',
            onTap: () => storyController.captureImage(),
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            icon: Icons.video_library_outlined,
            title: 'Video from Gallery',
            subtitle: 'Choose from your videos',
            onTap: () => storyController.selectVideo(),
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            icon: Icons.videocam_outlined,
            title: 'Record Video',
            subtitle: 'Capture a new video',
            onTap: () => storyController.recordVideo(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tealLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tealDark, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Obx(() {
                if (storyController.mediaType.value == 'image') {
                  return Image.file(
                    File(storyController.selectedMediaPath.value),
                    fit: BoxFit.contain,
                  );
                } else if (storyController.mediaType.value == 'video') {
                  if (storyController.videoController != null &&
                      storyController.videoController!.value.isInitialized) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              storyController.videoController!.value.aspectRatio,
                          child: VideoPlayer(storyController.videoController!),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: Obx(() {
                                  final isPlaying = storyController
                                          .videoController?.value.isPlaying ??
                                      false;
                                  return AnimatedOpacity(
                                    opacity: isPlaying ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator(color: Colors.white);
                }
                return const SizedBox.shrink();
              }),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => storyController.clearMedia(),
              icon: const Icon(Icons.refresh),
              label: const Text('Change Media'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tealDark,
                side: BorderSide(color: tealDark),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}