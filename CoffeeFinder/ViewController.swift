//
//  ViewController.swift
//  CoffeeFinder
//
//  Created by fangwiehsu on 2016/5/1.
//  Copyright © 2016年 fangwiehsu. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?

    var locationManager:CLLocationManager?
    let distanceSpan:Double = 500
    
    var lastLocation:CLLocation?
    var venues:[Venue]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onVenuesUpdate:"), name: API.notifications.venuesUpdated, object: nil)
    }
    
    func onVenuesUpdate(notification:NSNotificationCenter){
        refreshVenues(nil)
    }
    
    func refreshVenues(location:CLLocation?, getDataFromFoursquare:Bool = false){
        
        if location != nil{
            lastLocation = location
        }
        
        if let location = lastLocation{
            
            if getDataFromFoursquare == true{
                
                CoffeeApi.sharedInstance.getCoffeeShopWithLocation(location)
            }
            
            
            
            let(start, stop) = calculateCoordinatesWithRegion(location)
            let predicate = NSPredicate(format: "latitude < %f AND latitude > %f AND longitude > %f AND longitude < %f", start.latitude, stop.latitude, start.longitude, stop.longitude)
            let realm = try! Realm()
            venues = realm.objects(Venue).filter(predicate).sort{
                location.distanceFromLocation($0.coordinate) < location.distanceFromLocation($1.coordinate)
            }
            
            for venue in venues!{
                let annotation = CoffeeAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)))
                
                mapView?.addAnnotation(annotation)
            }
            
            tableView?.reloadData()
        }
    }
    
    
    //calculate coordinates with region
    func calculateCoordinatesWithRegion(location:CLLocation) -> (CLLocationCoordinate2D, CLLocationCoordinate2D)
    {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distanceSpan, distanceSpan)
        
        var start:CLLocationCoordinate2D = CLLocationCoordinate2D()
        var stop:CLLocationCoordinate2D = CLLocationCoordinate2D()
        
        start.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0)
        start.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0)
        stop.latitude   = region.center.latitude  - (region.span.latitudeDelta  / 2.0)
        stop.longitude  = region.center.longitude + (region.span.longitudeDelta / 2.0)
        
        return (start,stop)
    }
    
    //大頭針顯示於mapview
    func mapView(mapView:MKMapView, viewForAnnotation annotation:MKAnnotation) -> MKAnnotationView?{
        
        if annotation.isKindOfClass(MKUserLocation)
        {
            return nil
        }
        
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationIdentifier")
        if view == nil{
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier")
        }
        
        //顯示註解
        view?.canShowCallout = true
        
        return view
        
        
    }
    
    
    //tableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return venues?.count ?? 0
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier")
        
        if cell == nil{
            
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cellIdentifier")
        }
        
        if let venue = venues?[indexPath.row]{
            
            cell!.textLabel?.text = venue.name
            cell!.detailTextLabel?.text = venue.address
            
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let venue = venues?[indexPath.row]{
            let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: Double(venue.latitude),longitude: Double(venue.longitude)), distanceSpan, distanceSpan)
            
            mapView?.setRegion(region, animated: true)
        }
    }
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        
        if let mapView = self.mapView
        {
            mapView.delegate = self
        }
        
        if let tableView = self.tableView{
            
            tableView.delegate = self
            tableView.dataSource = self
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if locationManager == nil{
            locationManager = CLLocationManager()
            
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager!.requestAlwaysAuthorization()
            locationManager!.distanceFilter = 50  //don't send location update if the distance is smaller than 50 meters
            locationManager!.startUpdatingLocation()
        }
    }
    
    //using the new coordinate the set the region 
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        if let mapView = self.mapView{
            let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, distanceSpan, distanceSpan)
            mapView.setRegion(region, animated: true)
            
            refreshVenues(newLocation, getDataFromFoursquare: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

