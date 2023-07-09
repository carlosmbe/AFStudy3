//
//  DraftAFStudy3App.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-13.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct DraftAFStudy3App: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
           WindowGroup {
                   NavigationView {
                       if Auth.auth().currentUser != nil {
                           ChatView()
                       } else {
                           ContentView()
                       }
                   }
               }
           }
       }
   
