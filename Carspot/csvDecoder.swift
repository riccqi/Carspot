//
//  csvDecoder.swift
//  Carspot
//
//  Created by Richard Qi on 8/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import Foundation
import SQLite3
import SwiftCSV

class CPManager {
    var database: OpaquePointer?
    var csv: CSV?
    
    static let shared = CPManager()

    func createDatabase() {
        do {
            // From a file inside the app bundle, with a custom delimiter, errors, and custom encoding
            csv = try CSV(
                name: "hdb-carpark-information",
                extension: "csv",
                bundle: .main,
                encoding: .utf8)
        } catch {
            print("Failed to find file in bundle.")
            return
        }
    }
    
    func connect() {
        if database != nil {
            return
        }
        sqlite3_shutdown();
        let databaseURL = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("carparks.sqlite")
        
        if sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            print("Successfully opened database connection at \(databaseURL.path)")
        }
        else {
            print("unable to open database connection")
        }
        
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS carparks (
                car_park_no TEXT, address TEXT, x_coord TEXT, y_coord TEXT, car_park_type TEXT, type_of_parking_system TEXT, short_term_parking TEXT, free_parking TEXT, night_parking TEXT, car_park_decks TEXT, gantry_height TEXT, car_park_basement TEXT, total_lots INT, lot_type_c INT, lot_type_l INT, lot_type_h INT, lot_type_y INT
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
    }
    
