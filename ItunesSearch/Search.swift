//
//  Search.swift
//  ItunesSearch
//
//  Created by Alif on 04/05/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation
import UIKit

typealias SearchComplete = (Bool) -> Void

class Search {
    
    enum Category: Int {
        case all      = 0
        case music    = 1
        case software = 2
        case ebook    = 3
        
        var entityName: String {
            switch self {
            case .all:      return ""
            case .music:    return "musicTrack"
            case .software: return "software"
            case .ebook:    return "ebook"
            }
        }
    }
    
    enum State {
        case notSearchYet
        case loading
        case noResults
        case results([SearchResult])
    }
    
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    private var dataTask: URLSessionDataTask? = nil
    
    func performSearch(for text: String, category: Int, completion: @escaping SearchComplete ) {
        if !text.isEmpty {
            
            dataTask?.cancel()
            isLoading = true
            hasSearched = true
            searchResults = []
            
            let url = iTunesURL(searchText: text, category: category)
            let session = URLSession.shared
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                
                var success = false
                
                if let error = error as NSError?, error.code == -999 {
                    return   // Search was cancelled
                }
                if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let jsonData = data,
                    let jsonDictionary = self.parse(json: jsonData) {
                    self.searchResults = self.parse(dictionary: jsonDictionary)
                    self.searchResults.sort(by: <)
                    print("Success!")
                    
                    self.isLoading = false
                    success = true
                }
                
                if !success {
                    self.hasSearched = false
                    self.isLoading = false
                }
                
                DispatchQueue.main.async {
                    completion(success)
                }
            })
            dataTask?.resume()
        }
    }
    
    private func iTunesURL(searchText: String, category: Int) -> URL {
        let entityName: String
        switch category {
        case 1: entityName = "musicTrack"
        case 2: entityName = "software"
        case 3: entityName = "ebook"
        default: entityName = ""
        }
        
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format:"https://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = URL(string: urlString)
        return url!
    }
    
    private func parse(json data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("JSON Error: '\(error)'")
            return nil
        }
    }
    
    private func parse(track dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name            = dictionary["trackName"] as! String
        searchResult.artistName      = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL        = dictionary["trackViewUrl"] as! String
        searchResult.kind            = dictionary["kind"] as! String
        searchResult.currency        = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parse(audiobook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["collectionPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    private func parse(software dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
   private func parse(ebook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genres: Any = dictionary["genres"] {
            searchResult.genre = (genres as! [String]).joined(separator: ", ")
        }
        return searchResult
    }
    
   private func parse(dictionary: [String: Any]) -> [SearchResult] {
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected Result array.")
            return []
        }
        
        var searchResults: [SearchResult] = []
        
        
        for resultDict in array {
            
            var searchResult: SearchResult?
            
            if let resultDict = resultDict as? [String: Any] {
                if let wrapperType = resultDict["wrapperType"] as? String {
                    switch wrapperType {
                    case "track":
                        searchResult = parse(track: resultDict)
                    case "audiobook":
                        searchResult = parse(audiobook: resultDict)
                    case "software":
                        searchResult = parse(software: resultDict)
                    default:
                        break
                    }
                } else if let kind = resultDict["kind"] as? String, kind == "ebook" {
                    searchResult = parse(ebook: resultDict)
                }
                
                if let result = searchResult {
                    searchResults.append(result)
                }
            }
        }
        
        return searchResults
    }
    
}
