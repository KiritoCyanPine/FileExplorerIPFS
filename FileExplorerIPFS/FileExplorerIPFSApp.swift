//
//  FileExplorerIPFSApp.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 07/06/23.
//

import SwiftUI
import os
import FileProvider


class FileProvide {
    var identifier: NSFileProviderDomainIdentifier!
    var domain: NSFileProviderDomain!
    var providerConnection: ProviderConnection!
    
    init() {
        identifier = NSFileProviderDomainIdentifier(rawValue: "0000001")
        domain = NSFileProviderDomain(identifier: identifier, displayName: "0000001")
    }
    
    func endCydrive () {
        NSFileProviderManager.remove(domain) {error in
            print("Error : \(String(describing: error))")
            guard let error = error else {
                return
            }

            NSLog(error.localizedDescription)
        }
    }
    
    func applicationDidFinishLaunching() {
        os_log("application Started for FileProvider IPFS")
        NSFileProviderManager.add(domain) { error in
            print("Error : \(String(describing: error))")
            guard let error = error else {
                return
            }

            NSLog(error.localizedDescription)
        }
        
        providerConnection = ProviderConnection(domain: domain)
        providerConnection.resume()
    }
}


@main
struct FileExplorerIPFSApp: App {
    var body: some Scene {
        
        WindowGroup {
            ContentView()
        }
    }
}
