//
//  ReviewModel.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import Foundation

struct surveryItem :Codable, Hashable, Identifiable{
    var id = UUID()
    var question: String
    var choices: [String]
    
    
}

extension surveryItem{
    
    static func dailyQuestions() -> [surveryItem]{
        var todayQuestions = [surveryItem]()
        
        var oneToTen = [String]()
        
        for num in 1...10{
            oneToTen.append("\(num)")
        }
        
        todayQuestions.append(surveryItem(
            question: "Rate from 1-10 how many hours you spent interacting with the AI today",
            choices: oneToTen)
        )
        
        todayQuestions.append(surveryItem(
            question: "Rate from 1-10 how many hours you spent interacting with other people today",
            choices: oneToTen)
        )
        
        todayQuestions.append(surveryItem(question: "How positive or negative was your mood today?",
                                 choices: [
                        "1) Very Negative",
                        "2) Negative",
                        "3) Neither positive nor negative",
                        "4) Positive",
                        "5) Very Positive"
                    ]) )
        
        
        
        return todayQuestions
    }
    
    
    static func weeklyQuestions() -> [surveryItem]{
        var weeklyQuestions = [surveryItem]()
        
        var oneToSevenSCI = [String]()
        
        for num in 1...7{
            var option = ""
            
            if num == 1{
                option = "1. Not close at all"
                
            } else if num == 4{
                option = "4. Somewhat close"
                
            }else if num == 7{
                option = "7. Very Close"
                
            }else{
                option = "\(num)"
            }
                
                
            oneToSevenSCI.append(option)
        }
        
        
        
        
        
        var oneToSevenNMI = [String]()
        
        for num in 1...7{
            var option = ""
            
            if num == 1{
                option = "1. Strongly Disagree"
                
            }else if num == 7{
                option = "7. Strongly Agree’ "
                
            }else{
                option = "\(num)"
            }
                
                
            oneToSevenNMI.append(option)
        }
        
        
        //MARK: SCI Scale: From Berscheid, Snyder & Omoto (1989)
        
        weeklyQuestions.append(surveryItem(
            question: "Relative to all your other relationships (both same and opposite sex) how would you characterize your relationship with the AI?",
            choices: oneToSevenSCI)
        )
        
        weeklyQuestions.append(surveryItem(
            question: "Relative to what you know about other people's close relationships, how would you characterize your relationship with the AI?",
            choices: oneToSevenSCI)
        )
    

        //MARK: Network Management Inventory: from Gillath et al. (2011)
        
        
        
        return weeklyQuestions
    }
    
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
