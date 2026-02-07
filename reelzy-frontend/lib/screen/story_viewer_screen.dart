import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:get/get.dart';

class StoryViewerScreen extends StatefulWidget {
  final List stories;

  const StoryViewerScreen({super.key, required this.stories});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = StoryController();

  List<StoryItem> buildStoryItems() {
    return widget.stories.map<StoryItem>((story) {
      if (story['mediaType'] == 'image') {
        return StoryItem.pageImage(
          url: story['mediaUrl'],
          controller: controller,
          duration: const Duration(seconds: 5),
        );
      } else {
        return StoryItem.pageVideo(
          story['mediaUrl'],
          controller: controller,
          duration: const Duration(seconds: 10),
        );
      }
    }).toList();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StoryView(
        storyItems: buildStoryItems(),
        controller: controller,
        onComplete: () => Get.back(),
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Get.back();
          }
        },
      ),
    );
  }
}
