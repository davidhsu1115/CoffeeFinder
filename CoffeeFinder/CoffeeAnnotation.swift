//
//  CoffeeAnnotation.swift
//  CoffeeFinder
//
//  Created by fangwiehsu on 2016/5/9.
//  Copyright © 2016年 fangwiehsu. All rights reserved.
//

import Foundation
import MapKit

// Show spot in the mapview
class CoffeeAnnotation: NSObject, MKAnnotation{
    
    
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    
    init(title:String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        
        super.init()
    }
}