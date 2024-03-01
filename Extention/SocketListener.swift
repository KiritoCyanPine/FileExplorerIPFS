//
//  Socket_Optional.swift
//  Cydrive
//
//  Created by Debasish Nandi on 09/10/23.
//

import Foundation
import os.log

class Socket {
    var sock:Int32
    var socklen:UInt32
    var serveraddr = sockaddr_in()
    var port:UInt16
    
    public struct Config {
        var port: UInt16
        var transportLayerType: Int32
        var internetlayerprotocol: Int32
        var ipprotocol: Int32
        
        var padding:Bool
    }
    
    init(configuration:Config) {
        sock = socket(configuration.internetlayerprotocol, configuration.transportLayerType, configuration.ipprotocol)
        
        socklen = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        port = configuration.port
        
        serveraddr.sin_family = sa_family_t(configuration.internetlayerprotocol)
        serveraddr.sin_port = in_port_t((port << 8) + (port >> 8))
        serveraddr.sin_addr = in_addr(s_addr: in_addr_t(0))
        
        if configuration.padding{
            serveraddr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        }
    }
}

class SocketHandler: Listener {
    private var logger: Logger
    
    private var sock:Int32 = 0
    private let socklen: UInt32
    private var serveraddr: sockaddr_in
    private var port:UInt16
    
    init(logging:Logger, socket: Socket) {
        logger = logging
        
        sock = socket.sock
        socklen = socket.socklen
        port = socket.port
        serveraddr = socket.serveraddr
    }
    
    func start(completionHandler: @escaping (Data?) -> Void) throws {
        withUnsafePointer(to: &serveraddr) { sockaddrInPtr in
            let sockaddrPtr = UnsafeRawPointer(sockaddrInPtr).assumingMemoryBound(to: sockaddr.self)
            bind(sock, sockaddrPtr, socklen)
        }
        
        listen(sock, 2)
        
        logger.log("[SOCKET] ✅ Event Handler listening on port \(self.port)")
        
        self.listenerDaemon { DataOpt in
            completionHandler(DataOpt)
        }
    }
    
    private func listenerDaemon(completionHandler: @escaping (Data?)-> Void) {
        repeat {
            let client = accept(sock, nil, nil)
            var buffer = [CChar](repeating: 0, count: UserDefaults.sharedContainerDefaults.kiloByteSize)
            read(client, &buffer, UserDefaults.sharedContainerDefaults.kiloByteSize)
            
            completionHandler(Data(bytes: &buffer, count: buffer.count))
            
            "HTTP/1.1 200 OK".withCString { bytes in
                send(client, bytes, Int(strlen(bytes)), 0)
                close(client)
            }
        
        } while sock > -1
    }
}
