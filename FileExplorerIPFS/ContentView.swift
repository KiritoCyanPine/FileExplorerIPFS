//
//  ContentView.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 07/06/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, Cydrive!")
            
            Button("Start Cydrive", action: startServe)
            
            Button("Stop Cydrive", action: endServe)
            
        }
        .padding()
    }
}

func startServe() {
        var _: () = FileProvide().applicationDidFinishLaunching()
}

func endServe() {
    var _: () = FileProvide().endCydrive()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
