//
//  DataViewController.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/21/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import UIKit
import CoreData

class DataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var page: Page?
    var symbols: [Any]?
    var firstLoad: Bool = false
    var modelController: ModelController?
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadPageData()
        firstLoad = false
    }
    
    func setPageData(_ pageData: Page, withModelController: ModelController) {
        page = pageData
        symbols = page?.symbols?.allObjects
        modelController = withModelController
    }
    
    func reloadPageData() {
        let intrinioConnector: IntrinioConnector = IntrinioConnector()
        symbols = page?.symbols?.allObjects
        for (index, symbol) in symbols!.enumerated() {
            if (symbol as! Symbol).openPrice.isZero || firstLoad {
                intrinioConnector.updateSymbolData((symbol as! Symbol).symbol!, completionHandler: tickerSymbolUpdated)
                modelController?.intrinio?.subscribeToTicker((symbol as! Symbol).symbol!)
            }
        }
        self.tableView.reloadData()
    }
    
    func tickerSymbolUpdated(_ withSymbol: String?, priceResponse: PriceResponse?) -> Void {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let symbolsRequest: NSFetchRequest<Symbol> = Symbol.fetchRequest()
        symbolsRequest.predicate = NSPredicate(format: "symbol = %@", argumentArray: [withSymbol])
        
        do {
            let symbol: [Symbol] = try context.fetch(symbolsRequest)
            if symbol.count > 0 {
                let priceResponseData: PriceResponseData = priceResponse!.data![0]
                symbol[0].highPrice = priceResponseData.high!
                symbol[0].lowPrice = priceResponseData.low!
                symbol[0].openPrice = priceResponseData.open!
                symbol[0].closePrice = priceResponseData.close!
                symbol[0].volume = Int64(priceResponseData.volume)
                
                if symbol[0].lastPrice.isZero {
                    symbol[0].lastPrice = priceResponseData.close!
                }
                reloadSymbolRow(withSymbol!)
            }
        } catch {
            print(error)
        }
    }
    
    func reloadSymbolRow(_ withSymbol: String) {
        for (index, symbol) in symbols!.enumerated() {
            if withSymbol == (symbol as! Symbol).symbol {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
                self.tableView.endUpdates()
                return
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableLength = tableView.numberOfRows(inSection: 0)

        if indexPath.row == (tableLength - 1) {
            let symbolSelector = self.storyboard?.instantiateViewController(withIdentifier: "TableViewSymbolSearch") as! TableViewSymbolSearch
            symbolSelector.setPage(page!)
            self.present(symbolSelector, animated: true)
        }
    }
    
    func deleteRow(_ withIndex: IndexPath) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let deleteSymbol: Symbol = symbols![withIndex.row] as! Symbol

        let pageSymbolList = page?.mutableSetValue(forKeyPath: "symbols")
        
        pageSymbolList?.remove(deleteSymbol)
        
        let pageList = deleteSymbol.pages
        
        if pageList?.count == 0 {
            context.delete(deleteSymbol)
        }
        reloadPageData()
    }
    
    //MARK - Table view stuff
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //add one to count for the row that adds new symbols
        return symbols!.count + 1
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteRow(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == symbols!.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addItemCell", for: indexPath) as! TickerTableViewAddItemCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath) as! TickerTableViewCell
        
            let symbol: Symbol = symbols![indexPath.row] as! Symbol
            let priceChange: Float = symbol.lastPrice - symbol.openPrice
            let percentChange: Float = (priceChange / symbol.openPrice) * 100
            var percentIndicator: String = ""
            
            if percentChange > 0 {
                percentIndicator = "+"
                cell.priceChange.textColor = UIColor(displayP3Red: 0.0, green: 255.0, blue: 0.0, alpha: 1)
                cell.currentPriceLabel.textColor = UIColor(displayP3Red: 0.0, green: 255.0, blue: 0.0, alpha: 1)
                cell.tickerSymbolLabel.textColor = UIColor(displayP3Red: 0.0, green: 255.0, blue: 0.0, alpha: 1)
            } else {
                percentIndicator = ""
                cell.priceChange.textColor = UIColor(displayP3Red: 255.0, green: 0.0, blue: 0.0, alpha: 1)
                cell.currentPriceLabel.textColor = UIColor(displayP3Red: 255.0, green: 0.0, blue: 0.0, alpha: 1)
                cell.tickerSymbolLabel.textColor = UIColor(displayP3Red: 255.0, green: 0.0, blue: 0.0, alpha: 1)
            }
            
            cell.hiPriceLabel.text = "h: " + String(format: "%.3f", symbol.highPrice)
            cell.lowPriceLabel.text = "l: " + String(format: "%.3f", symbol.lowPrice)
            cell.openPriceLabel.text = "o: " + String(format: "%.3f", symbol.openPrice)
            cell.tickerSymbolLabel.text = symbol.symbol
            cell.currentPriceLabel.text = String(symbol.lastPrice)
            cell.priceChange.text = String(format: "%.3f", priceChange) + " \(percentIndicator)" + String(format: "%.3f", percentChange) + "%"
            
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 93.5
    }
}

