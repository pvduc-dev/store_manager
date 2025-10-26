import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Only configure Firebase if it hasn't been configured yet
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
