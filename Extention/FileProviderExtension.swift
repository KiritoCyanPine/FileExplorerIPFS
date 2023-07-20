//
//  FileProviderExtension.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import Foundation
import ipfs_api
import os.log

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    let domain: NSFileProviderDomain
    static var manager: NSFileProviderManager? = nil
    
    let temporaryDirectoryURL: URL
    
    let logger = Logger(subsystem: "com.cylogic.FileExplorerIPFS", category: "Extention")
    
    required init(domain: NSFileProviderDomain) {
        self.domain = domain
        FileProviderExtension.manager = NSFileProviderManager(for: domain)!
        
        do {
            temporaryDirectoryURL = try FileProviderExtension.manager!.temporaryDirectoryURL()
        } catch {
            fatalError("failed to get temporary directory: \(error)")
        }
        
        super.init()
    }
    
    
#warning("implement FileProviderExtension invalidate() method to cleanup any resource")
    func invalidate() {
        // TODO: cleanup any resources
    }
    
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        Task {
            
            if identifier == .rootContainer || identifier == .trashContainer || identifier == .workingSet {
                completionHandler(Item(identifier: identifier ), nil)
                return
            }
            
            if identifier.rawValue == "/" {
                completionHandler(Item(identifier: .rootContainer ), nil)
                return
            }
            
            var fpath = "/"
            fpath += identifier.rawValue
            
#warning("try to see if you can remove files Stat")
            let Filestat = try await FilesStat(filepath: fpath)
            
            let file = File(
                Name: identifier.rawValue,
                Hash: Filestat.Hash,
                Size: Filestat.Size,
                type: Filestat.`Type` == "directory" ? 1:0
            )
            
            let parentIdentifier = self.getParentIdentifier(of: identifier.rawValue)
            
            completionHandler(Item(fileItem: file,parentItem: parentIdentifier), nil)
            return
        }
        
        return Progress()
    }
    
#warning("update fetch contents to open the file directly if possible")
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        
        var progress = Progress()
        
        var _ =  self.item(for: itemIdentifier, request: request) { item, err in
            
            do {
                let filepath = "/"+(item?.itemIdentifier.rawValue)!
                let dataURL = self.makeTemporaryURL("fetchedContents")
                
#warning("use progress from this Downloader if possible..")
                progress = try FilesReadDownload(filepath: filepath, file: dataURL) { err in
                    if let error = err {
                        self.logger.error("❌ Error In FetchContents : FilesReadDownload,\(error)")
                    }
                    
                    defer {
                        if let item = item {
                            self.evictItem(Item: item)
                        }
                    }
                    
                    completionHandler(dataURL, item, nil)
                }
                
            } catch let error {
                self.logger.error("❌ Error In FetchContents : , \(error)")
                completionHandler(nil, item, error)
            }
            
        }
        
        return progress
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: a new item was created on disk, process the item's creation
        
        guard let cType = itemTemplate.contentType else{
            completionHandler(itemTemplate, [],false,NSFileProviderError(NSFileProviderError.Code.noSuchItem))
            return Progress()
        }
        
        var filepath: String
        
        if itemTemplate.parentItemIdentifier == .rootContainer {
            filepath = "/"+itemTemplate.filename
        } else {
            filepath = itemTemplate.parentItemIdentifier.rawValue+"/"+itemTemplate.filename
            
            if !filepath.hasPrefix("/") {
                filepath = "/"+filepath
            }
        }
        
        let fpath = filepath
        
#warning("createItem(), Properly handle creation of folders.")
        switch cType{
        case .folder:
            Task{
                do {
                    
                    try await FilesMkDir(filepath: fpath)
                    
                    let folder = File(Name: fpath, Hash: "", Size: 0, type: 1)
                    
                    let parentIdentifier = getParentIdentifier(of: fpath)
                    
                    let item = Item(fileItem: folder,parentItem: parentIdentifier)
                    
                    completionHandler(item, [], false, nil)
                } catch {
                    self.logger.error("❌ Error In CreateItem <FOLDER>: , \(error)")
                }
                
                return
            }
        default:
#warning("createItem(), implement for creation of files")
            Task {
                do{
                    try await self.WriteToIPFS(filePath: fpath, url: url)
                    
                    print("Creating File ", fpath)
                    
                    let filestat = try await FilesStat(filepath: fpath)
                    
                    let file = File(
                        Name: fpath,
                        Hash: filestat.Hash,
                        Size: filestat.Size,
                        type: filestat.`Type` == "directory" ? 1:0
                    )
                    
                    let parentIdentifier = self.getParentIdentifier(of: fpath)
                    
                    let newitem = Item(fileItem: file, parentItem: parentIdentifier)
                    
                    defer {
                            self.evictItem(Item: newitem)
                    }
                    
                    completionHandler(newitem, [], false, nil)
                    
                } catch {
                    self.logger.error("❌ Error In CreateItem <DEFAULT>: , \(error)")
                }
            }
        }
        
        let mayExist = options.contains(NSFileProviderCreateItemOptions.mayAlreadyExist)
        if mayExist {
            completionHandler(nil, [], false, nil)
        }
        
        return Progress()
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        
        completionHandler(item, [], false, nil)
        return Progress()
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        
        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        
        var container = containerItemIdentifier
        
        if containerItemIdentifier == .rootContainer{
            container = NSFileProviderItemIdentifier("/")
        }
        
        return FileProviderEnumerator(enumeratedItemIdentifier: container)
    }
}
