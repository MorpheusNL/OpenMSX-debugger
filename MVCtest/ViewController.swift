//
//  ViewController.swift
//  MVCtest
//
//  Created by Chris Smit on 16/05/2020.
//  Copyright © 2020 Chris Smit. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var contentsLabel: NSTextField!
    
    let MySock = SockData()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup Observer to receive a message when the file has downloaded
        NotificationCenter.default.addObserver(self, selector:#selector(onDidReceiveMessage), name: .didReceiveData, object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onConnectButtonPressed(_ sender: NSButton) {
        sender.title = "Reset"
        contentsLabel.stringValue = ""
    }
    
    @IBAction func onLoadButtonPressed(_ sender: Any) {
//        let message = MySock.loadData()
//        contentsLabel.stringValue = message
        MySock.loadData()
    }
    
    @IBAction func onSocketButtonPressed(_ sender: Any) {
        MySock.loadSocket()
    }
        
    @objc func onDidReceiveMessage(_ notification: Notification) {
        if let data = notification.userInfo as? [String: String] {
            if let message = data["MESSAGE"] {
                contentsLabel.stringValue = message
            }
        }
    }
    
}

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
}
