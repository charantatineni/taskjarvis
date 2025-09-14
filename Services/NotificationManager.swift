//
//  NotificationManager.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//

import Foundation
import UserNotifications
import AVFoundation
import SwiftUI

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var activeAlarmTint: Color? = nil   // for full-screen sheet tint
    private var player: AVAudioPlayer?

    private override init() { super.init() }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Show alert while app in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) // still show banner + play sound
        // Also show our in-app full-screen alarm sheet tinted by label color (carried in userInfo)
        if let hex = notification.request.content.userInfo["labelHex"] as? String,
           let tint = Color(hex: hex) {
            DispatchQueue.main.async {
                self.activeAlarmTint = tint
                self.playInAppAlarm()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.activeAlarmTint = nil
                    self.stopInAppAlarm()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.activeAlarmTint = .black
                self.playInAppAlarm()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.activeAlarmTint = nil
                    self.stopInAppAlarm()
                }
            }
        }
    }

    private func playInAppAlarm() {
        guard let url = Bundle.main.url(forResource: "alarm2s", withExtension: "caf") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { print("Audio error: \(error)") }
    }

    private func stopInAppAlarm() {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

