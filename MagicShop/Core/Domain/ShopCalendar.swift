import Foundation

public enum ShopWeekday: Int, CaseIterable, Codable, Sendable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    public var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

/// A fictional calendar driven solely by committed visitor transactions.
/// Preparing takes no time; backgrounding never earns income or skips hours.
public struct ShopCalendar: Equatable, Sendable {
    public static let openingMinute = 9 * 60
    public static let closingMinute = 18 * 60
    public let dayNumber: Int
    public let minutesSinceMidnight: Int

    public init(dayNumber: Int, processedVisits: Int = 0) {
        self.dayNumber = max(1, dayNumber)
        let cursor = min(max(0, processedVisits), ShopDayState.visitorCount)
        minutesSinceMidnight = Self.openingMinute +
            (Self.closingMinute - Self.openingMinute) * cursor / ShopDayState.visitorCount
    }

    public init(dayNumber: Int, minute: Int) {
        self.dayNumber = max(1, dayNumber)
        minutesSinceMidnight = min(max(minute, Self.openingMinute), Self.closingMinute)
    }

    public var weekday: ShopWeekday {
        ShopWeekday(rawValue: (dayNumber - 1) % 7) ?? .monday
    }
    public var weekdayName: String { weekday.displayName }
    public var timeText: String {
        String(format: "%02d:%02d", minutesSinceMidnight / 60, minutesSinceMidnight % 60)
    }
}

extension GameState {
    public var calendar: ShopCalendar {
        if let day = livingDay { return ShopCalendar(dayNumber: day.dayNumber, minute: day.minute) }
        if let day = currentDay {
            return ShopCalendar(dayNumber: day.dayNumber, processedVisits: day.nextVisitIndex)
        }
        return ShopCalendar(dayNumber: completedDays + 1)
    }
}

extension ShopDayState {
    public var calendar: ShopCalendar {
        ShopCalendar(dayNumber: dayNumber, processedVisits: nextVisitIndex)
    }
    public var minutesSinceMidnight: Int { calendar.minutesSinceMidnight }
}

extension CustomerVisit {
    public var scheduledMinute: Int {
        ShopCalendar(dayNumber: 1, processedVisits: id.index).minutesSinceMidnight
    }
}

extension DaySummary {
    public var weekdayName: String { ShopCalendar(dayNumber: dayNumber).weekdayName }
}
