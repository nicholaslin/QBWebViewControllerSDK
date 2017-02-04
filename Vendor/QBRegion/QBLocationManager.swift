//
//  LocationManager.swift
//  aftest
//
//  Created by hh on 17/1/18.
//  Copyright © 2017年 bobby. All rights reserved.
//

import Foundation
import MapKit

enum QBLocationErrorCode:Int {
    
    case notOpen//设备没有开定位
    case denied//app定位权限被拒绝
    case locationFailure//定位失败
}

class QBLocationError:NSError {
    
    var failCode:QBLocationErrorCode?
    
    convenience init(ecode:QBLocationErrorCode) {
        self.init(domain: "Application", code: -1, userInfo: nil)
        failCode = ecode
    }
}


protocol QBLocationManagerDelegate:NSObjectProtocol {
    
    func locationManager(_ service:QBLocationManager, failedError:QBLocationErrorCode)->Void
    
}

class QBLocationManagerTask {
    var addressCallBack:((_ address:QBLocationManagerDataAddress)->Void)?
    var failedCallBack:((_ error:QBLocationError)->Void)?
}



class QBLocationManagerDataTargetItem {
    var provinceInfo: (name: String, code: String)
    var cityInfo: (name: String, code: String)
    var districtInfo: (name: String, code: String)
    
    init(provinceCode:String, provinceName:String, cityCode:String, cityName:String, districtCode:String, districtName:String) {
        self.provinceInfo = (provinceName, provinceCode)
        self.cityInfo = (cityName, cityCode)
        self.districtInfo = (districtName, districtCode)
    }
}


class QBLocationManagerDataAddress {
    
    let coordinate:CLLocationCoordinate2D
    var target:QBLocationManagerDataTargetItem
    
    
    init(coor:CLLocationCoordinate2D, target:QBLocationManagerDataTargetItem) {
        
        self.coordinate = coor
        self.target = target
    }
    
}


class QBLocationManager:NSObject, CLLocationManagerDelegate {
    
    static let shareInstance = QBLocationManager()
    let locationManager = CLLocationManager()
    var tasks:[QBLocationManagerTask] = []
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
    }
    
    
    
    func requestAddress(_ address:@escaping (_ address:QBLocationManagerDataAddress)->Void, failed:@escaping (_ error:QBLocationError)->Void) {
        
        if CLLocationManager.locationServicesEnabled() {
            
            let task = QBLocationManagerTask()
            task.addressCallBack = address
            task.failedCallBack = failed
            tasks.append(task)
            
            //设备是可以定位的, 但不确定app是否具备定位的权限
            let requestSelector = NSSelectorFromString("requestWhenInUseAuthorization")
            if CLLocationManager.authorizationStatus() == .notDetermined &&
                locationManager.responds(to: requestSelector) {
                if #available(iOS 8.0, *) {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
            else {
                self.locationManager.startUpdatingLocation()
            }
        }
        else {
            //关闭定位时可以马上处理
            failed(QBLocationError(ecode: .notOpen))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            if #available(iOS 8.0, *) {
                self.locationManager.requestWhenInUseAuthorization()
            }
            break
        case .denied:
            print("拒绝app定位权限ios7")
            self.locationFailedCallBack(.denied)
            break
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            break
        case .authorizedAlways:
            print("设备开启了定位(包含app权限)ios7")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "EVENT_LOCATION_CHANGE_AUTHORIZATION_STATUS"), object: nil)
            break
        default:
            break
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        guard let location = locations.last else {
            
            self.locationFailedCallBack(.locationFailure)
            
            self.locationManager(manager, didFailWithError:NSError(domain: kCLErrorDomain, code: 2, userInfo: nil))
            return
        }
        
         LocationService.shareInstance.fuzzyQueryWithLat(lat: location.coordinate.latitude, lng: location.coordinate.longitude) { (province, city, district) in
            
            let itemData:QBLocationManagerDataTargetItem? = QBLocationManagerDataTargetItem(provinceCode: (province?.code)!, provinceName: (province?.name)!, cityCode: (city?.code)!, cityName: (city?.name)!, districtCode: (district?.code)!, districtName: (district?.name)!)
            
            
            guard let target = itemData else {
                return
            }
            
            let address = QBLocationManagerDataAddress(coor: location.coordinate, target: target)
            
            if(self.tasks.count>0) {
                for task in self.tasks {
                    task.addressCallBack?(address)
                }
                self.tasks.removeAll()
            }
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        
        manager.stopUpdatingLocation()
        
        self.locationFailedCallBack(.locationFailure, didFailWithError: error as NSError?)
        //定位失败
    }
    
    
    func locationFailedCallBack(_ failCode:QBLocationErrorCode, didFailWithError error: NSError? = nil) {
        
        guard self.tasks.count > 0 else {
            return
        }
        
        var lerror:QBLocationError
        if(error != nil) {
            lerror = QBLocationError(domain: error!.domain, code: error!.code, userInfo: error!.userInfo)
        }
        else {
            
            lerror = QBLocationError(domain: kCLErrorDomain, code: -2, userInfo:nil)
        }
        lerror.failCode = failCode
        
        for task in self.tasks {
            task.failedCallBack?(lerror)
        }
        self.tasks.removeAll()
    }
    
    
}
