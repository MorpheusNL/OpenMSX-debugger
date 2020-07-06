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
    @IBOutlet weak var pidNumber: NSTextField!
    
    @IBOutlet weak var assemblyFilePath: NSTextField!
    @IBOutlet weak var assemblyMemoryLocation: NSTextField!
    
    @IBOutlet weak var connectedIndicatorLabel: NSTextField!

    @IBOutlet weak var logText: NSTextFieldCell!
    
    @IBOutlet weak var debugMemoryLocation: NSTextField!
    @IBOutlet weak var debugMemoryInfo: NSTextField!
    
    let MySock = SockData()
    
    var selectedFile : URL?
    
    // create empty breakpoint dictionary
    var breakpoints = [1: "", 2: "", 3: "", 4: ""]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup Observer to receive a message when the file has downloaded
        NotificationCenter.default.addObserver(self, selector:#selector(onDidReceiveMessage), name: .didReceiveData, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(onDidReceiveBreakpoint), name: .didReceiveBreakpoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveMemory), name: .didReceiveMemory, object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func pidEntered(_ sender: Any) {
        if let pid = Int(pidNumber.stringValue) {
            MySock.connectSocket(pid: pid)
        } else {
            let alert = NSAlert()
            alert.messageText = "PID not valid"
            alert.informativeText = "Please enter a valid PID number for the OpenMSX emulator. To find this number open a terminal and type:\n\nlsof -U | grep -i openmsx\n\nThe PID is the number of the extension of the socket filename.\nAlternatively open the debug console in OpenMSX and type pid."
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
        }
    }
    
    @IBAction func onRegsButtonPressed(_ sender: NSButton) {
        MySock.writeSocket(message: "<command>cpuregs</command>")
    }
    
    @IBAction func vdpregsButtonPressed(_ sender: Any) {
        MySock.writeSocket(message: "<command>vdpregs</command>")
    }
    
    @IBAction func onLoadButtonPressed(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.beginSheetModal(for: view.window!) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.selectedFile = panel.urls[0]
                self.assemblyFilePath.stringValue = self.selectedFile?.path ?? ""
                self.assemblyFilePath.isHidden = false
                let filePath = self.selectedFile?.path
                let memLocation = self.assemblyMemoryLocation.stringValue
                let str = "<command>load_debuggable memory \(filePath ?? "") 0x\(memLocation)</command>"
                self.MySock.writeSocket(message: str)
            }
        }
    }
    
    @IBAction func togglePowerSelected(_ sender: NSButtonCell) {
        switch sender.state {
        case .on:
            MySock.writeSocket(message: "<command>set power on</command>")
        case .off:
            MySock.writeSocket(message: "<command>set power off</command>")
        default:
            MySock.writeSocket(message: "<command>set power on</command>")
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "OpenMSX Debugger"
        alert.informativeText = "Connect the OpenMSX Debugger with OpenMSX running. First determine the PID of the OpenMSX emulator and click Connect.\n\nTo determine the PID open the debug console in OpenMSX (CMD+L in MacOS) and type PID.\n\nThe Z80 registers can be read out using Regs. If needed power on/off your virtual MSX by clicking the power button."
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    @IBAction func debugStepButtonPressed(_ sender: Any) {
        MySock.writeSocket(message: "<command>debug step</command>")
        
    }
    
    @IBAction func debugContinueButtonPressed(_ sender: Any) {
        MySock.writeSocket(message: "<command>debug cont</command>")
    }
    
    @IBOutlet weak var bpAddress: NSTextField!
   
    @IBOutlet weak var breakpointPopUpButton: NSPopUpButtonCell!
    
    @IBAction func setBreakPointButtonPressed(_ sender: Any) {
        let bpMemLocation = bpAddress.stringValue
        // TODO: check if connected
        if bpMemLocation != "" {
            MySock.writeSocket(message: "<command>debug set_bp \(bpMemLocation)</command>")
        }
    }
    
    @IBAction func refreshBreakpointButtonPressed(_ sender: Any) {
        MySock.setBreakPoint(message: "<command>debug list_bp</command>")
    }
    
    @IBAction func deleteBreakPointButtonPressed(_ sender: Any) {
        if let bpString = breakpointPopUpButton.selectedItem?.title {
            let breakPointID = bpString.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            print(breakPointID[0])
            breakpointPopUpButton.removeItem(withTitle: bpString)
            MySock.writeSocket(message: "<command>debug remove_bp \(breakPointID[0])</command>")
        }
        
    }
    
    @IBAction func memoryReadButtonPressed(_ sender: Any) {
        MySock.writeSocket(message: "<command>showmem \(debugMemoryLocation.stringValue)</command>", userInfo: "SHOWMEM")
    }
    
    @objc func onDidReceiveMessage(_ notification: Notification) {
        if let data = notification.userInfo as? [String: String] {
            if let message = data["MESSAGE"] {
                contentsLabel.stringValue = message
            }
            if let message = data["STATUS"] {
                if message == "CONNECTED" {
                    self.connectedIndicatorLabel.isHidden = false
                }
            }
            if let message = data["RAW"] {
                self.logText.stringValue = message
            }
        }
    }
    
    @objc func onDidReceiveBreakpoint(_ notification: Notification) {
        if let data = notification.userInfo as? [String: String] {
            if let message = data["BREAKPOINTS"] {
                breakpointPopUpButton.removeAllItems()
                for line in message.split(separator: "\n", maxSplits: 99, omittingEmptySubsequences: true) {
                    breakpointPopUpButton.addItem(withTitle: String(line))
                }
                
            }
        }
    }
    
    @objc func onDidReceiveMemory(_ notification: Notification) {
        if let data = notification.userInfo as? [String: String] {
            if let message = data["SHOWMEM"] {
                debugMemoryInfo.stringValue = message
            }
        }
    }
}

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
    static let didReceiveBreakpoint = Notification.Name("didReceiveBreakpoint")
    static let didReceiveMemory = Notification.Name("didReceiveMemory")
}
