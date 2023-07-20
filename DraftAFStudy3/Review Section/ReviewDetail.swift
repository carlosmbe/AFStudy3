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
    
    @State private var selectedChoice: Int? = nil
    
    @State private var showAlert = false
    
    @State private var answers: [Int?] = Array(repeating: nil, count: surveryItem.allQuestions().count)

    
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
            
            SingleChoiceResponseView(question: items[currentIndex].question,
                                     choices: items[currentIndex].choices,
                                     selectedIndex: $selectedChoice)
            
            .cornerRadius(20)
            
            HStack {
                if currentIndex > 0 {
                    Button("Previous") {
                        if currentIndex > 0 {
                            answers[currentIndex] = selectedChoice
                            currentIndex -= 1
                            selectedChoice = answers[currentIndex]
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                
                Spacer()
                
                if currentIndex < items.count - 1 {
                     Button("Next") {
                         if selectedChoice != nil {
                             answers[currentIndex] = selectedChoice
                             currentIndex += 1
                             selectedChoice = answers[currentIndex]
                         } else {
                             showAlert = true
                         }
                     }
                     .buttonStyle(.borderedProminent)
                     .alert("Please select an answer before proceeding.", isPresented: $showAlert) {
                         Button("OK", role: .cancel) {}
                     }
                 }
                
                if currentIndex == items.count - 1 {
                    Button("Submit"){
                        // Handle the submit action
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(minHeight: CGFloat(50)).padding()
        }
        .navigationTitle("Question \(shownIndex) of \(items.count)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentIndex, perform: updateShownIndex)
        
        
        
    }
}



struct ReviewDetail_Previews: PreviewProvider {
    static var previews: some View {
        Survey()
    }
}
