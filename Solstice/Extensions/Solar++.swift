//
//  Solar+safety.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import Foundation
import Solar

extension Solar {
	var fallbackSunrise: Date? {
		sunrise ?? civilSunrise ?? nauticalSunrise ?? astronomicalSunrise
	}
	
	var fallbackSunset: Date? {
		sunset ?? civilSunset ?? nauticalSunset ?? astronomicalSunset
	}
	
	var safeSunrise: Date {
		sunrise ?? startOfDay
	}
	
	var safeSunset: Date {
		if let sunset {
			return sunset
		}
		
		guard let fallbackSunset,
					let fallbackSunrise else {
			return endOfDay
		}
		
		if fallbackSunrise.distance(to: fallbackSunset) > (60 * 60 * 7) {
			return endOfDay
		} else {
			return startOfDay.addingTimeInterval(0.1)
		}
	}
	
	var daylightDuration: TimeInterval {
		(fallbackSunrise ?? safeSunrise).distance(to: (fallbackSunset ?? safeSunset))
	}
	
	var peak: Date {
		(fallbackSunrise ?? safeSunrise).addingTimeInterval(abs(daylightDuration) / 2)
	}
	
	var yesterday: Solar {
		let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(60 * 60 * 24 - 1)
		return Solar(for: yesterdayDate, coordinate: coordinate)!
	}
	
	var differenceString: String {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .medium
		formatter.formattingContext = .middleOfSentence
		
		let comparator = date.isToday ? yesterday : Solar(coordinate: self.coordinate)!
		var string = (daylightDuration - comparator.daylightDuration).localizedString
		
		if daylightDuration - comparator.daylightDuration >= 0 {
			string += " more"
		} else {
			string += " less"
		}
		
		// Check if the base date formatted as a string contains numbers.
		// If it does, this means it's presented as an absolute date, and should
		// be rendered as “on {date}”; if not, it’s presented as a relative date,
		// and should be presented as “{yesterday/today/tomorrow}”
		let baseDateString = formatter.string(from: date)
		let decimalCharacters = CharacterSet.decimalDigits
		let decimalRange = baseDateString.rangeOfCharacter(from: decimalCharacters)
		
		let comparatorDate = comparator.date
		let comparatorDateString = formatter.string(from: comparatorDate)
		
		string += " daylight \(decimalRange == nil ? "" : "on ")\(baseDateString) compared to \(comparatorDateString)."
		
		return string
	}
	
	var nextSolarEvent: Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
		?? tomorrow?.events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
	}
	
	var previousSolarEvent: Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
		?? yesterday.events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
	}
	
	var tomorrow: Solar? {
		guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else {
			return nil
		}
		
		return Solar(for: tomorrow, coordinate: coordinate)
	}
}
