//
//  ContentView.swift
//  BLEScanner
//
//  Created by Daniel Günther on 23.04.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//

import SwiftUI

struct ZButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.vertical,8)
            .padding(.horizontal)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(5)
    }
}

struct ZButtonRed: ButtonStyle{
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.vertical,8)
            .padding(.horizontal)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(5)
    }
}


struct ContentView: View{
    @State private var restartDelay: Int = 4000
    @State private var ipLocal: String = UserDefaults.standard.string(forKey: "host") ?? ""
    @State private var enableRestart = false
    @State private var filter = true
    @State private var isCapturing = false
    @State private var showingAlert = false
    @ObservedObject var ble_managerO = ble_manager
    
    var body: some View {
        VStack {
            VStack {
                Toggle(isOn: $enableRestart) {
                    Text("Enable Restart")
                }.padding(.horizontal).padding(.vertical, 6.0)
                HStack {
                    
                    Text("Restart Delay(ms):")
                    Spacer()
                    TextField("", value: $restartDelay, formatter: NumberFormatter()).frame(width: 140.0).textFieldStyle(RoundedBorderTextFieldStyle())
                    
                }.padding(.horizontal).padding(.vertical, 6.0).disabled(!enableRestart)
                Divider()
                Toggle(isOn: $filter) {
                    Text("Enable Filter")
                }.padding(.horizontal).padding(.vertical, 6.0)
            }.disabled(isCapturing)
            Divider()
            

            if (!isCapturing) {
                Button(action: {
                    ble_manager.set(restartDelay: self.restartDelay, enableRestart: self.enableRestart, filter: self.filter)
                    ble_manager.start()
                    self.isCapturing = true
                }){
                    Text("Start capturing")
                }.buttonStyle(ZButton())
            } else {
                VStack{
                    Button(action: {
                        ble_manager.stop()
                        self.isCapturing = false
                    }){
                        Text("Stop capturing")
                    }.buttonStyle(ZButtonRed())
                    Text("Status: \(ble_managerO.captureStatus)")
                }
            }
            
            Spacer()
            Button(action: {
                self.showingAlert = true
            }){
                Text("Delete All Files")
            }.buttonStyle(ZButtonRed())
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Are you sure?"),
                        message: Text("Files will be lost unless synced before!"),
                        primaryButton: .default(Text("Yes"), action: {
                            ble_manager.deleteAll()
                        }),
                        secondaryButton: .default(Text("No")))
            }
            Divider()
            Text("Synchronizes all data to server:").bold().padding(.top,10)
            HStack {
                TextField("Enter ip or hostname", text: $ipLocal).textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    httpsync.sync(host: self.ipLocal)
                }){
                    Text("Sync")
                }.buttonStyle(ZButton())
            }.padding(.horizontal).padding(.bottom, 20.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
