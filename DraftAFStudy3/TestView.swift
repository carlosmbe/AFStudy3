//
//  TestView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-12-28.
//

import SwiftUI

struct TestView: View {
    
    @State var numberOfMinutes: Int = 0
    
    @State var data: [(String, [String])] = [
        ("One", Array(0...10).map { "\($0)" }),
        ("Two", Array(20...40).map { "\($0)" }),
        ("Three", Array(100...200).map { "\($0)" })
    ]
    @State var selection: [String] = [0, 20, 100].map { "\($0)" }
    
    var body: some View {
        VStack(alignment: .center) {
            
            HStack{
                
                Picker("How Many Minutes?", selection: $numberOfMinutes){
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Text("Minutes")
                    .bold()
                    .padding()
                  
                
            }
            Text("I've chatted with AI close to: \(numberOfMinutes) minutes")
            
            Text(verbatim: "Selection: \(selection)")
            MultiPicker(data: data, selection: $selection).frame(height: 300)
        }
        
        
        
        
    }
    
    /*#Preview {
     TestView()
     }
     */
    
    
    struct MultiPicker: View  {
        
        typealias Label = String
        typealias Entry = String
        
        let data: [ (Label, [Entry]) ]
        @Binding var selection: [Entry]
        
        var body: some View {
            GeometryReader { geometry in
                HStack {
                    ForEach(0..<self.data.count) { column in
                        Picker(self.data[column].0, selection: self.$selection[column]) {
                            ForEach(0..<self.data[column].1.count) { row in
                                Text(verbatim: self.data[column].1[row])
                                    .tag(self.data[column].1[row])
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width / CGFloat(self.data.count), height: geometry.size.height)
                        .clipped()
                    }
                }
            }
        }
    }
}

