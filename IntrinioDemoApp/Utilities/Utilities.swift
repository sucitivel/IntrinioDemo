//
//  Utilities.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/29/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import Foundation

struct TickerSymbol: Decodable {
    var name: String
    var ticker: String
    var cik: String
}

struct SymbolSearchResults: Decodable {
    var apiCallCredits: Int?
    var data: [TickerSymbol]
}

struct IEXPayload: Decodable {
    var type: String?
    var timestamp: Float?
    var ticker: String?
    var size: Int?
    var price: Float?
}

struct IEXEvent: Decodable {
    var topic: String?
    var event: String?
    var payload: IEXPayload?
}

struct PriceResponseData: Decodable {
    var open: Float?
    var high: Float?
    var close: Float?
    var low: Float?
    var volume: Int
}

struct PriceResponse: Decodable {
    var result_count: Int?
    var data: [PriceResponseData]?
}
