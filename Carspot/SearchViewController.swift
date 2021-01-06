//
//  SearchViewController.swift
//  Carspot
//
//  Created by Richard Qi on 23/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import UIKit
import MapKit

class SearchViewController: UITableViewController {
    
    var mapView : MKMapView!
    let regionInMeters: Double = 1000
    var handleMapSearchDelegate: HandleMapSearch!
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchCompleter.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: selectedItem)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if error == nil {
                let placemark = response?.mapItems[0].placemark
                self.handleMapSearchDelegate.dropPinZoomIn(placemark: placemark!)
            }
        }
        ViewController.fpc.move(to: .half, animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let selectedItem = searchResults[indexPath.row]
        cell.textLabel?.text = selectedItem.title
        cell.detailTextLabel?.text = selectedItem.subtitle
        return cell
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView, let searchbarText = searchController.searchBar.text else {return}
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchbarText
        searchRequest.region = mapView.region
        searchCompleter.queryFragment = searchbarText
    }
}
        
extension SearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func completer(_ completer: MKLocalSearchCompleter,didFailWithError error: Error) {
        print("Search failed.")
    }
}

