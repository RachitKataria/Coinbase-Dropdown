//
//  AppDelegate.swift
//  Coinbase_Dropdown
//
//  Created by Rachit Kataria on 3/1/18.
//  Copyright © 2018 Rachit Kataria. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var bitcoinMenuItem = NSMenuItem(title: " BTC: --", action: #selector(openCB), keyEquivalent: "")
    var ethereumMenuItem = NSMenuItem(title: " ETH: --", action: #selector(openCB), keyEquivalent: "")
    
    var year: String!, month: String!, day: String!
    var yesterdayETHPrice: Double!, yesterdayBTCPrice: Double!
    
    func setYesterdayDate() {
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        year =  String(components.year!)
        month = components.month! < 10 ? "0" + String(components.month!) : String(components.month!)
        day = components.day! < 10 ? "0" + String(components.day!) : String(components.day!)
        
        setYesterdayPrices()
    }
    
    func setYesterdayPrices() {
        let date_param = year + "-" + month + "-" + day
        
        let btc_url = "https://api.coinbase.com/v2/prices/BTC-USD/spot?date=" + date_param
        Alamofire.request(btc_url).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let spot_price = JSON(responseData.result.value!)
                print(spot_price)
                self.yesterdayBTCPrice = (spot_price["data"]["amount"]).doubleValue
            }
        }
        
        let eth_url = "https://api.coinbase.com/v2/prices/ETH-USD/spot?date=" + date_param
        Alamofire.request(eth_url).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let spot_price = JSON(responseData.result.value!)
                print(spot_price)
                self.yesterdayETHPrice = (spot_price["data"]["amount"]).doubleValue
            }
        }
    }
    
    @objc func openCB(sender: Any?) {
        if let url = URL(string: "https://www.coinbase.com/dashboard") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func createAttributedTitle(currency: String!, price: Double!)->NSAttributedString {
        
        let fullString = NSMutableAttributedString(string: "")
        
        // create our NSTextAttachment
        let arrow = NSTextAttachment()
        var arrowName: String!
        var priceTitle: String!
        
        // update format of price to include commas
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.currency
        let formattedPrice = numberFormatter.string(from: NSNumber(value:price))!
        
        if(currency == "BTC") {
            priceTitle = " BTC: " + formattedPrice

            if(price >= yesterdayBTCPrice) {
                arrowName = "green_arrow"
            } else {
                arrowName = "red_arrow"
            }
        } else if(currency == "ETH") {
            priceTitle = " ETH: " + formattedPrice

            if(price >= yesterdayETHPrice) {
                arrowName = "green_arrow"
            } else {
                arrowName = "red_arrow"
            }
        }
        
        arrow.image = NSImage(named: NSImage.Name(arrowName))
        
        // Center arrow in text
        let font = NSFont.systemFont(ofSize: 12) //set accordingly to your font, you might pass it in the function
        let mid = font.descender + font.capHeight
        arrow.bounds = CGRect(x: 0, y: font.descender - arrow.image!.size.height / 2 + mid + 2, width: arrow.image!.size.width, height: arrow.image!.size.height).integral
        
        // wrap the attachment in its own attributed string so we can append it
        let arrowString = NSAttributedString(attachment: arrow)
        
        // add the NSTextAttachment wrapper to our full string, then add pricing info.
        fullString.append(arrowString)
        fullString.append(NSAttributedString(string: priceTitle))
        return fullString
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // Request BTC price
        Alamofire.request("https://api.coinbase.com/v2/prices/BTC-USD/spot").responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let exchange_rates = JSON(responseData.result.value!)
                let btcPrice = exchange_rates["data"]["amount"]
                let attributedTitle = self.createAttributedTitle(currency: "BTC", price: btcPrice.doubleValue)
                self.bitcoinMenuItem.attributedTitle = attributedTitle
            }
        }
        
        // Request ETH price
        Alamofire.request("https://api.coinbase.com/v2/prices/ETH-USD/spot").responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let exchange_rates = JSON(responseData.result.value!)
                let ethPrice = exchange_rates["data"]["amount"]
                let attributedTitle = self.createAttributedTitle(currency: "ETH", price: ethPrice.doubleValue)
                self.ethereumMenuItem.attributedTitle = attributedTitle
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set up yesterday's date
        setYesterdayDate()
        
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("bitcoin"))
            constructMenu()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(bitcoinMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(ethereumMenuItem)
        
        menu.autoenablesItems = false;
        statusItem.menu = menu
        statusItem.menu?.delegate = self;
    }
}
