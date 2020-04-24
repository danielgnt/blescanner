//
//  HTTPSync.swift
//  BLEScanner
//
//  Created by Daniel Günther on 23.04.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//

import UIKit

let httpsync = HTTPSync()

class HTTPSync {
    private var host : String = ""
    
    func sync(host: String){
        self.host = host
        UserDefaults.standard.set(host, forKey: "host")
        print("Syncing to " + host)
        sendJSON(href: "which", json: ble_manager.getWhich())
    }
    
    func sendJSON(href: String, json: [String: Any]){
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: "http://"+self.host+"/" + href)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                self.responseReceived(href: href, json: responseJSON)
            }
        }

        task.resume()
    }
    
    func responseReceived(href: String, json: [String: Any]){
        if(href=="which"){
            sendJSON(href: "sync", json: ble_manager.getData(sync: json))
        }
    }
}
