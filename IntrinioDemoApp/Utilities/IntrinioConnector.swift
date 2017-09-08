//
//  IntrinioConnector.swift
//  IntrinioDemoApp
//
//  Created by brad zasada on 8/23/17.
//  Copyright © 2017 PrototypeB. All rights reserved.
//

import Foundation
import Starscream

class IntrinioConnector: WebSocketDelegate {
    var socket: WebSocket?
    var authToken: NSString?
    var authURL: String = "https://realtime.intrinio.com/auth"
    var username = "be7c26ebde694d08e71872b9774bf6a3"
    var password = "bc11e9a56c336708529f851258e67b23"
    var eventHandler: ((IEXEvent? ) -> Void)?
    var eventReady: (() -> Void)?
    var connectionReady: Bool = false
    var subscribedSymbols: [String] = []
    var heartbeater: Timer?

    func start(_ myEventHandler: @escaping (IEXEvent? ) -> Void, onReadyEvent: @escaping () -> Void) {
        //authenticate our user
        let request = getRequestForURL(urlString: authURL)
        
        self.eventHandler = myEventHandler
        self.eventReady = onReadyEvent
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            self.authToken = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            self.socket = WebSocket(url: URL(string: "wss://realtime.intrinio.com:443/socket/websocket?vsn=1.0.0&token=" + (self.authToken! as String))!)
            self.socket?.delegate = self
            self.socket?.connect()
        }
        
        task.resume()
    }
    
    func subscribeToTicker(_ withSymbol: String) {
        if subscribedSymbols.index(of: withSymbol) == nil {
            subscribedSymbols.append(withSymbol)
            socket?.write(string: "{\"topic\": \"iex:securities:\(withSymbol)\",\"event\": \"phx_join\",\"payload\": {},\"ref\": null}")
        }
    }
    
    func unSubscribeToTicker(_ withSymbol: String) {
        if let index = subscribedSymbols.index(of: withSymbol) {
            subscribedSymbols.remove(at: index)
            socket?.write(string: "{\"topic\": \"iex:securities:\(withSymbol)\",\"event\": \"phx_leave\",\"payload\": {},\"ref\": null}")
        }
    }
    
    func heartbeat() {
        socket?.write(string: "{\"topic\": \"phoenix\",\"event\": \"heartbeat\",\"payload\": {},\"ref\": null}")
    }
    
    func searchForTickerSymbol(searchQuery: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = getRequestForURL(urlString: "https://api.intrinio.com/companies?query=\(searchQuery)")

        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: completionHandler)
        task.resume()
    }
    
    func updateSymbolData(_ withSymbol: String, completionHandler: @escaping (String?, PriceResponse?) -> Void) {
        let request = getRequestForURL(urlString: "https://api.intrinio.com/prices?identifier=\(withSymbol)")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            let decoder = JSONDecoder()
            do {
                let priceResponse: PriceResponse = try decoder.decode(PriceResponse.self, from: data!)
                
                DispatchQueue.main.async {
                    completionHandler(withSymbol, priceResponse)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    func symbolUpdateDataRecieved(_ withData: Data?, response: URLResponse?, error: Error?) -> Void {
        
    }
    
    private func getRequestForURL(urlString: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
        let base64LoginString = loginData.base64EncodedString(options: NSData.Base64EncodingOptions())
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func websocketDidConnect(socket: WebSocket) {
        connectionReady = true
        
        heartbeater = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.heartbeat()
        }
        
        DispatchQueue.main.async {
            self.eventReady!()
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        connectionReady = false
        heartbeater?.invalidate()
        print("websocket is disconnected: \(error?.localizedDescription)")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let decoder = JSONDecoder()
        do {
            let iexEvent: IEXEvent = try decoder.decode(IEXEvent.self, from: text.data(using: .utf8)!)
            
            DispatchQueue.main.async {
                self.eventHandler!(iexEvent)
            }
        } catch {
            print(error)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        let decoder = JSONDecoder()
        do {
            let iexEvent: IEXEvent = try decoder.decode(IEXEvent.self, from: data)
            
            DispatchQueue.main.async {
                self.eventHandler!(iexEvent)
            }
        } catch {
            print(error)
        }
    }
}
