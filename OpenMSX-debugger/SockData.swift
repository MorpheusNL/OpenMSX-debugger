//
//  SockData.swift
//  MVCtest
//
//  Created by Chris Smit on 16/05/2020.
//  Copyright © 2020 Chris Smit. All rights reserved.
//

import Foundation

/* SockData Class
    func loadData()
    Reads data from a file or named pipe in the $TMPDIR location. Application Sandbox has been disabled in XCode to
    allow access to files outside the Sandbox.
    Reading occurs blocking and when reading a named pipe the application stalls until data is fed to the pipe.
    Making a pipe in a terminal: mkfifo namedpipe
    Writing data to a named pipe: cat Readme.txt > pipe
    Note a pipe can be recognized by the p before the access rights, e.g.:
    prw-r--r--     1 chris  staff       0 17 mei 16:17 textpipe
 */
struct SockData {
    let socketDescriptor : Int32
    let receiveBufferSize : Int = 1024
    
    // create dispatch queue for asynchronous socket operation
//    let dqueue = DispatchQueue(label: "MorpheusNL")
    
    init() {
        socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if socketDescriptor < 0 {
            print("Failed to initialize socket: \(errno)")
        } else {
            print("Socket created")
        }
        
//        connectSocket(pathToSocket: "/var/folders/m1/7g9ngbgj33b5qq_s8b4wv3dr0000gn/T//openmsx-chris/socket.20178")
    }
    
    // load data from a file
    func loadData() {
        
        var content = "Could not Read the File"
        
        let tmpPath = FileManager.default.temporaryDirectory
        
//        print("Temporary directory:\n\(tmpPath.path)")

        let filePath = tmpPath
            .appendingPathComponent("nl.CSolutions.MVCtest/Readme.txt")
              
        print("Reading file or named pipe: \(filePath.path)")
        
        if let fh = FileHandle.init(forReadingAtPath: filePath.path) {
            let fileContent = fh.readDataToEndOfFile()
            let str = String(decoding: fileContent, as: UTF8.self)
            content = str
//            print("Read file:\n \(str)")
            fh.closeFile()
        }
        
        let message = ["MESSAGE": content ]
        NotificationCenter.default.post(name: .didReceiveData, object: nil, userInfo: message)
    }
    
    func connectSocket(pid:Int) {
        let socketFileName = "socket.\(pid)"
        let userName = NSUserName()
        let socketName = "openmsx-\(userName)"
        
        let socketPath = FileManager.default.temporaryDirectory
        .appendingPathComponent(socketName)
        .appendingPathComponent(socketFileName)
        print(socketPath.path)
        connectSocket(pathToSocket: socketPath.path)
        let message = ["STATUS": "CONNECTED"]
        NotificationCenter.default.post(name: .didReceiveData, object: nil, userInfo: message)
    }
    
    // connectSocket creates sockaddr_un structure using pathToSocket and connects to socket
    func connectSocket(pathToSocket: String) {
        var sun_path = (Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0),
            Int8(0), Int8(0), Int8(0), Int8(0) )
        withUnsafeMutableBytes(of: &sun_path, {
            ptr in ptr.copyBytes(from: pathToSocket.utf8.prefix(pathToSocket.count))
        })
        var serverAddress = sockaddr_un(sun_len: UInt8(pathToSocket.count), sun_family: sa_family_t(AF_UNIX), sun_path: sun_path)

        let connectResult = withUnsafePointer(to: &serverAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {connect(socketDescriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.stride))})
        })
        if connectResult < 0 {print("Error connecting to socket: \(errno)")}
        else {
            print("Connected")
        }
        readSocket()
    }
    
    // read data from already connected socket
    func readSocket() {
        let receiveBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: receiveBufferSize)
        
        receiveBuffer.initialize(repeating: 0, count: receiveBufferSize)
        
//        defer {
//            receiveBuffer.deinitialize(count: receiveBufferSize)
//            receiveBuffer.deallocate()
//        }
        let receiveRawBuffer = UnsafeMutableRawPointer(receiveBuffer)

        // TODO: fix the queue
        DispatchQueue.main.async {
            _ = recv(self.socketDescriptor, receiveRawBuffer, self.receiveBufferSize, 0)
            let rxRawBufferPointer = UnsafeRawBufferPointer(start: receiveRawBuffer, count: self.receiveBufferSize)
            let content = self.convertSpecialCharacters(string: String.init(bytes: rxRawBufferPointer, encoding: .utf8) ?? "No reply")
            let str = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            let message = ["MESSAGE":  str, "RAW": content]
            NotificationCenter.default.post(name: .didReceiveData, object: nil, userInfo: message)
        }
                

    }
    
    // read data from already connected socket
    func readSocket(name aName: NSNotification.Name, userInfo: String = "") {
            let receiveBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: receiveBufferSize)
            
            receiveBuffer.initialize(repeating: 0, count: receiveBufferSize)
            
    //        defer {
    //            receiveBuffer.deinitialize(count: receiveBufferSize)
    //            receiveBuffer.deallocate()
    //        }
            let receiveRawBuffer = UnsafeMutableRawPointer(receiveBuffer)

            // TODO: fix the queue
            DispatchQueue.main.async {
                _ = recv(self.socketDescriptor, receiveRawBuffer, self.receiveBufferSize, 0)
                let rxRawBufferPointer = UnsafeRawBufferPointer(start: receiveRawBuffer, count: self.receiveBufferSize)
                let content = self.convertSpecialCharacters(string: String.init(bytes: rxRawBufferPointer, encoding: .utf8) ?? "No reply")
                let str = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                var message: [String:String] = ["":""]
                switch userInfo {
                case "SHOWMEM":
                    message = ["SHOWMEM": str]
                default:
                    message = ["BREAKPOINTS":  str ]
                }
                NotificationCenter.default.post(name: aName, object: nil, userInfo: message)
            }
                    

        }
    
    func convertSpecialCharacters(string: String) -> String {
            var newString = string
            let char_dictionary = [
                "&amp;" : "&",
                "&lt;" : "<",
                "&gt;" : ">",
                "&quot;" : "\"",
                "&apos;" : "'"
            ];
            for (escaped_char, unescaped_char) in char_dictionary {
                newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.literal, range: nil)
            }
            return newString
    }

    func writeSocket(message: String, userInfo: String="") {
        if let data = message.data(using: .utf8) {
            data.withUnsafeBytes( {write(socketDescriptor, $0, message.count)} )
        }
        if userInfo == "" {
            readSocket()
        }
        if userInfo == "SHOWMEM" {
            readSocket(name: .didReceiveMemory, userInfo: userInfo)
        }
        
    }
    
    func setBreakPoint(message: String) {
        if let data = message.data(using: .utf8) {
            data.withUnsafeBytes( {write(socketDescriptor, $0, message.count)} )
        }
        readSocket(name: .didReceiveBreakpoint)
        
    }
}

