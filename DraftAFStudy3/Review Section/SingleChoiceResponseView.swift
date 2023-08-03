//
//  MultipleChoiceResponseView.swift
//  DraftAFStudy3
//
//  Created by Carlos Mbendera on 2023-07-05.
//
import SwiftUI

struct SingleChoiceResponseView: View {
    var question: String = ""
    var choices: [String] = [""]

    @Binding var selectedIndex: Int?

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
            .padding(.horizontal)

            ScrollViewReader { reader in
                ScrollView {
                    VStack {
                        ForEach(choices.indices, id: \.self) { index in
                            Button(action: {
                                selectedIndex = index
                            }) {
                                HStack {
                                    Circle()
                                        .stroke(selectedIndex == index ? Color(.systemGray5) : Color.clear, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .fill(selectedIndex == index ? Color(hex: "1D6F8A") : Color(.systemGray5))
                                                .frame(width: 20, height: 20)
                                        )
                                    Text(choices[index])
                                        .fontWeight(selectedIndex == index ? .bold : .regular)
                                        .foregroundColor( Color(.label) )
                                        .padding()
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .overlay(RoundedRectangle(cornerRadius: 28)
                                     .stroke(Color(.systemGray5), lineWidth: 2) )
                            .background(RoundedRectangle(cornerRadius: 28).fill(Color(.secondarySystemGroupedBackground)))
                            .padding(EdgeInsets.init(top: 3, leading: 35, bottom: 3, trailing: 35))
                            .id(index) // Here we are assigning id to each element
                        }
                    }
                }
                .overlay(
                    VStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                reader.scrollTo(choices.count - 1, anchor: .bottom) // Scrolling to the last element
                            }
                        }) {
                            Image(systemName: "arrow.down")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .padding()
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                        .padding()
                    }
                    ,alignment: .bottomTrailing
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}

/*
struct SingleChoiceResponseView_Previews: PreviewProvider {
    static var previews: some View {
       // SingleChoiceResponseView(, selectedIndex: <#Binding<Int?>#>)
    }
}
*/
