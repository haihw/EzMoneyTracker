//
//  ContentView.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 9/11/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Transaction]
    @Query private var categories: [Category]
    var defaultCategory: Category? {
        let toLive = categories.filter { $0.name == "To Live"}.first
        print(toLive?.name)
        return toLive
    }
    var body: some View {
        
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("On \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        Text("Category: \(item.category!.name)")
                        Text("You \(item.type == TransactionType.Expense ? "spent" : "got") \(item.amount)$")
                        Text("Description: \(item.memo)")

                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
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
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear(){
            if categories.isEmpty {
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
    }
    

    private func addItem() {
        withAnimation {
            let newItem = Transaction(timestamp: Date(), memo: "trans", amount: 0)
            newItem.category = defaultCategory
//            defaultCategory?.transactions.append(newItem)
//            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
