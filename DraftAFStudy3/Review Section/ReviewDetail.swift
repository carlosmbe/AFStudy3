//
//  ReviewDetail.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum SurveyState {
    case notStarted
    case inProgress
    case completed
}

struct Survey : View {
    
    @State private var surveyFinished = false
    @State private var showCompletionAlert = false
    
    @StateObject private var viewModel = SurveyViewModel()
    var items: [surveryItem] {
        viewModel.items
    }
    
    @State private var currentIndex = 0
    @State private var shownIndex = 1
    @State private var selectedChoice: Int? = nil
    @State private var answers: [Int?] = []
    
    @State private var pickerSelection: Int = 0

    
    private func updateShownIndex(_ newValue: Int){
        shownIndex = min(max(1, currentIndex + 1), items.count)
    }
    
    var body: some View {
        let _ =  print("surveyFinished: \(surveyFinished), showCompletionAlert: \(showCompletionAlert), selectedChoice: \(String(describing: selectedChoice))")
        
        if !items.isEmpty {
            VStack {
                NavigationLink(destination: ChatView().navigationBarBackButtonHidden(true), isActive: $surveyFinished) { EmptyView() }
                
                
                if items[currentIndex].usePicker {
                    // Display the picker view
                    
                    TimePickerView(question: items[currentIndex].question,
                                    answers: $answers,
                                   index: currentIndex)
                    .padding()
                    
                    Spacer()
                    
                } else {
                    // Display the single choice view
                    SingleChoiceResponseView(question: items[currentIndex].question,
                                             choices: items[currentIndex].choices ?? [],
                                             selectedIndex: $selectedChoice)
                    .cornerRadius(20)
                }
                
                
                
                HStack {
                    if currentIndex > 0 {
                        Button("Previous") {
                            answers[currentIndex] = selectedChoice
                            currentIndex -= 1
                            selectedChoice = answers[currentIndex]
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                    
                    if currentIndex < items.count - 1 {
                        Button("Next") {
                            if items[currentIndex].usePicker {
                                // For picker questions, the answer is already updated in the `answers` array
                                currentIndex += 1
                            } else {
                                // For multiple choice questions
                                if let choice = selectedChoice {
                                    answers[currentIndex] = choice
                                    currentIndex += 1
                                } else {
                                    // Show alert if no choice is selected
                                    showCompletionAlert = true
                                }
                            }

                            // Reset selectedChoice for the next question
                            selectedChoice = answers[currentIndex]

                            // Additional logic if needed
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            currentIndex >= items.count ||
                            currentIndex >= answers.count ||
                            (items[currentIndex].usePicker ? answers[currentIndex] == nil : selectedChoice == nil)
                        )

                    }
                    
                    if currentIndex == items.count - 1 {
                        
                        
                        Button("Submit"){
                            print("Submit button tapped")
                            if selectedChoice != nil {
                                answers[currentIndex] = selectedChoice
                                
                                // Call the function but use a completion handler to know when it's done
                                submitSurvey(answers: answers) { success in
                                    if success {
                                        print("Success is Done.")
                                        showCompletionAlert = true  // This triggers the transition to ChatView
                                    } else {
                                        // Handle the error. Maybe show an error alert or something similar
                                        print("There was an error submitting the survey.")
                                    }
                                }
                            } else {
                                print("selectedChoice is nil.")
                                //  showCompletionAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedChoice != nil ? false : true)
                        .alert("Thank you for completing the survey!", isPresented: $showCompletionAlert) {
                            Button("OK") {
                                surveyFinished = true
                            }
                        }
                    }
                }
                .padding()
                .frame(minHeight: CGFloat(50))
                .padding()
            }
            .navigationTitle("Question \(shownIndex) of \(items.count)")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: currentIndex, perform: updateShownIndex)
            .onAppear {
                answers = Array(repeating: nil, count: items.count)
            }
        } else {
            VStack{
                Text("Loading questions...")
                ProgressView()
            }
        }
    }
    
    private func submitSurvey(answers: [Int?], completion: @escaping (Bool) -> Void) {
        print("Submit Survey Started")
        guard let userID = Auth.auth().currentUser?.uid, let userDisplayName = Auth.auth().currentUser?.displayName else {
            print("User is not logged in")
            completion(false)
            return
        }
        
        print("UserID: \(userID), DisplayName: \(userDisplayName)")
        
        let db = Firestore.firestore()
        var data: [String: Any] = [:]
        data["userName"] = userDisplayName
        
        for i in 0..<answers.count {
            let question = items[i].question
            if items[i].usePicker {
                // Handle picker response
                
                if let totalMinutes = answers[i] {
                    let hours = totalMinutes / 60
                    let minutes = totalMinutes % 60
                    data[question] = String(format: "%02d hours and %02d minutes", hours, minutes)
                } else {
                    data[question] = "No response"
                }
                    
                } else {
                    // Handle single choice response
                    if let answerIndex = answers[i], let choices = items[i].choices, choices.indices.contains(answerIndex) {
                        let answer = choices[answerIndex]
                        data[question] = answer
                    } else {
                        // Handle nil or out-of-range index
                    data[question] = "No response"
                }
            }
        }
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        let dateString = formatter.string(from: date)
        
        db.collection("UserSurveys")
            .document(userID)
            .collection("surveyItems")
            .document(dateString)
            .setData(data) { error in
                if let error = error {
                    print("Error writing survey to Firestore: \(error)")
                    completion(false)  // Indicate failure
                } else {
                    print("Survey data successfully written to Firestore")
                    UserDefaults.standard.set(date, forKey: "lastSurveyDate")
                    completion(true)  // Indicate success
                }
            }
        print("Data to be uploaded: \(data)")
    }
    
}


struct ReviewDetail_Previews: PreviewProvider {
    static var previews: some View {
        Survey()
    }
}

struct TimePickerView: View {
    var question: String
    @Binding var answers: [Int?]
    var index: Int

    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0

    private var safeSelectedTime: Binding<(Int, Int)> {
        Binding(
            get: {
                guard answers.indices.contains(index), let totalMinutes = answers[index] else { return (0, 0) }
                return (totalMinutes / 60, totalMinutes % 60)
            },
            set: { newValue in
                if answers.indices.contains(index) {
                    answers[index] = newValue.0 * 60 + newValue.1
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Rectangle()
                    .fill(Color(hex: "1D6F8A"))
                    .frame(width: 10, height: 10)
                    .cornerRadius(2)
                    .padding(.top, 8)

                Text(question)
                    .font(.title3)
            }

            HStack {
                Picker("Hours", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) {
                        Text("\($0) hr")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .onChange(of: selectedHour) { _ in safeSelectedTime.wrappedValue = (selectedHour, selectedMinute) }

                Picker("Minutes", selection: $selectedMinute) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0) min")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .onChange(of: selectedMinute) { _ in safeSelectedTime.wrappedValue = (selectedHour, selectedMinute) }
            }
        }
    }
}
