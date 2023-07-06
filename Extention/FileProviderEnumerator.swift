//
//  FileProviderEnumerator.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import ipfs_api
import os

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier
    private let anchor = NSFileProviderSyncAnchor("an anchor".data(using: .utf8)!)
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
        
        
        Task{
            do {
                var filepath:String = "/"
                var items: [Item] = []
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                    filepath += enumeratedItemIdentifier.rawValue
                }
                
                let fileslist = try await FilesList(filepath: filepath)
                
                guard let list = fileslist.Entries else {
                    observer.didEnumerate(items)
                    observer.finishEnumerating(upTo: nil)
                    return
                }
                
                print(list)
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                    
#warning("properly format this")
                    list.forEach { element in
                        var e = element
                        var fpath = enumeratedItemIdentifier.rawValue+element.Name
                        e.Name = enumeratedItemIdentifier.rawValue+"/"+element.Name
                        items.append(Item(fileItem: e, parentItem: enumeratedItemIdentifier, filePath: fpath))
                    }
                } else {
                    list.forEach { element in
                        var fpath = enumeratedItemIdentifier.rawValue+element.Name
                        items.append(Item(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath))
                    }
                }
                
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: nil)
                    
            } catch {
                print(error)
            }
        }
        
//        observer.didEnumerate([Item(identifier: NSFileProviderItemIdentifier("a file")),Item(identifier: NSFileProviderItemIdentifier("11 b file")),Item(identifier: NSFileProviderItemIdentifier("22 c file.csv"))])
//        observer.finishEnumerating(upTo: nil)
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
        observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(anchor)
    }
}
