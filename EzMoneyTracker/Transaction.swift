//
//  Item.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 9/11/23.
//

import Foundation
import SwiftData
enum TransactionType: Int, Codable, Hashable {
    case Income = 0
    case Expense = 1
}
enum Currency: String, Codable, Hashable {
    case vnd = "₫"
    case sgd = "S$"
    case usd = "$"
}

@Model
final class Category {
    var name: String
    var parent: Category?
    @Relationship(deleteRule: .cascade, inverse: \Category.parent) var subCategories: [Category]!
    @Relationship(deleteRule: .cascade, inverse: \Transaction.category) var transactions: [Transaction]!
    init(name: String, parent: Category? = nil) {
        self.name = name
        self.parent = parent
        self.subCategories = []
        self.transactions = []
    }
}
@Model
final class Transaction {
    var timestamp: Date
    var amount: Float
    var memo: String
    var category: Category?
    var type: TransactionType
    var currency: Currency
    init(timestamp: Date, memo: String, amount: Float, category: Category? = nil, type: TransactionType = .Expense, currency: Currency = .vnd) {
        self.timestamp = timestamp
        self.memo = memo
        self.amount = amount
        self.category = category
        self.type = type
        self.currency = currency
    }
}
