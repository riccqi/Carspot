//
//  Avaliability.swift
//  Carspot
//
//  Created by Richard Qi on 6/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import Foundation

struct Items: Codable {
    let items: [Time]
}

struct Time: Codable {
    let carpark_data: [Info]
}

struct Info: Codable {
    let carpark_info: [Details]
    let carpark_number: String
    let update_datetime: String
}

struct Details: Codable {
    let total_lots: String
    let lot_type: String
    let lots_available: String
}

struct Specs: Codable {
    let car_park_no: String
    let address: String
    let x_coord: String
    let y_coord: String
    let car_park_type: String
    let type_of_parking_system: String
    let short_term_parking: String
    let free_parking: String
    let night_parking: String
    let total_lots: Int
    let lot_type_c: Int
    let lot_type_l: Int
    let lot_type_h: Int
    let lot_type_y: Int
}

struct nearbyList {
    static var nearbyList: [String] = []
}
