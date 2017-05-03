//
//  SearchResult.swift
//  ItunesSearch
//
//  Created by Alif on 01/05/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

class SearchResult {
    var artworkSmallURL = ""
    var artworkLargeURL = ""
    var storeURL = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
    var name = ""
    var artistName = ""
}

func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
}
