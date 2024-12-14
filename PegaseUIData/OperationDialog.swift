

import SwiftUI
import AppKit
import SwiftData

struct OperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    

    let modeCreation :Bool
    
    var statut = ["Plannifie", "Engaged", "Executed"]
    
    @State private var linkedAccount = " "
    @State private var comment = " "
    @State private var name = " "
    @State private var surnaame = " "
    @State private var transactionDate = Date()
    @State private var selectedMode = "Bank Card"
    @State private var number = ""
    @State private var pointingDate = Date()
    @State private var selectedStatut = "Engaged"
    @State private var bankStatement = 0
    @State private var amount = " "
    
    var body: some View {
        
        let mode = PaymentModeManager.shared.getAllDatas(for: nil, context: modelContext)
        
        ZStack { // Permet de positionner la boîte de dialogue à droite
            Color(NSColor.windowBackgroundColor) // Fond de fenêtre
            
            VStack(spacing: 0) {
                // Titre en haut
                Text("Transaction")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                
                // Contenu principal
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Ligne 1 : Compte lié
                        HStack {
                            Text("Linked Account")
                            Spacer()
                            Picker("", selection: .constant("")) {
                                Text("(no transfer)").tag("")
                            }
                            .frame(width: 200)
                        }
                        
                        Divider()
                        
                        // Ligne 2 : Intitulé
                        HStack {
                            Text("Comment")
                            Spacer()
                            TextField("", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        // Ligne 3 : Nom et Prénom
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Surname")
                            Spacer()
                            TextField("", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        
                        Divider()
                        
                        // Ligne 4 : Date Transaction et Mode
                        HStack {
                            Text("Date Transaction")
                            Spacer()
                            DatePicker("", selection: .constant(Date()), displayedComponents: .date)
                                .labelsHidden()
                                .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Mode")
                            Spacer()
                            Picker("", selection: $selectedMode) {
                                Text("Bank Card").tag("Bank Card")
                            }
                            .frame(width: 200)
                        }
                        
                        Divider()
                        
                        // Ligne 5 : Date Pointage et Statut
                        HStack {
                            Text("Date of pointing")
                            Spacer()
                            DatePicker("", selection: .constant(Date()), displayedComponents: .date)
                                .labelsHidden()
                                .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Statut")
                            Spacer()
                            Picker("", selection: $selectedStatut) {
                                ForEach(statut, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .frame(width: 200)
                        }
                        
                        Divider()
                        
                        // Ligne 6 : Relevé Bancaire
                        HStack {
                            Text("Bank Statement")
                            Spacer()
                            TextField("0", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        Divider()
                        
                        
                        // Ligne 7 : Montant
                        HStack {
                            Spacer()
                            Text("55,00 €")
                                .font(.title)
                                .foregroundColor(.red)
                                .padding(.trailing)
                        }
                        
                        Divider()
                        
                        // Split Transactions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Split Transactions")
                                .bold()
                            
                            List {
                                HStack {
                                    Text("Gasoline")
                                    Spacer()
                                    Text("-55,00 €").foregroundColor(.green)
                                }
                            }
                            .frame(height: 100)
                            
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "plus")
                                }
                                Button(action: {}) {
                                    Image(systemName: "minus")
                                }
                            }
                        }
                        
                        Divider()
                    }
                    .padding()
                }
                
                // Boutons bas
                HStack {
                    Button("Cancel", action: {})
                    Spacer()
                    Button("OK", action: {})
                        .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .shadow(radius: 5) // Ajout d'une ombre pour l'esthétique
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Étendre la vue sur toute la fenêtre
    }
}

struct OperationView1: View {
    @State private var linkedAccount = " "
    @State private var intitule = " "
    @State private var nom = " "
    @State private var prenom = " "
    @State private var operationDate = Date()
    @State private var mode = "Bank Card"
    @State private var number = ""
    @State private var pointingDate = Date()
    @State private var statut = "Engaged"
    @State private var bankStatement = 0
    @State private var amount = " "
    
    let modeCreation :Bool
    
    var body: some View {
        VStack {
            // Header Section
            Text("Transaction")
                .font(.headline)
                .padding(.top)
            
            Text("Creative mode")
                .font(.subheadline)
                .foregroundColor(.orange)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                // Linked Account Section
                HStack {
                    Text("Linked Account")
                    Spacer()
                    TextField("", text: $linkedAccount)
                        .frame(maxWidth: 100)
                }
                
                HStack {
                    Text("Comment")
                    Spacer()
                    TextField("", text: $intitule)
                        .frame(maxWidth: 100)
                }
                
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("", text: $nom)
                        .frame(maxWidth: 100)
                }
                
                HStack {
                    Text("Surname")
                    Spacer()
                    TextField("", text: $prenom)
                        .frame(maxWidth: 100)
                }
                
                // Operation Date and Mode
                HStack {
                    Text("Operation date")
                    Spacer()
                    DatePicker("", selection: $operationDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: 120)
                    TextField("Bank Card", text: $mode)
                        .frame(maxWidth: 100)
                }
                
                // Number
                HStack {
                    Text("Number")
                    Spacer()
                    TextField("", text: $number)
                        .frame(maxWidth: 100)
                }
                
                // Pointing Date and Statut
                HStack {
                    Text("Pointing date")
                    Spacer()
                    DatePicker("", selection: $pointingDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: 120)
                    TextField("Engaged", text: $statut)
                        .frame(maxWidth: 100)
                }
                
                // Bank Statement
                HStack {
                    Text("Bank Statement")
                    Spacer()
                    TextField("0", value: $bankStatement, formatter: NumberFormatter())
                        .frame(maxWidth: 100)
                }
                
                // Amount
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("0.00", text: $amount)
                        .disabled(true)
                        .frame(maxWidth: 100)
                }
            }
            .padding([.leading, .trailing])
            
            Divider()
            
            // Sub-operation Section
            VStack {
                Text("Sub-operation")
                    .font(.headline)
                
                Text("Add a sub-operation")
                    .font(.body)
                
                HStack {
                    Button("+") {}
                    Button("-") {}
                }
                
                Text("No chart Data available.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, maxHeight: 100)
            //            .background(Color(rawValue: .white))
            .padding([.leading, .trailing])
            
            Spacer()
            
            // Cancel and Save Buttons
            HStack {
                Button("Cancel") {}
                Spacer()
                Button("Save") {}
                    .disabled(true)
            }
            .padding()
        }
        .frame(minWidth: 300, maxWidth: 400, minHeight: 600)
    }
}


