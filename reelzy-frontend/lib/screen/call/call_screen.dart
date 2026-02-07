import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/call/call_controller.dart';
import 'package:shorts_app/service/calling_service.dart';



class CallScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverImg;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImg,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallingService service;

  @override
  void initState() {
    super.initState();
    service = Get.find<CallingService>();
  }

  @override
  void dispose() {

    if (service.callType.value == CallType.video) {
      try {
        service.localRenderer.srcObject = null;
        service.remoteRenderer.srcObject = null;
      } catch (_) {}
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CallController());
    final service = Get.find<CallingService>();

    controller.setCallInfo(
      incoming: widget.isIncoming,
      name: widget.receiverName,
      avatar: widget.receiverImg ?? 'https://i.pravatar.cc/150',
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: SafeArea(
          child: Obx(() {
            if (service.callType.value == CallType.video) {
              return _buildVideoCallUI(controller, service);
            }
            return _buildAudioCallUI(controller);
          }),
        ),
      ),
    );
  }

  Widget _buildVideoCallUI(
      CallController controller, CallingService service) {
    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() {
            if (controller.isIncoming.value || !controller.isCallActive.value) {
              return Container(
                color: const Color(0xFF1a1a2e),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(controller.displayAvatar.value),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        controller.displayName.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.isIncoming.value
                            ? 'Incoming Video Call...'
                            : 'Calling...',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return RTCVideoView(
              service.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            );
          }),
        ),

        Positioned(
          top: 40,
          right: 16,
          width: 120,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black26,
              child: RTCVideoView(
                service.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        ),

        Positioned(
          top: 40,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Video Call',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Obx(() {
              if (controller.isIncoming.value) {
                return _buildIncomingVideoControls(controller);
              }
              return _buildActiveVideoControls(controller, service);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingVideoControls(CallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _callBtn(Icons.call_end, Colors.red, controller.rejectCall, size: 70),
        _callBtn(Icons.videocam, Colors.green, controller.acceptCall, size: 70),
      ],
    );
  }

  Widget _buildActiveVideoControls(
      CallController controller, CallingService service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ctrlBtn(
          controller.isMuted.value ? Icons.mic_off : Icons.mic,
          controller.toggleMute,
          isActive: controller.isMuted.value,
        ),
        _ctrlBtn(
          Icons.cameraswitch,
          service.switchCamera,
        ),
        _callBtn(
          Icons.call_end,
          Colors.red,
          controller.endCall,
          size: 70,
        ),
      ],
    );
  }

  Widget _buildAudioCallUI(CallController controller) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Voice Call',
          style: TextStyle(color: Colors.white70),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 70,
          backgroundImage: NetworkImage(controller.displayAvatar.value),
        ),
        const SizedBox(height: 20),
        Text(
          controller.displayName.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        _buildStatusText(controller),
        const Spacer(),
        controller.isIncoming.value
            ? _buildIncomingControls(controller)
            : _buildActiveCallControls(controller),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatusText(CallController controller) {
    if (controller.isIncoming.value) {
      return const Text('Incoming call...',
          style: TextStyle(color: Colors.white70));
    }
    if (controller.isCallActive.value) {
      return Text(controller.formattedDuration,
          style: const TextStyle(color: Colors.white, fontSize: 18));
    }
    return const Text('Calling...',
        style: TextStyle(color: Colors.white70));
  }

  Widget _buildIncomingControls(CallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _callBtn(Icons.call_end, Colors.red, controller.rejectCall),
        _callBtn(Icons.call, Colors.green, controller.acceptCall),
      ],
    );
  }

  Widget _buildActiveCallControls(CallController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ctrlBtn(
              controller.isMuted.value ? Icons.mic_off : Icons.mic,
              controller.toggleMute,
              isActive: controller.isMuted.value,
            ),
            _ctrlBtn(
              controller.isSpeakerOn.value
                  ? Icons.volume_up
                  : Icons.volume_down,
              controller.toggleSpeaker,
              isActive: controller.isSpeakerOn.value,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _callBtn(Icons.call_end, Colors.red, controller.endCall, size: 70),
      ],
    );
  }

  static Widget _ctrlBtn(IconData icon, VoidCallback onTap,
      {bool isActive = false}) {
    return Material(
      color: isActive
          ? Colors.white.withOpacity(0.3)
          : Colors.white.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  static Widget _callBtn(IconData icon, Color color, VoidCallback onTap,
      {double size = 60}) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}