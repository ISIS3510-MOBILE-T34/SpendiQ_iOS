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

    func scheduleTestMessage() {
        let content = UNMutableNotificationContent()
        content.title = "Nuevo Mensaje"
        content.body = "Notificacion de prueba"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (60*5), repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al enviar la notificación: \(error.localizedDescription)")
            }
        }
    }
}
