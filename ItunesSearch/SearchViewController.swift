//
//  ViewController.swift
//  ItunesSearch
//
//  Created by Alif on 30/04/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    let search =  Search()

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell      = "LoadingCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0)
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        tableView.rowHeight = 80
        searchBar.becomeFirstResponder()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    func performStoreRequest(with url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Download Error: \(error)")
            return nil
        }
    }
 
    func showNetWorkError() {
        let alert = UIAlertController(title: "Whoops..", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}


extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
        search.performSearch(for: searchBar.text!,
                             category: segmentedControl.selectedSegmentIndex,
                             completion: { success in
            if !success {
                self.showNetWorkError()
            }
            self.tableView.reloadData()
        })
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if search.isLoading {
            return 1 // Loading..
        } else if !search.hasSearched {
            return 0 // Not search Yet
        } else if search.searchResults.count == 0 {
            return 1 // Nothing found
        } else {
            return search.searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if search.isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
            
        } else if search.searchResults.count == 0 {
            return tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.nothingFoundCell,
                for: indexPath)
            
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.searchResultCell,
                for: indexPath) as! SearchResultCell
            
            let searchResult = search.searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            
            if searchResult.artistName.isEmpty {
                cell.artistNameLabel.text = "Unknow"
            } else {
                cell.artistNameLabel.text = String(format: "%@, (%@)", searchResult.artistName,
                                                   kindForDisplay(searchResult.kind))
            }
            cell.config(for: searchResult)
            return cell
        }
    }
    
    func kindForDisplay(_ kind: String) -> String {
        switch kind {
        case "album": return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
    
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if search.searchResults.count == 0 || search.isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}
