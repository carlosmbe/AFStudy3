//
//  MultipleChoiceResponseView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//

import SwiftUI

struct MultipleChoiceResponseView: View {
    var question: String = ""
    var choices: [String] = [""]
    
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

struct MultipleChoiceResponseView_Previews: PreviewProvider {
    static var previews: some View {
        MultipleChoiceResponseView()
    }
}
