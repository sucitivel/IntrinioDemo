//
//  ModelController.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/21/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import UIKit
import CoreData

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


class ModelController: NSObject, UIPageViewControllerDataSource {

    var pageData: [Page] = []
    var intrinio: IntrinioConnector?
    var updateTableSymbols: (( String? ) -> Void?)?
    
    override init() {
        super.init()
        // Create the data model.
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let pageRequest: NSFetchRequest<Page> = Page.fetchRequest()
        
        do {
            pageData = try context.fetch(pageRequest)
        } catch {
            print(error)
        }

        if pageData.count == 0 {
            let newPage: Page = Page(context: context)
            newPage.pageIndex = 0
            pageData.append(newPage)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }

        intrinio = IntrinioConnector()
        intrinio?.start(self.intrinioEventHandler, onReadyEvent: self.intrinioReady)
    }
    
    func setUpdateHandler(_ handler: @escaping ( String? ) -> Void?) {
        updateTableSymbols = handler
    }
    
    func intrinioEventHandler(_ withEvent: IEXEvent?) -> Void {
        print(withEvent)
        switch withEvent?.event {
        case "quote"?:
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let symbolRequest: NSFetchRequest<Symbol> = Symbol.fetchRequest()
            symbolRequest.predicate = NSPredicate(format: "symbol = %@", argumentArray: [withEvent?.payload?.ticker])
            do {
                let symbol: [Symbol] = try context.fetch(symbolRequest)
                if symbol.count > 0 {
                    symbol[0].lastPrice = (withEvent?.payload?.price)!
                }
                DispatchQueue.main.async {
                    self.updateTableSymbols?(symbol[0].symbol)
                }
            } catch {
                print(error)
            }
            break
        default:
            print(withEvent)
        }
        
    }
    
    func intrinioReady() -> Void {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let symbolsRequest: NSFetchRequest<Symbol> = Symbol.fetchRequest()
        do {
            let symbolData: [Symbol] = try context.fetch(symbolsRequest)
            for symbol in symbolData {
                intrinio?.subscribeToTicker(symbol.symbol!)
            }
        } catch {
            print(error)
        }
    }
    
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> DataViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
        dataViewController.setPageData(self.pageData[index], withModelController: self)
        
        return dataViewController
    }

    func indexOfViewController(_ viewController: DataViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        let index: Int? = self.pageData.index(of: viewController.page!)
        return index!
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        if index == self.pageData.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func addNewPage() -> Int {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newPage: Page = Page(context: context)
        newPage.pageIndex = Int32(pageData.count)
        pageData.append(newPage)
        return Int(newPage.pageIndex)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
}

