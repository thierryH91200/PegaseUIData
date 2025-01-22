//
//  Item.swift
//  testPref
//
//  Created by Thierry hentic on 04/11/2024.
//


import SwiftData
import SwiftUI


@Model
class EntityBankStatement: Identifiable {
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    
    @Attribute var num        : Int
    
    @Attribute var startDate  : Date = Date()
    @Attribute var startSolde : Double
    
    @Attribute var interDate  : Date = Date()
    @Attribute var interSolde : Double
    
    @Attribute var endDate    : Date = Date()
    @Attribute var endSolde   : Double
    
    @Attribute var cbDate     : Date = Date()
    @Attribute var cbSolde    : Double
    
    @Attribute var pdfLink    : String = ""
    @Attribute(.externalStorage) var pdfDoc: Data?
    
    var account: EntityAccount?
    
    init(num       : Int  = 0,
         startDate : Date = Date(), startSolde : Double = 0.0,
         interDate : Date = Date(), interSolde : Double = 0.0,
         endDate   : Date = Date(), endSolde   : Double = 0.0,
         cbDate    : Date = Date(), cbSolde    : Double = 0.0,
         pdfLink   : String = "")
    {
        self.num        = num
        self.startDate  = startDate
        self.startSolde = startSolde
        
        self.interDate  = interDate
        self.interSolde = interSolde
        
        self.endDate    = endDate
        self.endSolde   = endSolde
        
        self.cbDate     = cbDate
        self.cbSolde    = cbSolde
        
        self.pdfLink    = pdfLink
    }
}

//final class BankStatementManager: NSObject {
final class BankStatementManager {
    
    // Contexte pour les modifications
    static let shared = BankStatementManager()
    var currentAccount: EntityAccount?
    
    private var entities = [EntityBankStatement]()
    
    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }
    
    private init() { }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    // Supprimer une transaction
    func remove(entity: EntityBankStatement) {
        
        validContext.undoManager?.beginUndoGrouping()
        validContext.undoManager?.setActionName("DeleteBankStatement")
        validContext.delete(entity)
        validContext.undoManager?.endUndoGrouping()
    }
    
    // MARK: - Public Methods
    func getAllDatas(for account: EntityAccount?) -> [EntityBankStatement] {
        
        let lhs = account!.uuid
       
        let predicate = #Predicate<EntityBankStatement>{ entity in entity.account!.uuid  ==  lhs }
        let descriptor = FetchDescriptor<EntityBankStatement>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.num)]
        )
        
        do {
            entities = try validContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des données avec SwiftData")
        }
        return entities
    }
}
