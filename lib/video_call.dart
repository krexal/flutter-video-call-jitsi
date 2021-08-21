import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jitsi_meet/jitsi_meet.dart';

class VideoCall extends StatefulWidget {
  VideoCall({Key? key}) : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  var meetingCodeController = TextEditingController();
  var meetingCode = "";

  @override
  void initState() {
    JitsiMeet.addListener(JitsiMeetingListener(
      onConferenceWillJoin: _onConferenceWillJoin,
      onConferenceJoined: _onConferenceJoined,
      onConferenceTerminated: _onConferenceTerminated,
      onError: _onError,
    ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Column(
                children: [
                  Card(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: meetingCodeController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            return value!.isEmpty ? "Code Required" : null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: SizedBox(
                            child: MaterialButton(
                              textColor: Colors.red,
                              splashColor: Colors.grey.withOpacity(0.2),
                              padding: EdgeInsets.only(
                                top: 15,
                                bottom: 15,
                                left: 20,
                                right: 20,
                              ),
                              child: Text("Join Meeting"),
                              shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                              onPressed: () {
                                print("join meeting pressed");
                                print(meetingCodeController.text);
                                joinMeeting();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  SizedBox(
                    height: 70,
                  ),
                  Card(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              meetingCode,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 24,
                              ),
                            ),
                            Visibility(
                              visible: meetingCode.isNotEmpty,
                              child: TextButton.icon(
                                icon: Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Copy Code",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  copyMeetingCode(context);
                                },
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.blueGrey),
                                  elevation: MaterialStateProperty.all(5),
                                  padding:
                                      MaterialStateProperty.all(EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 15,
                                    bottom: 15,
                                  )),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white24),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            child: MaterialButton(
                              textColor: Colors.red,
                              splashColor: Colors.grey.withOpacity(0.2),
                              padding: EdgeInsets.only(
                                top: 15,
                                bottom: 15,
                                left: 20,
                                right: 20,
                              ),
                              child: Text("Create Meeting Code"),
                              shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              onPressed: () {
                                print("create meeting code clicked");
                                createCode();
                              },
                            ),
                          ),
                        ),
                      ],
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

  void createCode() {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    var code =
        List.generate(8, (index) => _chars[r.nextInt(_chars.length)]).join();
    setState(() {
      meetingCode = code;
    });
  }

  copyMeetingCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: meetingCode)).then((value) {
      final snackBar = SnackBar(content: Text('Meeting Code Copied!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  joinMeeting() async {
    if (meetingCodeController.text.isNotEmpty) {
      try {
        // Enable or disable any feature flag here
        // If feature flag are not provided, default values will be used
        // Full list of feature flags (and defaults) available in the README
        Map<FeatureFlagEnum, bool> featureFlags = {
          FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
        };

        if (!kIsWeb) {
          // Here is an example, disabling features for each platform
          if (Platform.isAndroid) {
            // Disable ConnectionService usage on Android to avoid issues (see README)
            featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
          } else if (Platform.isIOS) {
            // Disable PIP on iOS as it looks weird
            featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
          }
        }
        // Define meetings options here
        var options = JitsiMeetingOptions(room: meetingCode)
          ..serverURL = null
          ..subject = "Subject Here"
          ..userDisplayName = "Username"
          ..userEmail = "user email"
          ..iosAppBarRGBAColor = null
          ..audioOnly = false
          ..audioMuted = true
          ..videoMuted = false
          ..featureFlags.addAll(featureFlags)
          ..webOptions = {
            "roomName": meetingCode,
            "width": "100%",
            "height": "100%",
            "enableWelcomePage": false,
            "chromeExtensionBanner": null,
            "userInfo": {"displayName": "user name"}
          };

        debugPrint("JitsiMeetingOptions: $options");
        await JitsiMeet.joinMeeting(
          options,
          listener: JitsiMeetingListener(
            onConferenceWillJoin: (message) {
              debugPrint("${options.room} will join with message: $message");
            },
            onConferenceJoined: (message) {
              debugPrint("${options.room} joined with message: $message");
            },
            onConferenceTerminated: (message) {
              debugPrint("${options.room} terminated with message: $message");
            },
            genericListeners: [
              JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                },
              ),
            ],
          ),
        );
      } catch (e) {
        print(e.toString());
      }
    }
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined(message) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }
}
