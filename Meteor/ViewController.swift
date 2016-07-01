//
//  ViewController.swift
//  Meteor
//
//  Created by Mathieu Mailfert on 25/06/2016.
//  Copyright © 2016 Mathieu Mailfert. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tittleBar: UINavigationItem!
    
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var refreshControl: UIRefreshControl!

    var items = [[String: String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tittleBar.title = "Meteor"
        navBar.backgroundColor = UIColor.whiteColor()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Recharger la météo")
        refreshControl.addTarget(self, action: #selector(ViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func refresh(sender:AnyObject) {
        items = []
        meteoApiRequest(currentLocation)
    }
    
    // GEOLOCATION
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                self.displayLocationInfo(pm)
                self.currentLocation = locations[0]
                self.meteoApiRequest(locations[0])
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            locationManager.stopUpdatingLocation()
            
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            tittleBar.title = locality! + ", " + country!
        }
    }
    
    
    //REQUEST API
    func meteoApiRequest(location: CLLocation){
        let long = String(location.coordinate.longitude)
        let lat = String(location.coordinate.latitude)
        
        let urlString: String = "https://api.forecast.io/forecast/70fee63c44fa90759f7e24d328d67ff2/" + lat + "," + long
        if let url = NSURL(string: urlString) {
            if let data = try? NSData(contentsOfURL: url, options: []) {
                let json = JSON(data: data)
                parseJSON(json)
            } else {
                showError()
            }
        } else {
            showError()
        }
    }
    
    func parseJSON(json: JSON) {
        let res = json["hourly"]["data"]
        for result in res.arrayValue {
            let time = result["time"].stringValue
            
            let temperature = result["temperature"].stringValue
            let humidity = result["humidity"].stringValue
            let icon = result["icon"].stringValue
            
            let obj = ["time": time, "temperature": temperature, "humidity": humidity, "icon": icon]
            items.append(obj)
        }
        tableView!.reloadData()
        refreshControl.endRefreshing()
    }
    
    func showError() {
        let ac = UIAlertController(title: "Echec du chargement", message: "Problème de telechargement, veuillez vérifier votre connection et réessayer", preferredStyle: .Alert)
        
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
        refreshControl.endRefreshing()
    }

    // TABLEVIEW
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! MeteorCell
        
        let timeDouble = Double(items[indexPath.row]["time"]!)

        let date = NSDate(timeIntervalSince1970: timeDouble!)
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour, .Day , .Month , .Year], fromDate: date)
        let year =  components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        
        let tempCelsius = Int((Double(items[indexPath.row]["temperature"]!)! - 32) * 5 / 9)
        
        cell.dateLabel.text = String(day) + "/" + String(month) + "/" + String(year) + " à " + String(hour) + "h00"
        cell.tempLabel.text = String(tempCelsius) + " °C"
        cell.humidityLabel.text = String(Double(items[indexPath.row]["humidity"]!)! * 100) + "% d'humidité"
        cell.iconImage.image = UIImage(named: items[indexPath.row]["icon"]!)

        if (day % 2 == 0) {
            cell.backgroundColor = UIColor(red: 1, green: 1, blue: 0.95, alpha: 1)
        } else {
            cell.backgroundColor = UIColor(red: 0.95, green: 1, blue: 1, alpha: 1)
        }
        return cell
    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MeteorCell
        let tittle = "Le " + cell.dateLabel.text!
        let meteoData = "Une temperature de " + cell.tempLabel.text! + ", et une humidité de " + cell.humidityLabel.text!
        let ac = UIAlertController(title: tittle, message: meteoData, preferredStyle: .Alert)
        
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    //Hide statusBar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

