//
//  SurveyViewModel.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-10-28.
//

//TODO: Let users choose time similar to the timer layour in CLock app

import FirebaseAuth
import FirebaseFirestore


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
                items = surveryItem.allQuestions()
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
                print("date : \(date)")
                completion(date)
            } else {
                completion(nil)
            }
        }
    }
}

extension SurveyViewModel {
    func checkChatEligibility() {
        // Check UserDefaults first
        if let lastDate = UserDefaults.standard.object(forKey: "lastSurveyDate") as? Date {
            self.isEligibleForChat = Calendar.current.isDateInToday(lastDate)
            print("Eligibility from UserDefaults: \(self.isEligibleForChat)")
        } else {
            // Fetch from Firestore if not found in UserDefaults
            fetchLastSurveyDateFromFirestore { dateFromFirestore in
                if let fetchedDate = dateFromFirestore {
                    self.isEligibleForChat = Calendar.current.isDateInToday(fetchedDate)
                    print("Eligibility from Firestore: \(self.isEligibleForChat)")
                } else {
                    self.isEligibleForChat = false
                    print("No survey data found. User is not eligible for chat.")
                }
            }
        }
    }

    
    
}


