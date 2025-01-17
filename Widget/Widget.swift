//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 19/02/2023.
//

import WidgetKit
import SwiftUI
import Intents
import Solar

enum SolsticeWidgetKind: String {
	case CountdownWidget, OverviewWidget
}

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation
	var relevance: TimelineEntryRelevance? = nil
}

struct SolsticeOverviewWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Overview")
		]
	}
}

struct SolsticeCountdownWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Countdown")
		]
	}
}

protocol SolsticeWidgetTimelineProvider: IntentTimelineProvider where Entry == SolsticeWidgetTimelineEntry, Intent == ConfigurationIntent {
	var currentLocation: CurrentLocation { get }
	var geocoder: CLGeocoder { get }
}

extension SolsticeWidgetTimelineProvider {
	func getLocation(for placemark: CLPlacemark? = nil, isRealLocation: Bool = false) -> SolsticeWidgetLocation {
		return SolsticeWidgetLocation(title: placemark?.locality,
																	subtitle: placemark?.country,
																	timeZoneIdentifier: placemark?.timeZone?.identifier,
																	latitude: placemark?.location?.coordinate.latitude ?? currentLocation.latestLocation?.coordinate.latitude ?? SolsticeWidgetLocation.defaultLocation.latitude,
																	longitude: placemark?.location?.coordinate.longitude ?? currentLocation.latestLocation?.coordinate.longitude ?? SolsticeWidgetLocation.defaultLocation.longitude,
																	isRealLocation: isRealLocation)
	}
	
	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		var isRealLocation = false
		
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.last,
						error == nil else {
				return completion(SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			}
			
			let location = getLocation(for: placemark, isRealLocation: isRealLocation)
			let entry = SolsticeWidgetTimelineEntry(date: Date(), location: location)
			return completion(entry)
		}
		
		if let configurationLocation = configuration.location?.location {
			geocoder.reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			if currentLocation.latestLocation != nil {
				completion(SolsticeWidgetTimelineEntry(date: Date(), location: getLocation(isRealLocation: true)))
			} else {
				currentLocation.requestLocation { location in
					guard let location else { return }
					isRealLocation = true
					geocoder.reverseGeocodeLocation(location, completionHandler: handler)
				}
			}
		}
	}
	
	func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SolsticeWidgetTimelineEntry>) -> Void) {
		var isRealLocation = false
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.last,
						error == nil else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let location = getLocation(for: placemark, isRealLocation: isRealLocation)
			
			var entries: [SolsticeWidgetTimelineEntry] = []
			
			guard let solar = Solar(coordinate: location.coordinate) else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let currentDate = Date()
			let distanceToSunrise = abs(currentDate.distance(to: solar.safeSunrise))
			let distanceToSunset = abs(currentDate.distance(to: solar.safeSunset))
			let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
			let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
			? .init(score: 10, duration: nearestEventDistance)
			: nil
			
			var nextUpdateDate = currentDate.addingTimeInterval(60 * 15)
			
			if nextUpdateDate < solar.safeSunrise {
				nextUpdateDate = solar.safeSunrise
			} else if nextUpdateDate < solar.safeSunset {
				nextUpdateDate = solar.safeSunset
			}
			
			entries.append(
				SolsticeWidgetTimelineEntry(
					date: currentDate,
					location: location,
					relevance: relevance
				)
			)
			
			let timeline = Timeline(
				entries: entries,
				policy: .after(nextUpdateDate)
			)
			
			completion(timeline)
		}
		
		if let configurationLocation = configuration.location?.location {
			geocoder.reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			if let location = currentLocation.latestLocation {
				isRealLocation = true
				geocoder.reverseGeocodeLocation(location, completionHandler: handler)
			} else {
				currentLocation.requestLocation { location in
					guard let location else { return }
					isRealLocation = true
					geocoder.reverseGeocodeLocation(location, completionHandler: handler)
				}
			}
		}
	}
	
	func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
		SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation)
	}
}
