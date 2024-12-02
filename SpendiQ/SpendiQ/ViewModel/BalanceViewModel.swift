import Foundation
import CoreData

class BalanceViewModel: ObservableObject {
    @Published var balanceData: [(date: Date, balance: Double)] = []
    private let context = PersistenceController.shared.container.viewContext
    var selectedTimeFrame: String = "1 Day"
    
    init() {
        loadCachedBalanceData()
        fetchBalanceData(timeFrame: selectedTimeFrame)
    }
    
    // MARK: - Métodos de caché
    
    private func loadCachedBalanceData() {
        let fetchRequest: NSFetchRequest<BalanceDataEntity> = BalanceDataEntity.fetchRequest()
        do {
            let cachedDataEntities = try context.fetch(fetchRequest)
            let cachedBalanceData = cachedDataEntities.map { entity in
                (date: entity.date ?? Date(), balance: entity.balance)
            }
            self.balanceData = cachedBalanceData
            print("BalanceViewModel: Datos cargados desde la caché.")
        } catch {
            print("Error al cargar balanceData desde la caché: \(error.localizedDescription)")
        }
    }
    
    private func saveBalanceDataToCache() {
        // Eliminar datos anteriores
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BalanceDataEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Error al eliminar balanceData antiguo de la caché: \(error.localizedDescription)")
        }
        
        // Guardar nuevos datos
        for dataPoint in balanceData {
            let entity = BalanceDataEntity(context: context)
            entity.date = dataPoint.date
            entity.balance = dataPoint.balance
        }
        
        saveContext()
        print("BalanceViewModel: Datos guardados en la caché.")
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error al guardar el contexto: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Funciones principales
    
    func fetchBalanceData(timeFrame: String) {
        self.selectedTimeFrame = timeFrame
        
        // Obtener transacciones desde la caché (TransactionEntity)
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let calendar = Calendar.current
        var predicates: [NSPredicate] = []
        
        // Definir el predicado según el marco de tiempo seleccionado
        switch timeFrame {
        case "1 Day":
            let startOfDay = calendar.startOfDay(for: Date())
            let datePredicate = NSPredicate(format: "dateTime >= %@", startOfDay as NSDate)
            predicates.append(datePredicate)
        case "Max":
            // No se aplica filtro de fecha
            break
        default:
            let startOfDay = calendar.startOfDay(for: Date())
            let datePredicate = NSPredicate(format: "dateTime >= %@", startOfDay as NSDate)
            predicates.append(datePredicate)
        }
        
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateTime", ascending: true)]
        
        do {
            let transactions = try context.fetch(fetchRequest)
            self.processTransactions(allTransactions: transactions)
            // Después de procesar, guardar en la caché
            saveBalanceDataToCache()
        } catch {
            print("Error al obtener transacciones: \(error.localizedDescription)")
        }
    }
    
    private func processTransactions(allTransactions: [TransactionEntity]) {
        if selectedTimeFrame == "1 Day" {
            getStartingBalance(for: Date()) { startingBalance in
                self.calculateBalanceData(allTransactions: allTransactions, startingBalance: startingBalance)
            }
        } else {
            self.calculateBalanceData(allTransactions: allTransactions, startingBalance: 0.0)
        }
    }
    
    private func calculateBalanceData(allTransactions: [TransactionEntity], startingBalance: Double) {
        let sortedTransactions = allTransactions.sorted(by: { ($0.dateTime ?? Date()) < ($1.dateTime ?? Date()) })
        
        var cumulativeBalance: Double = startingBalance
        var balanceDataTemp: [(date: Date, balance: Double)] = []
        
        for transaction in sortedTransactions {
            let amount = transaction.amount
            switch transaction.transactionType {
            case "Expense":
                cumulativeBalance -= Double(amount)
            case "Income":
                cumulativeBalance += Double(amount)
            default:
                break
            }
            
            let date: Date
            switch selectedTimeFrame {
            case "1 Day":
                date = transaction.dateTime ?? Date()
            case "Max":
                date = Calendar.current.startOfDay(for: transaction.dateTime ?? Date())
            default:
                date = transaction.dateTime ?? Date()
            }
            
            balanceDataTemp.append((date: date, balance: cumulativeBalance))
        }
        
        DispatchQueue.main.async {
            self.balanceData = balanceDataTemp
        }
    }
    
    private func getStartingBalance(for date: Date, completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        var cumulativeBalance: Double = 0.0
        
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let datePredicate = NSPredicate(format: "dateTime < %@", startOfDay as NSDate)
        fetchRequest.predicate = datePredicate
        
        do {
            let transactions = try context.fetch(fetchRequest)
            for transaction in transactions {
                let amount = transaction.amount
                switch transaction.transactionType {
                case "Expense":
                    cumulativeBalance -= Double(amount)
                case "Income":
                    cumulativeBalance += Double(amount)
                default:
                    break
                }
            }
            completion(cumulativeBalance)
        } catch {
            print("Error al obtener transacciones: \(error.localizedDescription)")
            completion(0.0)
        }
    }
}
