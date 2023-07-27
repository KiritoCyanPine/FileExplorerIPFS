//
//  FileProviderExtention+Support.swift
//  Extention
//
//  Created by Debasish Nandi on 19/07/23.
//

import FileProvider
import Foundation
import ipfs_api
import AppKit


extension FileProviderExtension {
    
    func getIPFSFileDetails(inpath fpath:String ) async throws -> Item {
        let itempath = URL.toItemIdentifier(path: fpath)
        
        let Filestat = try await FilesStat(filepath: fpath)
        
        let file = File(
            Name: itempath,
            Hash: Filestat.Hash,
            Size: Filestat.Size,
            type: Filestat.`Type` == "directory" ? 1:0
        )
        
        let parentIdentifier = self.getParentIdentifier(of: itempath)
        
        return Item(fileItem: file,parentItem: parentIdentifier)
    }
    
    func evictItem(Item fileIdentifier: NSFileProviderItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // call eviction on the enumerated item.
            FileProviderExtension.manager?.evictItem(identifier: fileIdentifier.itemIdentifier, completionHandler: { error in
                
                if let err = error {
                    
                    switch err{
                    case NSFileProviderError.noSuchItem:
                        return
                    case POSIXError.EBUSY:
                        return self.evictItem(Item: fileIdentifier )
                    default:
                        self.logger.error("❌ Eviction failed for the \(fileIdentifier.itemIdentifier.rawValue), dur to error \(err)")
                        return self.evictItem(Item: fileIdentifier)
                    }
                }
                
                self.logger.debug("[Eviction] : \(fileIdentifier.itemIdentifier.rawValue)")
            })
        }
    }
    
    func getParentIdentifier(of filePath:String) -> NSFileProviderItemIdentifier{
        let parrawid = filePath.components(separatedBy: "/").dropLast().joined(separator: "/")
        
        var parentIdentifier = NSFileProviderItemIdentifier(parrawid)
        
        if parrawid == "" {
            parentIdentifier = .rootContainer
        }
        
        return parentIdentifier
    }
    
    func WriteToIPFSWithProgress(filePath:String,url : URL?,enableTruncate:Bool = false, completion: @escaping (Error?) -> Void) throws -> Progress {
        let chunker = ChunkReader()
        
        guard let fileUrl = url else {
            completion(ErrorChunkReader.InvalidFileAccessOperation("url is nil"))
            return Progress()
        }
        
        try chunker.open(url: fileUrl)
        
        let limit = try chunker.count()
    
        Task{
            defer{ chunker.close() }
            
            var truncate = enableTruncate
            
            for index in stride(from: 0, to: limit+1, by: 1) {
                if let chunk = try chunker.getNext() {
                    
                    chunker.progress?.completedUnitCount = Int64(index+1)
                    
                    var _ = try await FilesWrite(filepath: filePath, data: chunk.data,range: chunk.range, truncate: truncate)
                    truncate = false
                    self.logger.info("[Writer] chunk processed \(index+1) to \(limit+1)")
                    
                    continue
                }
                
                break
            }
            
            completion(nil)
        }
        
        guard let writeprogress = chunker.progress else {
            completion(ErrorChunkReader.InvalidProgress)
            return Progress()
        }
        
        return writeprogress
    }
    
    func makeTemporaryURL(_ purpose: String, _ ext: String? = nil) -> URL {
        if let ext = ext {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString).\(ext)")
        } else {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString)")
        }
    }
    
    func WriteToIPFS(filePath:String,url : URL?,enableTruncate:Bool = false) async throws {
        let chunker = ChunkReader()
        
        guard let fileUrl = url else {
            throw ErrorChunkReader.InvalidFileAccessOperation("url is nil")
        }
        
        try chunker.open(url: fileUrl)
        
        defer {
            chunker.close()
        }
        
        let limit = try chunker.count()
        
        var truncate = enableTruncate
        
        for index in stride(from: 0, to: limit+1, by: 1) {
            
            if let chunk = try chunker.getNext() {

                    var _ = try await FilesWrite(filepath: filePath, data: chunk.data,range: chunk.range,truncate: truncate)
                    truncate = false
                    self.logger.debug("[Writer] chunk processed \(index+1) to \(limit+1)")

                continue
            }
            
            break
        }
    }
}

extension FileProviderExtension {
    
     func createFileInternal(fpath:String,url:URL?, completion : (Item?, Error?) -> Void) async {
        do{
            let filePath = URL.toIPFSPath(path: fpath)
            
            try await self.WriteToIPFS(filePath: filePath, url: url)
            
            let newitem = try await  getIPFSFileDetails(inpath: filePath)
            
            defer {
                    self.evictItem(Item: newitem)
            }
            
            completion(newitem, nil)
        } catch {
            completion(nil,error)
        }
    }
    
        func createFileInternalWithProgress(fpath:String,url:URL?, completion : @escaping (Item?, Error?) -> Void) -> Progress {
        do{
            let filePath = URL.toIPFSPath(path: fpath)

            let localPAth2 = url!.path
            
            let FileStatistics = try FileManager.default.attributesOfItem(atPath: localPAth2)
            
            let size = FileStatistics[.size] as? UInt64 ?? UInt64(0)
            
            let newitem = generatePlaceHolderItem(fpath: fpath, size: size)
            
            let prog = try self.WriteToIPFSWithProgress(filePath: filePath, url: url) { ErrorOptional in
                if let error = ErrorOptional {
                    self.logger.error("❌ [createitem] Files stat failed with error \(error) for path \(fpath)")
                    completion(nil, error)
                    return
                }
            }
            
            completion(newitem, nil)
            
            return prog
        } catch {
            completion(nil,error)
            return Progress()
        }
    }
    
     func generatePlaceHolderItem(fpath:String, size : UInt64) -> Item {
        let itempath = URL.toItemIdentifier(path: fpath)
        
        let file = File(
            Name: itempath,
            Hash: "",
            Size: size,
            type: 0
        )
        
        let parentIdentifier = self.getParentIdentifier(of: itempath)
        
        return Item(fileItem: file, parentItem: parentIdentifier)
    }
}
