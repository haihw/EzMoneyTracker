//
//  ContentView.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 9/11/23.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var promptText = ""
    @State private var showOptions = false
    @State private var popoverOffset: CGSize = .zero
    @FocusState private var isFieldFocused: Bool

    @State private var showList = true
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic

    var defaultCategory: Category? {
        let toLive = categories.filter { $0.name == "To Live"}.first
        return toLive
    }
    var listView: some View {
        List {
            NavigationLink {
                chartView
            } label: {
                Text("Summary")
            }
            ForEach(transactions) { item in
                NavigationLink {
                    Text("Vào \(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Locale.current))")
                    Text("Bạn \(item.type == TransactionType.Expense ? "đã tiêu" : "đã nhận") \(item.amount.toString) \(item.currency.rawValue)")
                    Text("Nhóm: \(item.category?.name ?? "-")")
                    Text("Description: \(item.memo)")
                    
                } label: {
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .omitted))
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
    var chartView: some View {
        Chart {
            ForEach(categories.filter {!$0.transactions.isEmpty}, id: \.name) { item in
                SectorMark(
                    angle: .value("$", item.transactions.map{$0.amount}.sum())
                )
                .foregroundStyle(by: .value("Type", item.name))
                .annotation(position: .overlay) {
                    Text("\(item.transactions.map{$0.amount}.sum().toString)$")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 500)
    }
    var summaryView: some View {
        VStack(alignment: .trailing) {
            Text("Today: \(((transactions.filter{$0.timestamp > Date().beginingOfDay}).reduce(0.0) { $0 + $1.amount}).toString)" + " " + (transactions.isEmpty ? "": transactions.first!.currency.rawValue))
            Text("This week: \(((transactions.filter{$0.timestamp > Date().beginingOfWeek}).reduce(0.0) { $0 + $1.amount}).toString)" + " " + (transactions.isEmpty ? "": transactions.first!.currency.rawValue))
            Text("This month: \(((transactions.filter{$0.timestamp > Date().beginingOfMonth}).reduce(0.0) { $0 + $1.amount}).toString)" + " " + (transactions.isEmpty ? "": transactions.first!.currency.rawValue))
            Text("This year: \(((transactions.filter{$0.timestamp > Date().beginingOfYear}).reduce(0.0) { $0 + $1.amount}).toString)" + " " + (transactions.isEmpty ? "": transactions.first!.currency.rawValue))
            Text("Total Spend: \((transactions.reduce(0.0) { $0 + $1.amount}).toString) \(transactions.isEmpty ? "": transactions.first!.currency.rawValue)")
        }.onTapGesture {
            isFieldFocused = false
        }
    }
    var body: some View {
        NavigationSplitView {
            Toggle(isOn: $showList) {
                Text(showList ? "Switch to hide list" : "Switch to show list")
            }.padding(16)
            if showList {
                listView
            }
            Spacer()
            summaryView
            VStack {
                if showOptions {
                    Button("i") {
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
                    .presentationCompactAdaptation(.popover)
                    .offset(popoverOffset)
                }
                TextField("Type something", text: $promptText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: promptText) {
                        if promptText.last == "/" {
                            // Simulate fetching options based on searchText

                            
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
                    .onAppear {
                        print("default show")
                        isFieldFocused = true
                    }
                    .focused($isFieldFocused)
                

            }
            
            
            .padding(.top, 8)
            .navigationSplitViewStyle(.balanced)
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
    @discardableResult func extractTransactionDetails(from inputString: String) -> Transaction {
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
