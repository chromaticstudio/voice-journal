//
//  SearchBar.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/9/24.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack (spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray) // Optionally adjust color

            TextField("Search journals", text: $searchText)
                .onChange(of: searchText) { oldState, newState in
                    // Optionally perform search filtering logic here
                    print("Search text changed to: \(newState)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color("SoftContrastColor"))
            .cornerRadius(10)
        }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchText: .constant(""))
    }
}
