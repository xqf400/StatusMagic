//
//  Weather+Date.swift
//  StatusMagic
//
//  Created by XQF on 04.03.23.
//

import Foundation


private let apiKey = "a6b243f000737fa523434d1e8fc4d1a7"

// MARK: - OpenWeather URLs

let dailyUrl = "https://api.openweathermap.org/data/2.5/weather?&appid=\(apiKey)&units=metric&lang=en"


struct DailyWeatherMain: Codable {
    let temp: Double
    let feels_like: Double
    let humidity: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
}

struct DailyWeather: Codable {
    let main: DailyWeatherMain
    let name: String
    let weather: [WeatherDescription]
    let wind: Wind
    let visibility: Int
}
struct WeatherDescription: Codable {
    let description: String
    let id: Int
}

// MARK: - Wind
struct Wind: Codable {
    let speed: Double
}

struct DailyWeatherModel {
    let cityName: String
    let temperature: String
    let description: String
    let maxTemp: String
    let minTemp: String
    let feelsLike: Double
    let humidity: Double
    let id: String
    let visibility: Int
    let pressure: Int
    let windSpeed: Double
    var minMaxTemp: String {
        return "Маx. \(maxTemp), Min. \(minTemp)"
    }
}


func fetchWeather (lat: Double, lon: Double, success: @escaping (_ str: String) -> Void, failure: @escaping (_ error: String) -> Void){
    let locatedDailyUrl = URL(string: dailyUrl + "&lon=\(lon)&lat=\(lat)")
    let session = URLSession.shared
    let request = URLRequest(url: locatedDailyUrl!)
          
     let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
         guard error == nil else {
             return
         }
         guard let data = data else {
             return
         }
              
        do {
            let weather = try JSONDecoder().decode(DailyWeather.self, from: data)
            let temp = Double(round(10 * weather.main.temp) / 10)
            let tempStr = "\(temp) Grad"
            success(tempStr)
        } catch let error {
          print("error ",error.localizedDescription)
            failure(error.localizedDescription)
        }
     })
     task.resume()
}


func setTimeSeconds() {
    let calendar = Calendar.current
    let date = Date()
    let hour = calendar.component(.hour, from: date)
    let hourFinal = UserDefaults.standard.bool(forKey: "Time24Hour") ? hour : (hour%12 == 0 ? 12 : hour%12)
    let minutes = calendar.component(.minute, from: date)
    let seconds = calendar.component(.second, from: date)
    
    let newStr: String = "\(hourFinal):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    
    if newStr.utf8CString.count <= 64 {
        StatusManager.sharedInstance().setTime(newStr)
    } else {
        StatusManager.sharedInstance().setTime("Length Error")
    }
}


func setCrumbDate() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM"
    
    let newStr: String = dateFormatter.string(from: Date())
    
    if (newStr + " ▶").utf8CString.count <= 256 {
        StatusManager.sharedInstance().setCrumb(newStr)
    } else {
        StatusManager.sharedInstance().setCrumb("Length Error")
    }
}
func setCrumbWeather() {
    var locationDataManager = LocationManager()
    guard let lat = locationDataManager.locationManager.location?.coordinate.latitude else {
        return
    }
    guard let long = locationDataManager.locationManager.location?.coordinate.longitude else {
        return
    }
    fetchWeather(lat: lat, lon: long) { str in
        if (str + " ▶").utf8CString.count <= 256 {
            StatusManager.sharedInstance().setCrumb(str)
        } else {
            StatusManager.sharedInstance().setCrumb("Length Error")
        }
    } failure: { error in
        StatusManager.sharedInstance().setCrumb("error")
    }
}
