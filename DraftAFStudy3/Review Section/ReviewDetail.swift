//
//  ReviewDetail.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import CardStack
import SwiftUI


struct Survey : View {

    @State private var items = surveryItem.allQuestions()
    
    @State private var currentIndex = 0 // holds the index of the current top card
    @State private var shownIndex = 1
    
    //This func makes sure that the number of questions being displayed is never 0/20 or 21/20. The parameter is there to satisfy the requirements of On Change
    private func updateShownIndex(_ newValue: Int){
        //TODO: Test with print statements
        if currentIndex <= 0 {
            shownIndex = 1
            
        }else if currentIndex >= items.count - 1{
            shownIndex = items.count
        }
        
        else{
            shownIndex = currentIndex + 1
        }
    }

    var body: some View {
        
        VStack {
    
            Text("Swipe left or right to navigate between questions")
                .font(.caption)
                .padding()
            
            
            // Card Stack
            CardStack(items, currentIndex: $currentIndex) { item in
                SingleChoiceResponseView(question: item.question, choices: item.choices)
                    .cornerRadius(20)
            }
        
        }
        .navigationTitle("Question \(shownIndex) of \(items.count)")
        .onChange(of: currentIndex, perform: updateShownIndex)
        
        
        
    }
}



struct ReviewDetail: View{
    
    @State private var mood: Double = 0
    @State private var timeSpent: Double = 0
    
    private let moodColors: [Color] = [.red,
                                       .yellow,
                                       .blue,
                                       .mint,
                                       .green]
    
    
    
    var body: some View{
        
        VStack{
    
            Group{
                Text("How Much Time Did You Spend With The Chat Bot?")
                    .font(.subheadline)
                    .padding()
               
                Text("\(Int(timeSpent.rounded()))/10")
                    .padding()
                    .font(.subheadline)
                
                HStack{
                    Text("A Little 1/10")
                    Spacer()
                    
                    Text("Fair 5/10")
                    
                    Spacer()
                    
                    Text("Alot 10/10")
                }
                
                Slider(value: $timeSpent, in: 0...10)
                    .padding()
            }
    
            
            Group{
                Text("How was your day?")
                    .font(.subheadline)
                    .padding()
                
                HStack{
                    Text("Very Negative")
                        .foregroundColor(.red)
                    Spacer()
                    
                    Text("Meh")
                    
                    Spacer()
                    
                    Text("Very Positive")
                        .foregroundColor(.green)
                }
                
                Slider(value: $mood, in: 0...4, step: 1)
                    .accentColor(moodColors[Int(mood.rounded())])
                    .padding()
            }
            
            Text("Other Prompts Come Here")
                .padding()
            
            
            Button("Submit"){
                
            }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Sliders Here")
    }
}


struct ReviewDetail_Previews: PreviewProvider {
    static var previews: some View {
        Survey()
    }
}
