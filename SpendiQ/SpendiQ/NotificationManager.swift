import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()

    private init() {} // Singleton

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permiso para notificaciones concedido.")
            } else {
                print("Permiso para notificaciones denegado.")
            }
        }
    }
}
