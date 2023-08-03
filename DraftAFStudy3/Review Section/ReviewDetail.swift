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
                    }
                    
                    if currentIndex == items.count - 1 {
                        Button("Submit"){
                            if selectedChoice != nil {
                                answers[currentIndex] = selectedChoice
                                submitSurvey(answers: answers)
                            } else {
                                showCompletionAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
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
    
    private func submitSurvey(answers: [Int?]) {
        guard let userID = Auth.auth().currentUser?.uid, let userDisplayName = Auth.auth().currentUser?.displayName else {
            print("User is not logged in")
            return
        }

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
                } else {
                    print("Survey data successfully written to Firestore")
                    UserDefaults.standard.set(date, forKey: "lastSurveyDate")
                    showCompletionAlert = true
                }
            }
    }
}


class SurveyViewModel: ObservableObject {
    @Published var items: [surveryItem] = []
    
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
    func canAccessChat() -> Bool {
        if let lastDate = UserDefaults.standard.object(forKey: "lastSurveyDate") as? Date {
            let differenceInHours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
            return differenceInHours < 24
        } else {
            // If the date isn't available in UserDefaults, consider the user as not eligible.
            // Optionally, you can fetch from Firestore here as a fallback.
            return false
        }
    }
}



struct ReviewDetail_Previews: PreviewProvider {
    static var previews: some View {
        Survey()
    }
}
