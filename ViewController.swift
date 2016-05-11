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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?

    var locationManager:CLLocationManager?
    let distanceSpan:Double = 500
    
    var lastLocation:CLLocation?
    var venues:Results<Venue>?
    
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
            
            let realm = try! Realm()
            venues = realm.objects(Venue)
            
            for venue in venues!{
                let annotation = CoffeeAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)))
                
                mapView?.addAnnotation(annotation)
            }
        }
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
    
    
    
    override func viewWillAppear(animated: Bool) {
        
        if let mapView = self.mapView
        {
            mapView.delegate = self
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

