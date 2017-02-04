//
//  QBRespObject.swift
//  QBWebViewSDK
//
//  Created by 林子帆 on 2017/1/18.
//  Copyright © 2017年 林子帆. All rights reserved.
//

import Foundation

/*! @brief 响应JS请求的状态
 *  每次响应在QBResp中带上本次的响应状态，不能单独使用。
 *
 */
public enum QBRespStatus:Int {
    case success = 0
    case noLogin = 1
    case paramError = 2
    case shareCancel = 3
    case shareFail = 4
    case exchangeFail = 5
    case exchangeCancel = 6
    case quickLoginFail = 7
    case getOrderNoFail = 8
    case getUserDataFail = 9
    case payFail = 10
    case payCancel = 11
}

/*! @brief 响应JS请求的结构体
 *  status: 本次响应的状态
 *  data:   回传给JS的数据，如果没有，传空(e.g.[:]).
 *  msg:    一般传nil，在特殊情况下才传，例如通知JS出错原因
 */
public struct QBResp {
    
    var status:QBRespStatus
    var data:[String:Any]
    var msg:String?
    
    public init(status:QBRespStatus, data:[String:Any] = [:], msg:String? = nil) {
        self.status = status
        self.data = data
        self.msg = msg
    }
    
}
