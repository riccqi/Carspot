//
//  CarparkViewController.swift
//  Carspot
//
//  Created by Richard Qi on 6/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FloatingPanel

class CarparkViewController: UIViewController, FloatingPanelControllerDelegate {
    
    @IBOutlet var CPname: UILabel!
    @IBOutlet weak var feesCP: UILabel!
    @IBOutlet weak var typeOfCP: UILabel!
    @IBOutlet weak var parkingFees: UILabel!
    @IBOutlet weak var nightParking: UILabel!
    @IBOutlet weak var gantryHeight: UILabel!
    @IBOutlet weak var lotsAvail: UILabel!
    @IBOutlet var button: UIButton!
    @IBAction func goButtonTapped(_ sender: UIButton) {
        ViewController.secondFpc.hide(animated: true, completion: nil)
        ViewController.fpc.move(to: .tip, animated: true)
        NotificationCenter.default.post(name: Notification.Name("mapped"), object: nil)
    }
    
    var carparkInfo2: Specs!
    var carpark: String?
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 200
    var lat: Double!
    var lon: Double!

    override func viewDidLoad() {
        super.viewDidLoad()

        button.backgroundColor = UIColor.init(red: 48/255, green: 173/255, blue: 99/255, alpha: 1)
        button.layer.cornerRadius = 15.0
        button.tintColor = UIColor.white

        carparkInfo2 = CPManager.shared.getCarpark(cname: carpark!)
        CPname.text = carparkInfo2.address

        lat = Double(carparkInfo2.y_coord)
        lon = Double(carparkInfo2.x_coord)
        let x:[String:Double] = ["x" : lon]
        let y:[String:Double] = ["y" : lat]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "y_coord"), object: nil, userInfo: y)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "x_coord"), object: nil, userInfo: x)

        feesCP.text = carparkInfo2.short_term_parking
        typeOfCP.text = carparkInfo2.car_park_type + " " + carparkInfo2.type_of_parking_system
        parkingFees.text = carparkInfo2.free_parking
        nightParking.text = carparkInfo2.night_parking
        gantryHeight.text = String(carparkInfo2.total_lots)
        lotsAvail.text = String(carparkInfo2.lot_type_c)
    }
}





