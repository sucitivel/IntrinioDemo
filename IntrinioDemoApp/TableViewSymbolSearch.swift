//
//  TableViewSymbolSearch.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/25/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class TableViewSymbolSearch: UITableViewController, UISearchBarDelegate {
    var tickerSymbols: SymbolSearchResults?
    var intrinio: IntrinioConnector = IntrinioConnector()
    @IBOutlet var myTableView: UITableView!
    var currentPage: Page?
    
    let cellTickerLabelTag = 1
    let cellTickerNameTag = 2
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tickerSymbols == nil {
            return 0;
        } else {
            return tickerSymbols!.data.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerSymbolCell", for: indexPath)

        let tickerSymbolLabel: UILabel = cell.viewWithTag(self.cellTickerLabelTag) as! UILabel
        let tickerNameLabel: UILabel = cell.viewWithTag(self.cellTickerNameTag) as! UILabel

        tickerSymbolLabel.text = tickerSymbols!.data[indexPath.row].ticker
        tickerNameLabel.text = tickerSymbols!.data[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tickerSymbol: TickerSymbol = tickerSymbols!.data[indexPath.row]
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        let symbolFetchRequest: NSFetchRequest<Symbol> = Symbol.fetchRequest()
        symbolFetchRequest.fetchLimit = 1
        symbolFetchRequest.predicate = NSPredicate(format: "symbol == %@", argumentArray: [tickerSymbol.ticker])

        do {
            let pageSymbolList = currentPage?.mutableSetValue(forKeyPath: "symbols")
            let existingSymbolTest: [Symbol] = try context.fetch(symbolFetchRequest)
            if existingSymbolTest.count > 0 {
                pageSymbolList?.add(existingSymbolTest[0])
            } else {
                let newSymbol = Symbol(context: context)
                newSymbol.company = tickerSymbol.name
                newSymbol.symbol = tickerSymbol.ticker
                newSymbol.cik = tickerSymbol.cik
                pageSymbolList?.add(newSymbol)
            }
        } catch {
            print(error)
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        self.dismiss(animated: true, completion: {})
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        intrinio.searchForTickerSymbol(searchQuery: searchBar.text!, completionHandler: self.resultsReceived)
    }
    
    func resultsReceived(withData: Data?, urlResponse: URLResponse?, error: Error?) -> Void {
        let decoder = JSONDecoder()
        do {
            tickerSymbols = try decoder.decode(SymbolSearchResults.self, from: withData!)
            DispatchQueue.main.async {
                self.myTableView.reloadData()
            }
        } catch {
            print("error decoding json")
            print(error)
        }
    }
    
    func setPage(_ page: Page) {
        currentPage = page
    }
}
