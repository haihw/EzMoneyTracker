//
//  TransactionView.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 3/12/23.
//

import SwiftUI
struct TransactionView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var title = ""
    @State private var amountString = ""
    
    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Amount", text: $amountString)
#if os(iOS)

                .keyboardType(.numberPad)
#endif
            Button("Add Transaction") {
                if let amount = Double(amountString) {
//                    viewModel.addTransaction(title: title, amount: amount)
                    title = ""
                    amountString = ""
                }
            }
        }
#if os(iOS)
        .navigationBarTitle("Add Transaction")
#endif
    }
}
