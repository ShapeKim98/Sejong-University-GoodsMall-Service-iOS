//
//  OrderType.swift
//  SejongUniversityGoodsMall
//
//  Created by 김도형 on 2023/02/19.
//

import Foundation

enum OrderType: String, Codable {
    case pickUpOrder = "pickup"
    case deliveryOrder = "delivery"
}