    func createContent() -> Int {
        connect()
        var statement: OpaquePointer? = nil
        
        for row in csv!.namedRows
        {
            let carparkno = row["car_park_no"]!
            let address = row["address"]!
            let x = row["x_coord"]!
            let y = row["y_coord"]!
            let carparktype = row["car_park_type"]!
            let typeofparkingsystem = row["type_of_parking_system"]!
            let shorttermparking = row["short_term_parking"]!
            let freeparking = row["free_parking"]!
            let nightparking = row["night_parking"]!
            let carparkdecks = row["car_park_decks"]!
            let gantryheight = row["gantry_height"]!
            let carparkbasement = row["car_park_basement"]!
            
            
            if sqlite3_prepare_v2(
                database,
                "INSERT INTO carparks (car_park_no, address, x_coord, y_coord, car_park_type, type_of_parking_system, short_term_parking, free_parking, night_parking, car_park_decks, gantry_height, car_park_basement, total_lots, lot_type_c, lot_type_l, lot_type_h, lot_type_y) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'NONE','NONE','NONE','NONE','NONE')",
                -1,
                &statement,
                nil
            ) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, NSString(string: carparkno).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, NSString(string: address).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, NSString(string: x).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, NSString(string: y).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, NSString(string: carparktype).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, NSString(string: typeofparkingsystem).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, NSString(string: shorttermparking).utf8String, -1, nil)
                sqlite3_bind_text(statement, 8, NSString(string: freeparking).utf8String, -1, nil)
                sqlite3_bind_text(statement, 9, NSString(string: nightparking).utf8String, -1, nil)
                sqlite3_bind_text(statement, 10, NSString(string: carparkdecks).utf8String, -1, nil)
                sqlite3_bind_text(statement, 11, NSString(string: gantryheight).utf8String, -1, nil)
                sqlite3_bind_text(statement, 12, NSString(string: carparkbasement).utf8String, -1, nil)
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error inserting note")
                }
            }
            else {
                print("Error creating note insert statement")
            }
        }
        sqlite3_finalize(statement)
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    func getCarpark(cname: String) -> Specs {
        connect()

        var result: Specs!
        var statement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(database, "SELECT car_park_no, address, x_coord, y_coord, car_park_type, type_of_parking_system, short_term_parking, free_parking, night_parking, total_lots, lot_type_c, lot_type_l, lot_type_h, lot_type_y FROM carparks WHERE car_park_no = ?", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: cname).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {

                result = Specs(car_park_no: String(cString: sqlite3_column_text(statement, 0)), address: String(cString: sqlite3_column_text(statement, 1)), x_coord: String(cString: sqlite3_column_text(statement, 2)), y_coord: String(cString: sqlite3_column_text(statement, 3)), car_park_type: String(cString: sqlite3_column_text(statement, 4)), type_of_parking_system: String(cString: sqlite3_column_text(statement, 5)), short_term_parking: String(cString: sqlite3_column_text(statement, 6)), free_parking: String(cString: sqlite3_column_text(statement, 7)), night_parking: String(cString: sqlite3_column_text(statement, 8)), total_lots: Int(sqlite3_column_int(statement, 9)), lot_type_c: Int(sqlite3_column_int(statement, 10)), lot_type_l: Int(sqlite3_column_int(statement, 11)), lot_type_h: Int(sqlite3_column_int(statement, 12)), lot_type_y: Int(sqlite3_column_int(statement, 13)))
            }
        }
        else {
            print("ERROR SELECTING: \(String(cString: sqlite3_errmsg(database)!))")
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    func getFullCarpark() -> [Specs] {
        connect()

        var result: [Specs] = []
        var statement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(database, "SELECT car_park_no, address, x_coord, y_coord, car_park_type, type_of_parking_system, short_term_parking, free_parking, night_parking, total_lots, lot_type_c, lot_type_l, lot_type_h, lot_type_y FROM carparks", -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Specs(car_park_no: String(cString: sqlite3_column_text(statement, 0)), address: String(cString: sqlite3_column_text(statement, 1)), x_coord: String(cString: sqlite3_column_text(statement, 2)), y_coord: String(cString: sqlite3_column_text(statement, 3)), car_park_type: String(cString: sqlite3_column_text(statement, 4)), type_of_parking_system: String(cString: sqlite3_column_text(statement, 5)), short_term_parking: String(cString: sqlite3_column_text(statement, 6)), free_parking: String(cString: sqlite3_column_text(statement, 7)), night_parking: String(cString: sqlite3_column_text(statement, 8)), total_lots: Int(sqlite3_column_int(statement, 9)), lot_type_c: Int(sqlite3_column_int(statement, 10)), lot_type_l: Int(sqlite3_column_int(statement, 11)), lot_type_h: Int(sqlite3_column_int(statement, 12)), lot_type_y: Int(sqlite3_column_int(statement, 13))))
            }
        }
        else {
            print("ERROR SELECTING: \(String(cString: sqlite3_errmsg(database)!))")
        }
        sqlite3_finalize(statement)
        return result
    }

    func updateLots(carpark: String, dets: [Details]) {
        connect()

        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE carparks SET total_lots = ?, lot_type_c = ?, lot_type_l = ?, lot_type_h = ?, lot_type_y = ? WHERE car_park_no = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            
            for i in dets
            {
                if i.lot_type == "C"
                {
                    sqlite3_bind_int(statement, 1, Int32(i.total_lots)!)
                    sqlite3_bind_int(statement, 2, Int32(i.lots_available) ?? 0)
                }
                else if i.lot_type == "L"
                {
                    sqlite3_bind_int(statement, 3, Int32(i.lots_available) ?? 0)
                }
                else if i.lot_type == "H"
                {
                    sqlite3_bind_int(statement, 4, Int32(i.lots_available) ?? 0)
                }
                else if i.lot_type == "Y"
                {
                    sqlite3_bind_int(statement, 5, Int32(i.lots_available) ?? 0)
                }
            }
            
            sqlite3_bind_text(statement, 6, NSString(string: carpark).utf8String, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving update")
            }
        }
        else {
            print("Error creating carpark update statement")
        }

        sqlite3_finalize(statement)
    }
    
    
    func filterCarpark(x: Info) {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "DELETE FROM carparks WHERE car_park_no = ?", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: x.carpark_number).utf8String, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting")
            }
        }
        else {
            print("Error creating carpark delete statement")
        }
        sqlite3_finalize(statement)
    }
}


           
