//
//  ApiManager.swift
//  Weather
//
//  Created by RuslanKa on 13.03.2018.
//

import Foundation

class ApiManager {
    
    private static let googleAPIKey = "AIzaSyCtmhu0qIk0F57qPFKDTei_6HWc1PCXVhw"
    private static let darkSkyAPI = "c7e47ce403b6eec0c6a2d5be9830fc90"
    
    static func getWeatherWithDarkSky(latitude: Double, longitude: Double, completion: @escaping (_ weatherData: [Dictionary<String, Any>]) -> Void) {
        let urlString = "https://api.darksky.net/forecast/\(darkSkyAPI)/\(latitude),\(longitude)"
        let url = URL(string: urlString)
        let sessionTask = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if let error = error {
                print("Couldn't get weather. \(error)")
            } else {
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Dictionary<String, Any> else { return }
                guard let hourlyData = (jsonObject!["hourly"] as? Dictionary<String, Any>)!["data"] as? [Dictionary<String, Any>] else { return }
                completion(hourlyData)
            }
        }
        sessionTask.resume()
    }
    
    static func getCity(latitude: Double, longitude: Double, completion: @escaping (_ city: String, _ country: String) -> Void) {
        var countryCode: String?
        var cityName: String?
        let googleMapsUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=\(googleAPIKey)")!
        let task = URLSession.shared.dataTask(with: googleMapsUrl) { (data, response, error) in
            if let error = error {
                print("Couldn't get city. \(error)")
            } else {
                if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Dictionary<String, Any> {
                    if let results = jsonObj?["results"] as? [Dictionary<String, Any>] {
                        if let addressComponents = results[0]["address_components"] as? [Dictionary<String, Any>] {
                            for component in addressComponents {
                                if let types = component["types"] as? [String] {
                                    if types.contains("country") {
                                        countryCode = component["short_name"] as? String
                                    }
                                    if types.contains("locality") {
                                        cityName = component["short_name"] as? String
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if let countryCode = countryCode, let cityName = cityName {
                completion(cityName, countryCode)
            }
        }
        task.resume()
    }
    
}
