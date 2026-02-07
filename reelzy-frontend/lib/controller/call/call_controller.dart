import 'dart:async';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get/instance_manager.dart';
import 'package:shorts_app/service/calling_service.dart';

class CallController extends GetxController {
  final CallingService _callingService = Get.find<CallingService>();

  final isCallActive = false.obs;
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final callDuration = 0.obs;
  final isIncoming = false.obs;

  final displayName = ''.obs;
  final displayAvatar = ''.obs;

  Timer? _durationTimer;

  @override
  void onInit() {
    super.onInit();
    ever(_callingService.isInCall, (bool inCall) {
      if (inCall) {
        isCallActive.value = true;
        _startDurationTimer();
      } else {
        isCallActive.value = false;
        _stopDurationTimer();
      }
    });
  }

  void setCallInfo({
    required bool incoming,
    required String name,
    required String avatar,
  }) {
    isIncoming.value = incoming;
    displayName.value = name;
    displayAvatar.value = avatar;
  }

  void _startDurationTimer() {
    callDuration.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String get formattedDuration {
    final m = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final s = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _callingService.toggleMute(isMuted.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    _callingService.toggleSpeaker(isSpeakerOn.value);
  }

  Future<void> acceptCall() async {
    await _callingService.acceptCall();
    isIncoming.value = false;
  }

  void rejectCall() {
    _callingService.endCall();
    Get.back();
  }

  void endCall() {
    _callingService.endCall();
    Get.back();
  }
}