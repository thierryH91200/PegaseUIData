//
//  OperationDialog4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 09/03/2025.
//


import SwiftUI
import AppKit
import SwiftData
import Observation


// MARK: 2. État du formulaire

class TransactionFormState: ObservableObject {
    
    @Published var accounts: [EntityAccount] = []
    @Published var linkedAccount: String = ""
    @Published var transactionDate: Date = Date()
    @Published var paymentModes: [EntityPaymentMode] = []
    @Published var pointingDate: Date = Date()
    @Published var status: [EntityStatus] = []
    
    @Published var bankStatement: Int = 0
    @Published var checkNumber: Int = 0
    
    @Published var amount: String = "0,00 €"
    
    @Published var isShowingDialog: Bool = false
    
    @Published var currentSousTransaction: EntitySousOperations?
    @Published var subOperations: [EntitySousOperations] = []

    @Published var currentTransaction: EntityTransactions?
    @Published var entityTransactions: [EntityTransactions] = []
    
    @Published var selectedBankStatement: String = ""
    @Published var selectedStatus: EntityStatus?
    @Published var selectedMode: EntityPaymentMode?
    @Published var selectedAccount: EntityAccount?
}
