//
//  TickerItem.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/24/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import Foundation
import UIKit

class TickerTableViewCell: UITableViewCell {
    @IBOutlet var tickerSymbolLabel: UILabel!
    @IBOutlet var openPriceLabel: UILabel!
    @IBOutlet var lowPriceLabel: UILabel!
    @IBOutlet var hiPriceLabel: UILabel!
    @IBOutlet var currentPriceLabel: UILabel!
    @IBOutlet var priceChange: UILabel!
    
}
