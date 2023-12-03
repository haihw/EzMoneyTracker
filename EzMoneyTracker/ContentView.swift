//
//  ContentView.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 9/11/23.
//

import SwiftUI
import SwiftData
extension Float {
    var toString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: self as NSNumber) ?? ""
    }
}
extension String {
    var toNumericValue: Float? {
        let numericPart = self.dropLast().trimmingCharacters(in: .whitespaces)
        let unit = self.last?.lowercased() ?? ""
        let multiplier: Float
        switch unit {
        case "k":
            multiplier = 1_000
        case "m":
            multiplier = 1_000_000
        case "b":
            multiplier = 1_000_000_000
        default:
            multiplier = 1
        }

        if let numericValue = Float(numericPart) {
            return numericValue * multiplier
        } else {
            return nil
        }
    }

}
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var promptText = ""
    @State private var showOptions = false
    @State private var popoverOffset: CGSize = .zero
    @FocusState private var isFieldFocused: Bool

    @State private var showList = false
    var defaultCategory: Category? {
        let toLive = categories.filter { $0.name == "To Live"}.first
        return toLive
    }
    var listView: some View {
        return List {
            ForEach(transactions) { item in
                NavigationLink {
                    Text("On \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    Text("Category: \(item.category!.name)")
                    Text("You \(item.type == TransactionType.Expense ? "spent" : "got") \(item.amount.toString) \(item.currency.rawValue)")
                    Text("Description: \(item.memo)")
                    
                } label: {
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .omitted))
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
    var body: some View {
        NavigationSplitView {

            listView
            Text("Total Spend: \((transactions.reduce(0.0) { $0 + $1.amount}).toString) \(transactions.isEmpty ? "": transactions.first!.currency.rawValue)")
            VStack {
                if showOptions {
                    Button("Select Category") {
                        showOptions = true
                    }
                    .popover(isPresented: $showOptions, arrowEdge: .top) {
                        VStack {
                            ForEach(categories.map{$0.name}, id: \.self) { option in
                                Button(action: {
                                    promptText += "\(option)| "
                                    showOptions = false
                                }) {
                                    Text(option)
                                        .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(minWidth: 100, maxHeight: 200)
                    .presentationCompactAdaptation(.none)
                    .offset(popoverOffset)
                }
                TextField("Type something", text: $promptText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: promptText) {
                        if promptText.last == "/" {
                            // Simulate fetching options based on searchText
                            GeometryReader { geometry in
                                Color.clear.onAppear {
                                    let slashPosition = geometry.frame(in: .global).origin
                                    print("Slash position: \(slashPosition)")
                                    
                                    // Calculate the desired offset based on the slash position
                                    popoverOffset = CGSize(width: slashPosition.x, height: slashPosition.y)
                                }
                            }
                            showOptions = true
                        } else {
                            showOptions = false
                        }
                    }
                    .onSubmit {
                        submitPrompt(promptText)
                        promptText = ""
                        isFieldFocused = true
                    }
                    .focused($isFieldFocused)
                

            }
            
            
            .padding(.top, 8)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: destroyAllItems) {
                        Label("Destroy All", systemImage: "trash")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear(){
            checkDefaultData()
        }
    }
    
    private func checkDefaultData() {
        if self.categories.isEmpty {
            let expenseBaseCategory = Category(name: "Expense Base")
            let incomeBaseCategory = Category(name: "Income Base")
            
            let defaultCategories:[Category] =
            [Category(name: "To Live"),
             Category(name: "Have Fun"),
             Category(name: "Family Happiness"),
             Category(name: "Financial Freedom"),
             Category(name: "Community")
            ]
            expenseBaseCategory.subCategories.append(contentsOf: defaultCategories)
            modelContext.insert(expenseBaseCategory)
            modelContext.insert(incomeBaseCategory)
        }
    }
    
    
    /// Utility
    func extractTransactionDetails(from inputString: String) -> Transaction {
        var inputString = inputString
        let transaction = Transaction(timestamp: Date(), memo: inputString, amount: 0)
        var category: Category?
        do {
            let regex = try NSRegularExpression(pattern: "\\b(\\d+(\\.\\d+)?)\\s*([KkMmBb]?)\\b", options: [])
            if let lastMatch = regex.matches(in: inputString, options: [], range: NSRange(location: 0, length: inputString.utf16.count)).last {
                if let range = Range(lastMatch.range, in: inputString) {
                    let matchedString = String(inputString[range])
                    inputString.removeSubrange(range)
                    if let amout = matchedString.toNumericValue {
                        transaction.amount = amout
                    }
                }
            }
            let regexCategory = try NSRegularExpression(pattern: "\\/(.*?)\\|", options: [])
            if let lastMatch = regexCategory.matches(in: inputString, options: [], range: NSRange(location: 0, length: inputString.utf16.count)).last {
                if let range = Range(lastMatch.range, in: inputString) {
                    let matchedString = String(inputString[range])
                    inputString.removeSubrange(range)
                    let trimmedString = matchedString.dropFirst().dropLast()
                    category = categories.first(where: {$0.name == trimmedString})
                }
            }
            transaction.memo = inputString
            transaction.category = category ?? defaultCategory
        } catch {
            print("Error creating regex: \(error)")
            return transaction
        }
        return transaction
    }


    private func submitPrompt(_ prompt: String) {
        //process text
        //extract amount
        extractTransactionDetails(from: prompt)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Transaction(timestamp: Date(), memo: "trans", amount: 0)
            newItem.category = defaultCategory
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(transactions[index])
            }
        }
    }
    
    private func destroyAllItems() {
        withAnimation {
            do {
                try modelContext.delete(model: Transaction.self)
            } catch {
                print("Failed to delete all transaction.")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
