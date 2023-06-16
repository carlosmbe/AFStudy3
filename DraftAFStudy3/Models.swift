//
//  Models.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-14.
//

import Foundation
import SwiftUI

struct Message: Hashable{
    var isMe : Bool
    var messageContent : String
    var name : String?
    
   static func messageDummyData() -> [Message]{
        
        let test1 = Message(isMe: true, messageContent: "This is the first message and is a UI Example")
        let test2 = Message(isMe: false, messageContent: "Really!? This is a UI Example?")
        let test3 = Message(isMe: true, messageContent: "Yep :)")
       
       let testArray: [Message] = [test1, test2, test3]
       
       return testArray
    }
}

struct messageUI : View{
    
    @State var message : Message
    
    var body : some View{
        HStack{
            if message.isMe{
                Spacer()
            }
        
            Text(message.messageContent)
                .padding(10)
                .foregroundColor(message.isMe ? Color.white : Color.white)
                .background(message.isMe ? Color.blue : Color.indigo)
                .cornerRadius(10)
            
            if !message.isMe{
                Spacer()
            }
            
        }  .listRowBackground(Color.clear)
        
    }
}


