//
//  WeatherInfo.swift
//  Weather
//
//  Created by RuslanKa on 09.03.2018.
//

import Foundation

class WeatherInfo {
    let temperature: Double
    
    init(temperature: Double) {
        self.temperature = temperature
    }
    
    var description: String {
        get {
            return "\(temperature.rounded().description) °C"
        }
    }
    
}
