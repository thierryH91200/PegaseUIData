import SwiftUI
import SwiftData

// Gestionnaire de préférences des transactions
final class PreferenceDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var preferenceTransaction: EntityPreference? {
        didSet {
            // Sauvegarde automatique des modifications
            saveChanges()
        }
    }
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    func saveChanges() {
        do {
            try modelContext?.save()
        } catch {
            printTag("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

// Vue permettant de modifier les préférences de transactions pour un compte
struct PreferenceTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: PreferenceDataManager
    
    @State private var entityPreference  : EntityPreference?
    @State private var entityRubric      : [EntityRubric]      = []
    @State private var entityCategorie   : [EntityCategory]    = []
    @State private var entityPaymentMode : [EntityPaymentMode] = []
    @State private var entityStatus      : [EntityStatus]      = []
    
    @State var selectedStatus   : EntityStatus?
    @State var selectedRubric   : EntityRubric?
    @State var selectedCategory : EntityCategory?
    @State var selectedMode     : EntityPaymentMode?
    
    @State private var isExpanded = false // Indicateur pour l'état de sélection du signe
    @State var changeCounter = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Default values ​​for transactions for this account.")
                .font(.headline)
                .padding(.top)
            
            // Sélection des préférences
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(entityStatus, id: \..self) { index in
                            Text(index.name).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(entityPaymentMode, id: \..self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Picker("Rubric", selection: $selectedRubric) {
                        ForEach(entityRubric, id: \..self) {
                            Text($0.name).tag($0 as EntityRubric?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedRubric) { _, newRubric in
                        if let newRubric = newRubric {
                            // Mise à jour des catégories en fonction de la rubrique sélectionnée
                            entityCategorie = newRubric.categorie.sorted { $0.name < $1.name }
                            if let selected = selectedCategory,
                               !entityCategorie.contains(where: { $0 == selected }) {
                                selectedCategory = entityCategorie.first
                            }
                        } else {
                            entityCategorie = []
                            selectedCategory = nil
                        }
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(entityCategorie, id: \..self) {
                            Text($0.name).tag($0 as EntityCategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .frame(width: 600)
            
            // Sélection du signe par une icône
            HStack {
                Text("Default sign")
                ZStack {
                    Rectangle()
                        .fill(isExpanded ? Color.red : Color.green)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: isExpanded ? "minus" : "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .onTapGesture {
                    isExpanded.toggle()
                }
            }
            .padding(.bottom)
            Spacer()
        }
        .onAppear {
            Task {
                try await configureFormState()
                DataContext.shared.context = modelContext

                if let account = currentAccountManager.currentAccount {
                    try await refreshData(for: account)
                }
            }
        }
        
        .onDisappear {
            Task {
                await updatePreference(status: selectedStatus!,
                                       mode: selectedMode!,
                                       rubric: selectedRubric!,
                                       category: selectedCategory!,
                                       preference: entityPreference!,
                                       sign: isExpanded)
            }
        }
        
        .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
            changeCounter += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task {
                    guard let status = selectedStatus,
                          let mode = selectedMode,
                          let rubric = selectedRubric,
                          let category = selectedCategory,
                          let preference = entityPreference else { return }

                    await updatePreference(status: status,
                                           mode: mode,
                                           rubric: rubric,
                                           category: category,
                                           preference: preference,
                                           sign: isExpanded)

                    if let account = newAccount {
                        dataManager.preferenceTransaction = nil
                        dataManager.currentAccount = account
                        try await refreshData(for: account)
                    }
                }
            }
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    // Fonction de mise à jour des préférences
    @MainActor
    func updatePreference(status: EntityStatus,
                          mode: EntityPaymentMode,
                          rubric: EntityRubric,
                          category: EntityCategory,
                          preference: EntityPreference,
                          sign: Bool) async {
        Task {
            try await PreferenceManager.shared.update(status: status,
                                                       mode: mode,
                                                       rubric: rubric,
                                                       category: category,
                                                       preference: preference,
                                                       sign: sign)
        }
    }
    
    // Configuration initiale du formulaire
    func configureFormState() async throws {
        DataContext.shared.context = modelContext

        if /*let account = CurrentAccountManager.shared.getAccount(),*/
           let modes = PaymentModeManager.shared.getAllData() {
            selectedMode = entityPreference?.paymentMode
            entityPaymentMode = modes
        }
        if let account = CurrentAccountManager.shared.getAccount() {
            if let status = StatusManager.shared.getAllData(for: account) {
                // Sélection sécurisée du premier status
                selectedStatus = entityPreference?.status
                entityStatus = status
            }
        }
    }

    // Rafraîchir les données du formulaire
    private func refreshData(for account: EntityAccount) async throws {
        DataContext.shared.context = modelContext

        dataManager.preferenceTransaction = PreferenceManager.shared.getAllData(for: account)
        guard let entityPreference = dataManager.preferenceTransaction else { return }
        
        self.entityPreference = entityPreference
        selectedStatus = entityPreference.status
        selectedMode = entityPreference.paymentMode
        selectedRubric = entityPreference.category?.rubric
        selectedCategory = entityPreference.category
        isExpanded = entityPreference.signe
        
        entityStatus = StatusManager.shared.getAllData(for: account) ?? []
        entityPaymentMode = PaymentModeManager.shared.getAllData()!
        entityRubric = RubricManager.shared.getAllData()
        entityCategorie = selectedRubric?.categorie ?? []
    }
}
