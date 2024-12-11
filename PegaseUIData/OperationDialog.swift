import SwiftUI

struct OperationView: View {
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
                    Text("Linked account")
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
                    Text("Bank statement")
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
//        .frame(minWidth: 300, maxWidth: 400, minHeight: 600)
    }
}


