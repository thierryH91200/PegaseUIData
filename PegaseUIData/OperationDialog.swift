

import SwiftUI
import AppKit
import SwiftData

struct OperationDialog: View {
    
    let modeCreation :Bool

    @Environment(\.modelContext) private var modelContext: ModelContext
        
    var statut = ["Plannifie", "Engaged", "Executed"]
    
    @State private var linkedAccount = " "
    @State private var comment = " "
    @State private var name = " "
    @State private var surname = " "
    @State private var transactionDate = Date()
    @State private var selectedMode = "Bank Card"
    @State private var number = ""
    @State private var pointingDate = Date()
    @State private var selectedStatut = "Engaged"
    @State private var bankStatement = 0
    @State private var amount = " "
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(modeCreation: Bool) {
        self.modeCreation = modeCreation
    }

    var body: some View {
        
//        let account = CurrrentAccountManager.shared.getAccount()
//        let modes = PaymentModeManager.shared.getAllDatas(for: account)
//        let md = modes
        
        ZStack { // Permet de positionner la boîte de dialogue à droite
            Color(NSColor.windowBackgroundColor) // Fond de fenêtre
            
            VStack(spacing: 0) {
                // Titre en haut
                Text("\(modeCreation ? String(localized:"Creation") : String(localized:"Modification"))")
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
                            TextField("", text: $comment)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        // Ligne 3 : Nom et Prénom
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Surname")
                            Spacer()
                            TextField("", text: $surname)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        
                        Divider()
                        
                        // Ligne 4 : Date Transaction et Mode
                        HStack {
                            Text("Date Transaction")
                            Spacer()
                            DatePicker("", selection: $transactionDate, displayedComponents: .date)
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
                            DatePicker("", selection: $pointingDate, displayedComponents: .date)
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
                            TextField("", value: $bankStatement, formatter: numberFormatter)
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
                        
                        // Sub-operation Section
                        VStack {
                            Text("Sub-operation")
                                .font(.headline)
                            
                            Text("Add a sub-operation")
                                .font(.body)
                            
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "plus")
                                }
                                Button(action: {}) {
                                    Image(systemName: "minus")
                                }
                            }
                            
                            Text("No chart Data available.")
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .padding([.leading, .trailing])
                        
                        Spacer()                        
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
            .onAppear {
                Task {
                    // Maintenant, l'accès à `modelContext` est sûr ici
                    PaymentModeManager.shared.configure(with: modelContext)
                    let account = CurrentAccountManager.shared.getAccount()
                    if account != nil {
                        
                        let modes = PaymentModeManager.shared.getAllDatas(for: account!)
                        print(modes!) // Exemple de débogage
                    }
                }
            }
            .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .shadow(radius: 5) // Ajout d'une ombre pour l'esthétique
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Étendre la vue sur toute la fenêtre
    }
}

