//
//  LocationService.swift
//  aftest
//
//  Created by hh on 17/1/16.
//  Copyright © 2017年 bobby. All rights reserved.
//

import UIKit

class LocationService_Item: NSObject {
    
    var name: String?
    var code: String?
    var hasChildren: Bool?
    
    init(name: String, code: String, hasChildren: Bool) {
        super.init()
        
        self.name = name
        self.code = code
        self.hasChildren = hasChildren
        
    }
    
}

class LocationService_Node: NSObject {
    
    var name: String?
    var code: String?
    var children: [LocationService_Node]?
    
    init(name: String?, code: String?, children: [LocationService_Node]?) {
        super.init()
        
        self.name = name
        self.code = code
        self.children = children
        
    }
    
}

class LocationService {
    
    static let shareInstance = LocationService()
    
    var data: [LocationService_Node]?
    
    fileprivate init() {
        
//        let file = Bundle(path: Bundle.main.bundlePath + "/RegionSDK.bundle")?.path(forResource: "QBCityCode", ofType: "json")
        let file = Bundle(identifier: QBWebView_SDK_Identifier)?.path(forResource: "QBCityCode", ofType: "json")
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: file!)) {
            do {
                let arr = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [[String:AnyObject]]
                
                self.data = self.buildData(items: arr!)
            } catch {
                print("解析错误")
            }
        }
    }
    
    func fuzzyQueryWithLat(lat: Double, lng: Double, callBack:@escaping (_ province: LocationService_Item?, _ city: LocationService_Item?, _ district: LocationService_Item?) -> Void) {
        
        let aks = ["VH5IPYbCSgKldXbsAU63YiWj", "dCv3S95YwGcuv53mcfLFTktu", "4RVREnsQ5IYyYCOk68ErDFbq"]
        
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        let session: URLSession = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: OperationQueue.main)
        let request: URLRequest = URLRequest(url: URL(string: "https://api.map.baidu.com/geocoder/v2/?ak=\(aks[Int(arc4random_uniform(UInt32(aks.count)))])&location=\(String(lat)),\(String(lng))&output=json")!)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                callBack(nil, nil, nil)
            } else {
                
                do {
                    let resp = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: Any]
                    if let result = resp["result"] as? [String: Any] {
                        if let addressComponent = result["addressComponent"] as? [String: Any] {
                            if var provinceName = addressComponent["province"] as? String?, var cityName = addressComponent["city"] as? String?, var districtName = addressComponent["district"] as? String? {
                                
                                if provinceName?.characters.count == 0 {
                                    provinceName = nil
                                }
                                if cityName?.characters.count == 0 {
                                    cityName = nil
                                }
                                if districtName?.characters.count == 0 {
                                    districtName = nil
                                }
                                
                                else if districtName?.range(of: "市辖区") != nil {
                                    districtName = nil
                                }
                                
                                if provinceName != nil && cityName != nil && provinceName == cityName {
                                    cityName = districtName
                                    districtName = nil
                                }
                                
                                else if cityName?.range(of: "直辖县级行政单位") != nil {
                                    cityName = districtName
                                    districtName = nil
                                }
                                
                                print("\(provinceName != nil ? provinceName : "?") \(cityName != nil ? cityName : "?") \(districtName != nil ? districtName : "?")")
                                
                                self.fuzzyQueryWithProvinceName(provinceName: provinceName, cityName: cityName, districtName: districtName, callback: callBack)
                            }
                            
                            else {
                                callBack(nil, nil, nil)
                            }
                        }
                    }
                    
                } catch {
                    print("解析错误")
                }
            }
        }
        task.resume()
    }
    
    func fuzzyQueryWithProvinceName(provinceName: String?, cityName:String?, districtName: String?, callback: @escaping (_ province: LocationService_Item?, _ city: LocationService_Item?, _ district: LocationService_Item?) -> Void) {
        
        DispatchQueue.global().async { 
            var province: LocationService_Item? = nil
            var city: LocationService_Item? = nil
            var district: LocationService_Item? = nil
            
            if provinceName != nil {
                let provinceNode = self.fuzzyQueryWithProvinceName(provinceName: provinceName!)
                if provinceNode != nil {
                    province = LocationService_Item.init(name: (provinceNode?.name)!, code: (provinceNode?.code)!, hasChildren: provinceNode?.children != nil)
                    
                    if cityName != nil {
                        let cityNode = self.fuzzyQueryWithProvinceName(provinceName: provinceName!, cityName: cityName!)
                        if cityNode != nil {
                            city = LocationService_Item.init(name: (cityNode?.name)!, code: (cityNode?.code)!, hasChildren: cityNode?.children != nil)
                            
                            if districtName != nil {
                                let districtNode = self.fuzzyQueryWithProvinceName(provinceName: provinceName!, cityName: cityName!, districtName: districtName!)
                                
                                if districtNode != nil {
                                    district = LocationService_Item.init(name: (districtNode?.name)!, code: (districtNode?.code)!, hasChildren: districtNode?.children != nil)
                                }
                            }
                        }
                    }
                }
            }
            callback(province, city, district)
        }
    }
    
    
    func fuzzyQueryWithProvinceName(provinceName: String) -> LocationService_Node? {
        return self.fuzzyFindWithName(name: provinceName, nodes: self.data!)
    }
    
    func fuzzyQueryWithProvinceName(provinceName: String, cityName: String) -> LocationService_Node? {
        let provinceNode = self.fuzzyQueryWithProvinceName(provinceName: provinceName)
        if provinceNode == nil || provinceNode?.children == nil || provinceNode?.children?.count == 0 {
            return nil
        }
        
        return self.fuzzyFindWithName(name: cityName, nodes: (provinceNode?.children)!)
    }
    
    func fuzzyQueryWithProvinceName(provinceName: String, cityName: String, districtName: String) -> LocationService_Node? {
        let cityNode = self.fuzzyQueryWithProvinceName(provinceName: provinceName, cityName: cityName)
        if cityNode == nil || cityNode?.children == nil || cityNode?.children?.count == 0 {
            return nil
        }
        return self.fuzzyFindWithName(name: districtName, nodes: (cityNode?.children)!)
    }
    
    //MARK: privete func
    fileprivate func findWithCode(code: String, nodes: [LocationService_Node]) -> LocationService_Node? {
        
        for node in nodes {
            
            if node.code! == code {
                return node
            }
        }
        
        return nil
    }
    
    fileprivate func fuzzyFindWithName(name: String, nodes: [LocationService_Node]) -> LocationService_Node {
        
        var minVal = 99999
        var minIdx = 0
        
        for idx in 0..<nodes.count {
            let node = nodes[idx]
            if node.name! == name {
                return node
            }
            let score = name.getLevenshtein(node.name!)
            if score < minVal {
                minVal = score
                minIdx = idx
            }
        }
        
        return nodes[minIdx]
    }
    
    fileprivate func buildData(items: [[String:AnyObject]]) -> [LocationService_Node] {
        
        var data = [LocationService_Node]()
        
        for item in items {
            let name = item["name"] as? String ?? ""
            let code = item["code"] as? String ?? ""
            var children: [LocationService_Node]?
            
            if let _  = item["children"] {
                children = self.buildData(items: item["children"] as! [[String : AnyObject]])
            }
            
            let node: LocationService_Node = LocationService_Node.init(name: name, code: code, children: children)
            data.append(node)
        }
        return data
    }
}





