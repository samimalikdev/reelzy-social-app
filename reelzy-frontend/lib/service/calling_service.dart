import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:shorts_app/screen/call/call_screen.dart';
import 'package:shorts_app/screen/widget/incoming_call.dart';

enum CallType { audio, video }

class CallingService extends GetxService {
  late IO.Socket socket;

  webrtc.RTCPeerConnection? _pc;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;

  final webrtc.RTCVideoRenderer localRenderer = webrtc.RTCVideoRenderer();
  final webrtc.RTCVideoRenderer remoteRenderer = webrtc.RTCVideoRenderer();

  bool _localRendererInitialized = false;
  bool _remoteRendererInitialized = false;

  String? myId;
  String? otherId;
  String? otherName;
  String? otherAvatar;

  final isRinging = false.obs;
  final isInCall = false.obs;

  final callType = CallType.audio.obs;
  CallType? incomingCallType;

  bool _eventsRegistered = false;

  void init({
    required IO.Socket sharedSocket,
    required String userId,
  }) {
    print('CallingService for user: $userId');
    
    if (myId != null && myId == userId) {
      print('CallingService already initialized');
      return;
    }
    
    socket = sharedSocket;
    myId = userId;
    
    if (!_eventsRegistered) {
      _registerEvents();
      _eventsRegistered = true;
    }
    
    print('CallingService initialized');
  }

  void _registerEvents() {
    print('Registering calling events');
    
    socket.off('call:incoming');
    socket.off('call:accepted');
    socket.off('call:offer');
    socket.off('call:answer');
    socket.off('call:ice');
    socket.off('call:end');
    
    socket.on('call:incoming', _onIncomingCall);
    socket.on('call:accepted', _onCallAccepted);
    socket.on('call:offer', _onOffer);
    socket.on('call:answer', _onAnswer);
    socket.on('call:ice', _onIce);
    socket.on('call:end', (_) => _cleanup());
    
    print('Calling events registered');
  }

