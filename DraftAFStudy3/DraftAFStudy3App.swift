//
//  DraftAFStudy3App.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-13.
//
import SwiftUI
import Firebase
import UserNotifications


@main
struct DraftAFStudy3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var viewModel = SurveyViewModel()
    
    @StateObject var chatViewModel = ChatViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showSurveyAlert = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if Auth.auth().currentUser != nil {
                    if viewModel.isEligibleForChat == true {
                        ChatView()
                    } else {
                        ChatView() //Delete later
                        //TODO: Uncomment After Choosing Chat Bot Style
//                        Survey()
//                            .onAppear(perform: {
//                                showSurveyAlert = true
//                            })
//                            .alert(isPresented: $showSurveyAlert) {
//                                Alert(title: Text("Reminder"),
//                                      message: Text("Please complete the survey to access the chat."),
//                                      dismissButton: .default(Text("OK")))
//                            }
                    }
                } else {
                    SignUpView()
                }
            }
            .environmentObject(chatViewModel)
            .onChange(of: scenePhase) { newPhase in
                      if newPhase == .active {
                          viewModel.checkChatEligibility()
                      }
                  }
        }
    }
}




class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self

        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }

      print(userInfo)

      completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

      let deviceToken:[String: String] = ["token": fcmToken ?? ""]
        print("Device token: ", deviceToken) // This token can be used for testing notifications on FCM
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo

    if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
    }

    print(userInfo)

    // Change this to your preferred presentation option
    completionHandler([[.banner, .badge, .sound]])
  }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

    }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID from userNotificationCenter didReceive: \(messageID)")
    }

    print(userInfo)

    completionHandler()
  }
}
