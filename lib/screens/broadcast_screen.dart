import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming/config/appid.dart';
import 'package:live_streaming/firebase/firestore_methods.dart';
import 'package:live_streaming/responsive/resonsive_layout.dart';
import 'package:live_streaming/screens/home_page.dart';
import 'package:live_streaming/widgets/custom_button.dart';
import 'package:permission_handler/permission_handler.dart';

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;
  const BroadcastScreen({
    Key? key,
    required this.isBroadcaster,
    required this.channelId,
  }) : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool switchCamera = true;
  bool isMuted = false;
  bool isScreenSharing = false;
  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _addListeners();

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster) {
      _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      _engine.setClientRole(ClientRole.Audience);
    }
    _joinChannel();
  }

  String baseUrl = "https://live-streaming-app-server.herokuapp.com";

  String? token;

  Future<void> getToken() async {
    final res = await http.get(
      Uri.parse(baseUrl +
          '/rtc/' +
          widget.channelId +
          '/publisher/userAccount/' +
          FirebaseAuth.instance.currentUser!.uid +
          '/'),
    );

    if (res.statusCode == 200) {
      setState(() {
        token = res.body;
        token = jsonDecode(token!)['rtcToken'];
      });
    } else {
      debugPrint('Failed to fetch the token');
    }
  }

  void _addListeners() {
    _engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      debugPrint('joinChannelSuccess $channel $uid $elapsed');
    }, userJoined: (uid, elapsed) {
      debugPrint('userJoined $uid $elapsed');
      setState(() {
        remoteUid.add(uid);
      });
    }, userOffline: (uid, reason) {
      debugPrint('userOffline $uid $reason');
      setState(() {
        remoteUid.removeWhere((element) => element == uid);
      });
    }, leaveChannel: (stats) {
      debugPrint('leaveChannel $stats');
      setState(() {
        remoteUid.clear();
      });
    }, tokenPrivilegeWillExpire: (token) async {
      await getToken();
      await _engine.renewToken(token);
    }));
  }

  void _joinChannel() async {
    await getToken();
    if (token != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await [Permission.microphone, Permission.camera].request();
      }
      await _engine.joinChannelWithUserAccount(
        token,
        widget.channelId,
        FirebaseAuth.instance.currentUser!.uid,
      );
    }
  }

  void _switchCamera() {
    _engine.switchCamera().then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    }).catchError((err) {
      debugPrint('switchCamera $err');
    });
  }

  void onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    await _engine.muteLocalAudioStream(isMuted);
  }

  // _startScreenShare() async {
  //   final helper = await _engine.getScreenShareHelper(
  //       appGroup: kIsWeb || Platform.isWindows ? null : 'io.agora');
  //   await helper.disableAudio();
  //   await helper.enableVideo();
  //   await helper.setChannelProfile(ChannelProfile.LiveBroadcasting);
  //   await helper.setClientRole(ClientRole.Broadcaster);
  //   var windowId = 0;
  //   var random = Random();
  //   if (!kIsWeb &&
  //       (Platform.isWindows || Platform.isMacOS || Platform.isAndroid)) {
  //     final windows = _engine.enumerateWindows();
  //     if (windows.isNotEmpty) {
  //       final index = random.nextInt(windows.length - 1);
  //       debugPrint('Screensharing window with index $index');
  //       windowId = windows[index].id;
  //     }
  //   }
  //   await helper.startScreenCaptureByWindowId(windowId);
  //   setState(() {
  //     isScreenSharing = true;
  //   });
  //   await helper.joinChannelWithUserAccount(
  //     token,
  //     widget.channelId,
  //     FirebaseAuth.instance.currentUser!.uid,
  //   );
  // }

  // _stopScreenShare() async {
  //   final helper = await _engine.getScreenShareHelper();
  //   await helper.destroy().then((value) {
  //     setState(() {
  //       isScreenSharing = false;
  //     });
  //   }).catchError((err) {
  //     debugPrint('StopScreenShare $err');
  //   });
  // }

  _leaveChannel() async {
    await _engine.leaveChannel();
    if ('${FirebaseAuth.instance.currentUser!.uid}${FirebaseAuth.instance.currentUser!.displayName}' ==
        widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updateViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, HomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: CustomButton(
                  text: 'End Stream',
                  onTap: _leaveChannel,
                ),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ResponsiveLatout(
            desktopBody: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _renderVideo(isScreenSharing),
                      if ("${FirebaseAuth.instance.currentUser!.uid}${FirebaseAuth.instance.currentUser!.displayName}" ==
                          widget.channelId)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _switchCamera,
                              child: const Icon(
                                Icons.cameraswitch,
                              ),
                            ),
                            InkWell(
                              onTap: onToggleMute,
                              child: Text(isMuted ? 'Unmute' : 'Mute'),
                            ),
                            // InkWell(
                            //   onTap: isScreenSharing
                            //       ? _stopScreenShare
                            //       : _startScreenShare,
                            //   child: Text(
                            //     isScreenSharing
                            //         ? 'Stop ScreenSharing'
                            //         : 'Start Screensharing',
                            //   ),
                            // ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            mobileBody: Column(
              children: [
                _renderVideo(isScreenSharing),
                if ("${FirebaseAuth.instance.currentUser!.uid}${FirebaseAuth.instance.currentUser!.displayName}" ==
                    widget.channelId)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: _switchCamera,
                        child: const Icon(
                          Icons.cameraswitch,
                          size: 50,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: onToggleMute,
                        child: Text(
                          isMuted ? 'Unmute' : 'Mute',
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(isScreenSharing) {
    return AspectRatio(
      aspectRatio: 7 / 9,
      child:
          "${FirebaseAuth.instance.currentUser!.uid}${FirebaseAuth.instance.currentUser!.displayName}" ==
                  widget.channelId
              ? isScreenSharing
                  ? kIsWeb
                      ? const RtcLocalView.SurfaceView.screenShare()
                      : const RtcLocalView.TextureView.screenShare()
                  : const RtcLocalView.SurfaceView(
                      zOrderMediaOverlay: true,
                      zOrderOnTop: true,
                    )
              : isScreenSharing
                  ? kIsWeb
                      ? const RtcLocalView.SurfaceView.screenShare()
                      : const RtcLocalView.TextureView.screenShare()
                  : remoteUid.isNotEmpty
                      ? kIsWeb
                          ? RtcRemoteView.SurfaceView(
                              uid: remoteUid[0],
                              channelId: widget.channelId,
                            )
                          : RtcRemoteView.TextureView(
                              uid: remoteUid[0],
                              channelId: widget.channelId,
                            )
                      : Container(),
    );
  }
}
