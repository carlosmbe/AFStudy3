//
//  ReviewDetail.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import CardStack
import SwiftUI

struct surveryItem :Codable, Hashable, Identifiable{
    var id = UUID()
    var question: String
    var choices: [String]
    
    static func testData() -> [surveryItem]{
        
        var items = [surveryItem]()
        //MARK: DAILY
        items.append(surveryItem(question: "How positive or negative was your mood today?",
                                 choices: [
                        "1) Very Negative",
                        "2) Negative",
                        "3) Neither positive nor negative",
                        "4) Positive",
                        "5) Very Positive"
                    ]) )
        
        
        //MARK: Weekly
        items.append(surveryItem(question: "Satisfaction With Life Scale (SWLS): from Diener, Emmons, Larsen & Griffin (1985)",
                                 choices: [
                        "In most ways, my life is close to my ideal.",
                        "The conditions of my life are excellent.",
                        "I am satisfied with my life.",
                        "So far, I have gotten the important things I want in life.",
                        "If I could live my life over, I would change almost nothing."
                    ]) )
                     
        items.append(surveryItem(question: "Attachment to AI Scale: Developed by Gillath, Ai, Branicky, Keshmiri, Davison & Spaulding (2021)",
                                 choices: [
                        "It helps me to turn to my AI in times of need.",
                        "I usually discuss my problems and concerns with my AI.",
                        "I talk things over with my AI.",
                        "I find it easy to depend on my AI.",
                        "I don’t feel comfortable opening up to my AI.",
                        "I prefer not to show my AI how I feel deep down.",
                        "I often worry that my AI doesn’t really care for me",
                        "I’m afraid that my AI will abandon me.",
                        "I worry that my AI won’t care about me as much as I care about it"
                    ]) )
                     
        return items
                     
    }
}

struct Survey : View {

    @State private var items = surveryItem.testData()
    @State private var currentIndex = 0 // holds the index of the current top card

    var body: some View {
        VStack {
            // Counter on top
            
                Text("Question \(currentIndex + 1) of \(items.count)")
                    .font(.title2)
                    .padding([.top, .horizontal])
                Text("Swipe left or right to navigate between questions")
                    .font(.caption)
                    .padding(.bottom)
            
            
            // Card Stack
            CardStack(items, currentIndex: $currentIndex) { item in
                MultipleChoiceResponseView(question: item.question, choices: item.choices)
                    .cornerRadius(20)

            }
            
          
            // Instruction for users to swipe
            .help("Swipe left or right to navigate between questions or press 'Next'")
        }
    }
}

struct MultipleChoiceResponseView: View {
    var question: String
    var choices: [String]
    
    @State private var selectedIndices: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading) {
            Text(question)
                .font(.title3)
                .padding(.horizontal)

            ScrollView {
                VStack {
                    ForEach(choices.indices, id: \.self) { index in
                        Button(action: {
                            if selectedIndices.contains(index) {
                                selectedIndices.remove(index)
                            } else {
                                selectedIndices.insert(index)
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(selectedIndices.contains(index) ? Color.green : Color(.systemGray5))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        selectedIndices.contains(index) ?
                                            Image(systemName: "checkmark").foregroundColor(.white) : nil
                                    )
                                Text(choices[index])
                                    .fontWeight(selectedIndices.contains(index) ? .bold : .regular)
                                    .foregroundColor( Color(.label ) )
                                    .padding()
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .overlay(RoundedRectangle(cornerRadius: 28)
                                    .stroke(selectedIndices.contains(index) ? Color.green : Color(.systemGray5), lineWidth: 2) )
                        .background(RoundedRectangle(cornerRadius: 28).fill(Color(.secondarySystemGroupedBackground)))
                        .padding(EdgeInsets.init(top: 3, leading: 35, bottom: 3, trailing: 35))
                    }
                }
            }
        }
       // .padding()
       // .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(20)
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
        ReviewDetail()
    }
}
