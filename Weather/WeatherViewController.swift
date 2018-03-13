//
//  ViewController.swift
//  Weather
//
//  Created by RuslanKa on 09.03.2018.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBAction func navigationArrowPressed(_ sender: UIBarButtonItem) {
        geoManager.requestLocation()
    }
    var gettingWeatherSpinner = UIActivityIndicatorView()
    var gettingCitySpinner = UIActivityIndicatorView()
    var spinner = UIActivityIndicatorView()
    var cityName: String? {
        didSet {
            if cityName != nil {
                navigationItem.title = cityName
            } else {
                navigationItem.title = "..."
            }
        }
    }
    
    let cellId = "weatherCell"
    let geoManager = CLLocationManager()
    let googleAPIKey = "AIzaSyCtmhu0qIk0F57qPFKDTei_6HWc1PCXVhw"
    let openWeatherMapApi = "29b3ab933aa05c01c6e6accbb3e4be4d"
    let darkSkyAPI = "c7e47ce403b6eec0c6a2d5be9830fc90"
    
    var isGettingCity: Bool = false {
        didSet {
            if isGettingCity {
                showSpinner(spinner)
            } else {
                stopSpinner(spinner)
            }
        }
    }
    var isGettingWeather: Bool = false {
        didSet {
            if isGettingCity {
                showSpinner(spinner)
            } else {
                stopSpinner(spinner)
            }
        }
    }
    var weatherPerDay: [[(Date, WeatherInfo)]] = [[(Date, WeatherInfo)]]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        geoManager.delegate = self
        
        setUpdateDateTimer(3600)
        checkGeoPermission()
        setUI()
        geoManager.requestLocation()
    }
    
    func setUI() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        spinner.activityIndicatorViewStyle = .gray
        spinner.hidesWhenStopped = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: spinner)
    }
    
    func setUpdateDateTimer(_ ms: Double) {
        Timer.scheduledTimer(withTimeInterval: ms, repeats: true) { [weak self] _ in
            self?.fullResfresh()
        }
    }
    
    func checkGeoPermission() {
        geoManager.requestWhenInUseAuthorization()
    }
    
    func fullResfresh() {
        geoManager.requestLocation()
    }
    
    func fetchData(with location: CLLocation) {
        self.isGettingWeather = true
        ApiManager.getWeatherWithDarkSky(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, completion: { [weak self] (weatherData) in
            let todayHourlyData = weatherData.filter({ (dict) -> Bool in
                let time = Date.init(timeIntervalSince1970: dict["time"] as! Double)
                return Calendar.current.compare(time, to: Date(), toGranularity: Calendar.Component.day) == .orderedSame
            })
            let tomorrowHourlyData = weatherData.filter({ (dict) -> Bool in
                let calendar = Calendar.current
                var dayComponent = DateComponents()
                dayComponent.day = 1
                let tomorrowDate = calendar.date(byAdding: dayComponent, to: Date())
                let time = Date.init(timeIntervalSince1970: dict["time"] as! Double)
                return Calendar.current.compare(time, to: tomorrowDate!, toGranularity: Calendar.Component.day) == .orderedSame
            })
            let totalWeatherData = [todayHourlyData, tomorrowHourlyData]
            var totalWeatherDataForTable = [[(Date, WeatherInfo)]]()
            for weatherDataForSingleDay in totalWeatherData {
                var weatherPerHourForSingleDay = [(Date, WeatherInfo)]()
                for hourData in weatherDataForSingleDay {
                    guard let timeUnix = hourData["time"] as? Double else { return }
                    guard let temperatureF = hourData["temperature"] as? Double else { return }
                    let temperatureC = (5/9) * (temperatureF - 32)
                    let time = Date.init(timeIntervalSince1970: timeUnix)
                    weatherPerHourForSingleDay.append((time, WeatherInfo.init(temperature: temperatureC)))
                }
                weatherPerHourForSingleDay.sort(by: { (tuple1, tuple2) -> Bool in tuple1.0 < tuple2.0 })
                totalWeatherDataForTable.append(weatherPerHourForSingleDay)
            }
            self?.weatherPerDay = totalWeatherDataForTable
            self?.isGettingWeather = false
        })
        
        isGettingCity = true
        ApiManager.getCity(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { [weak self] (city, country) in
            self?.cityName = city
            self?.isGettingCity = false
        }
    }
    
    @objc func refreshWeatherData(_ sender: Any) {
        fullResfresh()
        tableView.refreshControl?.endRefreshing()
    }
    
    func showSpinner(_ spinner: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            spinner.startAnimating()
        }
    }
    func stopSpinner(_ spinner: UIActivityIndicatorView) {
        if !(isGettingCity || isGettingWeather) {
            DispatchQueue.main.async {
                spinner.stopAnimating()
            }
        }
    }
}

extension WeatherViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return weatherPerDay.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherPerDay[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let weatherCell = cell as? WeatherTableCell {
            weatherCell.date = weatherPerDay[indexPath.section][indexPath.row].0
            weatherCell.weatherInfo = weatherPerDay[indexPath.section][indexPath.row].1
        }
        return cell
    }
}

extension WeatherViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(35)
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDates = weatherPerDay[section]
        if sectionDates.count > 0 {
            let dateForSection = sectionDates[0].0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM YYYY"
            return dateFormatter.string(from: dateForSection)
        }
        return nil
    }
}

extension WeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        fetchData(with: locations.last!)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
