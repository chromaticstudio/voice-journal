//
//  Formatters.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/9/24.
//

import Foundation

struct FormatterUtils {
    static let shared = FormatterUtils()

    private init() {}
    
    // Date Formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()

    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if date >= calendar.date(byAdding: .day, value: -6, to: Date())! {
            dateFormatter.dateFormat = "EEEE"
        } else {
            dateFormatter.dateFormat = "EEEE, d MMM yyyy"
        }
        
        return dateFormatter.string(from: date)
    }
    
    func formatDayDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "'Today', d MMM yyyy"
        } else if calendar.isDateInYesterday(date) {
            dateFormatter.dateFormat = "'Yesterday', d MMM yyyy"
        } else {
            dateFormatter.dateFormat = "EEEE, d MMM yyyy"
        }
        
        return dateFormatter.string(from: date)
    }
    
    // Time and Duration Formatters
    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func formatDuration(_ duration: Double) -> String {
        let roundedDuration = ceil(duration)
        return formatter.string(from: TimeInterval(roundedDuration)) ?? "00:00"
    }

    func formattedTime(from timeInterval: TimeInterval) -> String {
        return formatter.string(from: timeInterval) ?? ""
    }
}
