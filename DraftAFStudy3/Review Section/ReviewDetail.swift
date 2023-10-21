//
//  ReviewDetail.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-06-26.
//

import CardStack
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    
    private func updateShownIndex(_ newValue: Int){
        shownIndex = min(max(1, currentIndex + 1), items.count)
    }
    
    var body: some View {
      let _ =  print("surveyFinished: \(surveyFinished), showCompletionAlert: \(showCompletionAlert), selectedChoice: \(String(describing: selectedChoice))")

        if !items.isEmpty {
            VStack {
              NavigationLink(destination: ChatView().navigationBarBackButtonHidden(true), isActive: $surveyFinished) { EmptyView() }

                SingleChoiceResponseView(question: items[currentIndex].question,
                                         choices: items[currentIndex].choices,
                                         selectedIndex: $selectedChoice)
                    .cornerRadius(20)
                
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
                            if selectedChoice != nil {
                                answers[currentIndex] = selectedChoice
                                currentIndex += 1
                                selectedChoice = answers[currentIndex]
                            } else {
                                showCompletionAlert = true
                            }
                        }
                         .buttonStyle(.borderedProminent)
                        .disabled(selectedChoice != nil ? false : true)
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
            let answerIndex = answers[i]!
            let answer = items[i].choices[answerIndex]
            let question = items[i].question
            data[question] = answer
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



enum SurveyState {
    case notStarted
    case inProgress
    case completed
}

class SurveyViewModel: ObservableObject {
    @Published var isEligibleForChat: Bool? = true
    @Published var items: [surveryItem] = []
    @Published var surveyState: SurveyState = .notStarted
    
    init() {
        fetchQuestions()
    }

    func fetchQuestions() {
        if let lastDate = UserDefaults.standard.object(forKey: "lastSurveyDate") as? Date {
            let differenceInDays = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
            
            if differenceInDays! >= 7 {
                items = surveryItem.weeklyQuestions()
            } else {
                items = surveryItem.dailyQuestions()
            }
        } else {
            fetchLastSurveyDateFromFirestore { (dateFromFirestore) in
                if let lastDate = dateFromFirestore {
                    UserDefaults.standard.set(lastDate, forKey: "lastSurveyDate")
                    self.fetchQuestions()  // Recursively fetch questions after setting date
                } else {
                    self.items = surveryItem.dailyQuestions()
                }
            }
        }
    }

    func fetchLastSurveyDateFromFirestore(completion: @escaping (Date?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        let db = Firestore.firestore()
        db.collection("UserSurveys").document(userID).collection("surveyItems").order(by: "date", descending: true).limit(to: 1).getDocuments { (snapshot, error) in
            if let documents = snapshot?.documents, let firstDoc = documents.first, let date = firstDoc.get("date") as? Date {
                completion(date)
            } else {
                completion(nil)
            }
        }
    }
}

extension SurveyViewModel {
    func checkChatEligibility() {
        if let lastDate = UserDefaults.standard.object(forKey: "lastSurveyDate") as? Date {
            let differenceInHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
            self.isEligibleForChat = differenceInHours < 24
            print(isEligibleForChat)
        } else {
            fetchLastSurveyDateFromFirestore { dateFromFirestore in
                if let _ = dateFromFirestore {
                    self.isEligibleForChat = false

                } else {
                    self.isEligibleForChat = true
                }
            }
        }
    }
}




struct ReviewDetail_Previews: PreviewProvider {
    static var previews: some View {
        Survey()
    }
}
