//
//  ModalViewController.swift
//  Carspot
//
//  Created by Richard Qi on 28/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import UIKit
import FloatingPanel

class ModalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FloatingPanelControllerDelegate {
    
    var spec: Specs!
    @IBOutlet var myTableView: UITableView!
    let cellReuseIdentifier = "Cell"
    var secondFpc: FloatingPanelController!
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyList.nearbyList.count
    }
    
    //DISPLAY CELL
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellReuseIdentifier)
        cell.accessoryType = .disclosureIndicator
        spec = CPManager.shared.getCarpark(cname: nearbyList.nearbyList[indexPath.row])
        
        cell.detailTextLabel?.text = String(spec.lot_type_c)
        cell.textLabel?.text = spec.car_park_no
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ViewController.secondFpc != nil {
            ViewController.secondFpc.hide(animated: true)
        }
        performSegue(withIdentifier: "ParkSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ParkSegue",
                let destination = segue.destination as? CarparkViewController,
                let index = myTableView.indexPathForSelectedRow?.row {
            destination.carpark = nearbyList.nearbyList[index]
        }
    }
    
    @objc func refresh() {
        myTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh), name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
        
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        myTableView.delegate = self
        myTableView.dataSource = self
    }
}

