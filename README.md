I convert the Pegase program from swift to swiftui

I converted coredata to SwiftData

Identity = ok

Bank = ok

Statement = ok

Dark/LIght toolBar = ok                         10/11/24

Add helper and definition for SwiftData         15/11/24

I have added a database to my application.
I still have a lot adjustments to make.
Improvement of the database                     20/11/24

Improves Detail view                            13/12/24

Add view mode payment                           20/01/25

Add bank statement                              30/01/25

Improve translation                             02/02/25

Improve change account                          02/02/25

Add rubric                                      03/02/25

Improve alot of things                          05/02/25

Add check                                       05/02/25

Add scheduler                                   05/02/25

Add vew transaction                             26/02/25


/// Représente un groupe de transactions d'un mois précis (par exemple 2023-02).
struct TransactionsByMonth: Identifiable {
    let id = UUID()
    let year: String
    let month: Int
    let transactions: [EntityTransactions]

    /// Formatage mois (ex: "Février")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR") // ou "en_US" etc.
        formatter.dateFormat = "LLLL" // nom du mois
        if let transaction = transactions.first,
           let date = transaction.datePointage {
            return formatter.string(from: date).capitalized
        }
        return "Mois Inconnu"
    }

    /// Calcul du total du mois
    var totalAmount: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }
}

/// Représente un regroupement par année.  
struct TransactionsByYear: Identifiable {
    let id = UUID()
    let year: String
    let months: [TransactionsByMonth]
}

<p align="center">
<img src="Doc/Capture1.png" alt="Sample">
<p align="center">
<em>List</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture3.png" alt="Sample">
<p align="center">
<em>Bank statement</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture4.png" alt="Sample">
<p align="center">
<em>Scheduler</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture5.png" alt="Sample">
<p align="center">
<em>Payment method</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture6.png" alt="Sample">
<p align="center">
<em>Général</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture7.png" alt="Sample">
<p align="center">
<em>Category Bar</em>
</p>
</p>
