//
//  CoffeeApi.swift
//  CoffeeFinder
//
//  Created by fangwiehsu on 2016/5/1.
//  Copyright © 2016年 fangwiehsu. All rights reserved.
//

import Foundation
import MapKit
import RealmSwift
import QuadratTouch

struct API{
    
    struct notifications {
        
        static let venuesUpdated = "venues updated"
    }
}

class CoffeeApi{
    
    static let sharedInstance = CoffeeApi()
    var session:Session?
    
    
    init(){
        
        let client = Client(clientID: "22WRVH3XM1ZBXHPVO5ZZCV0HGPXWD51434XB0R5WYCTH4LIK", clientSecret: "COABOLQJLKSHA05554QL5PTLKOU5T32LGSOCBAT2ZJBOABDD", redirectURL: "")
        let configuration = Configuration(client: client)
        Session.setupSharedSessionWithConfiguration(configuration)
        self.session = Session.sharedSession()
        
    }
    
    
    func getCoffeeShopWithLocation(location:CLLocation)
    {
    
        if let session = self.session
        {
            
            var parameters = location.parameters()
            parameters += [Parameter.categoryId: "4bf58dd8d48988d1e0931735"]
            parameters += [Parameter.radius: "2000"]
            parameters += [Parameter.limit: "50"]
        
            
            //start search
            let searchTask = session.venues.search(parameters)
            {
                (result) -> Void in
                
                if let response = result.response
                {
                    if let venues = response["venues"] as? [[String:AnyObject]]
                    {
                        autoreleasepool({ 
                            
                            let realm = try! Realm()  //try! Realm() 表示不處理Realm所產生的錯誤 驚嘆號會讓try產生的錯誤直接被忽略
                            realm.beginWrite()
                            
                            for venue:[String: AnyObject] in venues
                            {
                                let venueObject:Venue = Venue()
                                
                                if let id = venue["id"] as? String
                                {
                                    venueObject.id = id
                                }
                                if let name = venue["name"] as? String
                                {
                                    venueObject.name = name
                                }
                                if let location = venue["location"] as? [String: AnyObject]
                                {
                                    if let longitude = location["lng"] as? Float
                                    {
                                        venueObject.longitude = longitude
                                    }
                                    if let latitude = location["lat"] as? Float
                                    {
                                        venueObject.latitude = latitude
                                    }
                                    
                                    if let formattedAddress = location["formattedAddress"] as? [String]
                                    {
                                        venueObject.address = formattedAddress.joinWithSeparator(" ")
                                    }
                                    
                                }
                                
                             realm.add(venueObject, update: true)
                                
                            }
                            
                            do
                            {
                                try realm.commitWrite()
                                print("Committing write")
                            }catch (let e){
                                print("You don't have Realm \(e)")
                            
                            }
                            
                        })
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(API.notifications.venuesUpdated, object: nil, userInfo: nil)
                    }
                }
                
            }
            
            searchTask.start()
        }
        
    }
    
    
}

extension CLLocation{
    
    func parameters() -> Parameters
    {
        let ll = "\(self.coordinate.latitude), \(self.coordinate.longitude)"
        let llAcc = "\(self.horizontalAccuracy)"
        let alt = "\(self.altitude)"
        let altAcc = "\(self.verticalAccuracy)"
        
        let parameters = [
        
            Parameter.ll:ll, Parameter.llAcc:llAcc, Parameter.alt:alt, Parameter.altAcc:altAcc
        ]
        
        return parameters
    }
    
}