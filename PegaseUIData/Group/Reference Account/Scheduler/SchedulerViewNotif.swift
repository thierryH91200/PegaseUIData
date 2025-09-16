//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 23/05/2025.
//

import AppKit
import SwiftUI
import UserNotifications

extension Notification.Name {
    static let didSelectScheduler = Notification.Name("didSelectScheduler")
}

// MARK: - NotificationManager
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                printTag("Notification permission error: \(error.localizedDescription)")
            } else {
                printTag("Notification permission granted: \(granted)")
            }
        }
    }
    
    func scheduleReminder(for scheduler: EntitySchedule) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Schedule"
        content.body = "Reminder: \(scheduler.libelle) is due soon."
        content.sound = .default
        
        let triggerDate = scheduler.dateValeur.addingTimeInterval(-86400) // 1 day before
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: scheduler.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder(for scheduler: EntitySchedule) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [scheduler.id.uuidString])
    }
}

struct UpcomingRemindersView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    let upcoming: [EntitySchedule]
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("🔔 Upcoming Reminders")
                .font(.headline)
            
            let filteredUpcoming = upcoming
                .filter { !$0.isProcessed && $0.dateValeur >= Calendar.current.startOfDay(for: Date()) }
                .sorted { $0.dateValeur < $1.dateValeur }
            
            if filteredUpcoming.isEmpty {
                Text("No scheduled operations.")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(filteredUpcoming) { item in
                        HStack {
                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: item.dateValeur).day ?? 0
                            let iconName = daysRemaining <= 1 ? "exclamationmark.triangle.fill" : "calendar"
                            let iconColor: Color = daysRemaining <= 1 ? .red : (daysRemaining <= 7 ? .orange : .green)
                            
                            Image(systemName: iconName)
                                .foregroundColor(iconColor)
                            
                            VStack(alignment: .leading) {
                                Text(item.libelle)
                                    .fontWeight(daysRemaining <= 1 ? .bold : .regular)
                                    .foregroundColor(daysRemaining <= 1 ? .red : .primary)
                                
                                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: item.dateValeur).day ?? 0
                                
                                let relativeLabel: String = {
                                    switch daysRemaining {
                                    case 0:
                                        return "Aujourd’hui"
                                    case 1:
                                        return "Demain"
                                    case 2...6:
                                        return "Dans \(daysRemaining) jours"
                                    default:
                                        return ""
                                    }
                                }()
                                if !relativeLabel.isEmpty {
                                    Text(relativeLabel)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Date : \(dateFormatter.string(from: item.dateValeur))")
                                        .font(.caption)
                                    .foregroundColor(daysRemaining <= 1 ? .red : (daysRemaining <= 3 ? .orange : .secondary))                            }
                                Spacer()
                                
                                Text(String(format: "%.2f", item.amount))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onAppear {
                        for entitySchedule in upcoming {
                            SchedulerManager.shared.createTransaction(entitySchedule: entitySchedule)
                            NotificationManager.shared.cancelReminder(for: entitySchedule)
                            entitySchedule.isProcessed = true
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
        
        