  Future<void> _initWebRTC() async {
    if (callType.value == CallType.video) {
      if (!_localRendererInitialized) {
        await localRenderer.initialize();
        _localRendererInitialized = true;
      }
      if (!_remoteRendererInitialized) {
        await remoteRenderer.initialize();
        _remoteRendererInitialized = true;
      }
    }

    _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': callType.value == CallType.video
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
              'frameRate': 30,
            }
          : false,
    });

    if (callType.value == CallType.video) {
      localRenderer.srcObject = _localStream;
    }

    _pc = await webrtc.createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        socket.emit('call:ice', {
          'senderId': myId,
          'receiverId': otherId,
          'candidate': candidate.toMap(),
        });
      }
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (callType.value == CallType.video) {
          remoteRenderer.srcObject = _remoteStream;
        }
        isInCall.value = true;
        isRinging.value = false;
      }
    };
  }

  Future<void> _initLocalStreamOnly() async {
    if (callType.value == CallType.video) {
      if (!_localRendererInitialized) {
        await localRenderer.initialize();
        _localRendererInitialized = true;
      }
      
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': 640,
          'height': 480,
          'frameRate': 30,
        },
      });

      localRenderer.srcObject = _localStream;
    }
  }

  Future<void> startCall(
    String receiverId, {
    required String receiverName,
    String? receiverAvatar,
    required CallType type,
  }) async {
    if (myId == null) {
      print('CallingService not initialized');
      return;
    }
    
    if (receiverId == myId) return;

    callType.value = type;
    incomingCallType = type;

    otherId = receiverId;
    otherName = receiverName;
    otherAvatar = receiverAvatar;
    isRinging.value = true;

    final me = FirebaseAuth.instance.currentUser;

    socket.emit('call:start', {
      'callerId': myId,
      'receiverId': receiverId,
      'callerName': me?.displayName ?? 'User',
      'callerAvatar': me?.photoURL,
      'callType': type.name,
    });

    await _initWebRTC();

    Get.to(() => CallScreen(
          receiverId: receiverId,
          receiverName: receiverName,
          receiverImg: receiverAvatar,
          isIncoming: false,
        ));
  }

  Future<void> _onIncomingCall(data) async {
    otherId = data['callerId'];
    otherName = data['callerName'];
    otherAvatar = data['callerAvatar'];

    incomingCallType =
        data['callType'] == 'video' ? CallType.video : CallType.audio;
    callType.value = incomingCallType!;

    isRinging.value = true;

    if (callType.value == CallType.video) {
      await _initLocalStreamOnly();
    }

    Get.to(() => CallScreen(
          receiverId: otherId!,
          receiverName: otherName ?? 'User',
          receiverImg: otherAvatar,
          isIncoming: true,
        ));
  }

  Future<void> acceptCall() async {
    if (incomingCallType != null) {
      callType.value = incomingCallType!;
    }

    socket.emit('call:accept', {
      'callerId': otherId,
      'receiverId': myId,
      'callType': callType.value.name,
    });

    if (callType.value == CallType.video) {
      if (!_remoteRendererInitialized) {
        await remoteRenderer.initialize();
        _remoteRendererInitialized = true;
      }
      
      _pc = await webrtc.createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      });

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _pc!.addTrack(track, _localStream!);
        });
      }

      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          socket.emit('call:ice', {
            'senderId': myId,
            'receiverId': otherId,
            'candidate': candidate.toMap(),
          });
        }
      };

      _pc!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          remoteRenderer.srcObject = _remoteStream;
          isInCall.value = true;
          isRinging.value = false;
        }
      };
    } else {
      await _initWebRTC();
    }
  }

  Future<void> _onCallAccepted(data) async {
    if (data['callType'] != null) {
      callType.value =
          data['callType'] == 'video' ? CallType.video : CallType.audio;
    }

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    socket.emit('call:offer', {
      'callerId': myId,
      'receiverId': otherId,
      'offer': offer.toMap(),
    });
  }

  Future<void> _onOffer(data) async {
    final offer = data['offer'];

    await _pc!.setRemoteDescription(
      webrtc.RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    socket.emit('call:answer', {
      'callerId': otherId,
      'receiverId': myId,
      'answer': answer.toMap(),
    });
  }

  Future<void> _onAnswer(data) async {
    final answer = data['answer'];
    await _pc!.setRemoteDescription(
      webrtc.RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  Future<void> _onIce(data) async {
    final c = data['candidate'];
    if (_pc != null && c != null) {
      await _pc!.addCandidate(
        webrtc.RTCIceCandidate(
          c['candidate'],
          c['sdpMid'],
          c['sdpMLineIndex'],
        ),
      );
    }
  }

  void toggleMute(bool mute) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !mute);
  }

  void toggleSpeaker(bool on) {
    webrtc.Helper.setSpeakerphoneOn(on);
  }

  void switchCamera() {
    _localStream?.getVideoTracks().forEach(webrtc.Helper.switchCamera);
  }

  void endCall() {
    socket.emit('call:end', {
      'callerId': myId,
      'receiverId': otherId,
    });
    _cleanup();
  }

  void _cleanup() {
    print('Cleaning up call resources');
    
    _pc?.close();
    _pc = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    _remoteStream = null;

  
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}

    otherId = null;
    otherName = null;
    otherAvatar = null;
    incomingCallType = null;

    isInCall.value = false;
    isRinging.value = false;

    IncomingCallManager.hide();
    
    print('Call cleanup complete');
  }


  void reset() {
    print('esetting CallingService');
    
    _cleanup();

    socket.off('call:incoming');
    socket.off('call:accepted');
    socket.off('call:offer');
    socket.off('call:answer');
    socket.off('call:ice');
    socket.off('call:end');
    
    _eventsRegistered = false;

    // Reset myId
    myId = null;

    print('CallingService reset complete');
  }

  @override
  void onClose() {
    print('CallingService onClose called');
    
    _cleanup();
    
    try {
      if (_localRendererInitialized) {
        localRenderer.dispose();
        _localRendererInitialized = false;
      }
      if (_remoteRendererInitialized) {
        remoteRenderer.dispose();
        _remoteRendererInitialized = false;
      }
    } catch (_) {}
    
    super.onClose();
  }
}