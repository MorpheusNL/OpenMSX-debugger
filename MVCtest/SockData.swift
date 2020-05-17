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
class SockData {
    func loadData() {
        // load data from file
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
    
    func loadSocket() {
        print("in function loadSocket()")
    }
}

