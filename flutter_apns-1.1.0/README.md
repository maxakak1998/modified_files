# apns

Plugin to implement APNS push notifications on iOS and Firebase on Android. 

## Why this plugin was made?

Currently, the only available push notification plugin is `firebase_messaging`. This means that, even on iOS, you will need to setup firebase and communicate with Google to send push notification. This plugin solves the problem by providing native APNS implementation while leaving configured Firebase for Android.

## Usage
1. Configure firebase on Android according to instructions: https://pub.dartlang.org/packages/firebase_messaging.
2. On iOS, make sure you have correctly configured your app to support push notifications, and that you have generated certificate/token for sending pushes.
3. Add `flutter_apns` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).
4. Using `createPushConnector()` method, configure push service according to your needs. `PushConnector` closely resembles `FirebaseMessaging`, so Firebase samples may be useful during implementation.
```dart
import 'package:flutter_apns/apns.dart';

final connector = createPushConnector();
connector.configure(
    onLaunch: _onLaunch,
    onResume: _onResume,
    onMessage: _onMessage,
);
connector.requestNotificationPermissions()
```
5. Build on device and test your solution using Firebase Console and NWPusher app.

## Troubleshooting

1. Ensure that you are on actual devices. NOTE: this may not be needed from 11.4: https://ohmyswift.com/blog/2020/02/13/simulating-remote-push-notifications-in-a-simulator/
2. If onToken method is not being called, add error logging to your AppDelegate, for example:

*swift*
```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
     NSLog("PUSH registration failed: \(error)")
    findDependency(\.userData).newPushToken = .waitingForUpload(nil)
  }
}

```

*objc*
```objc
#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@", error);
}

@end
```