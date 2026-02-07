import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:shorts_app/model/reel_model.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FullscreenVideoScreen extends StatefulWidget {
  final ReelModel reel;

  const FullscreenVideoScreen({super.key, required this.reel});

  @override
  State<FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<FullscreenVideoScreen> {
  final Rx<VideoPlayerController?> controller = Rx(null);
  bool isUIVisible = true;

  @override
  void initState() {
    super.initState();

    controller.value = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.videoUrl!),
    )..initialize().then((_) {
        controller.value?.play();
        controller.refresh();
      });
  }

  @override
  void dispose() {
    controller.value?.dispose();
    controller.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final c = controller.value;
        if (c == null || !c.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final size = c.value.size;

        return GestureDetector(
          onTap: () {
            isUIVisible = !isUIVisible;
            setState(() {});
          },
          child: Stack(
            children: [
              VisibilityDetector(
                key: ValueKey(widget.reel.id),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.6) {
                    c.play();
                  } else {
                    c.pause();
                  }
                },
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: size.width < size.height
                        ? BoxFit.cover
                        : BoxFit.fitWidth,
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: VideoPlayer(c),
                    ),
                  ),
                ),
              ),

              AnimatedOpacity(
                opacity: isUIVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ),
                 
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
