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
    
    @Attribute(.unique) var id: UUID = UUID()
    
    @Attribute var num        : Int
    
    @Attribute var startDate  : Date
    @Attribute var startSolde : Double
    
    @Attribute var interDate  : Date
    @Attribute var interSolde : Double
    
    @Attribute var endDate    : Date
    @Attribute var endSolde   : Double
    
    @Attribute var cbDate     : Date
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
    
//    public init() {
//
//    }

    
}
