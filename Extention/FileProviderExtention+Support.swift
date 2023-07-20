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
        
        var parentIdentifier = NSFileProviderItemIdentifier(String(parrawid.dropFirst(1)))
        
        if parrawid == "" {
            parentIdentifier = .rootContainer
        }
        
        return parentIdentifier
    }
    
    func makeTemporaryURL(_ purpose: String, _ ext: String? = nil) -> URL {
        if let ext = ext {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString).\(ext)")
        } else {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString)")
        }
    }
    
    func WriteToIPFS(filePath:String,url : URL?) async throws {
        let chunker = ChunkReader()
        
        guard let fileUrl = url else {
            throw ErrorChunkReader.InvalidFileAccessOperation("url is nil")
        }
        
        try chunker.open(url: fileUrl)
        
        defer {
            chunker.close()
        }
        
        let limit = try chunker.count()
        
        for index in stride(from: 0, to: limit+1, by: 1) {
            
            if let chunk = try chunker.getNext() {

                    var _ = try await FilesWrite(filepath: filePath, data: chunk.data,range: chunk.range)
                    self.logger.debug("[Writer] chunk processed \(index+1) to \(limit+1)")

                continue
            }
            
            break
        }
    }
}
