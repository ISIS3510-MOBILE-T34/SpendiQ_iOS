//
//  TransactionsMapView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 2/12/24.
//
import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation
import CoreData
import Network
import Combine

// MARK: - Models
struct TransactionMarker: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let type: String
    let color: Color
    let anomaly: Bool
    let needsSync: Bool
}

// MARK: - ViewModel
class TransactionsMapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var markers: [TransactionMarker] = []
    @Published var isLoading = false
    @Published var isOffline = false
    @Published var errorMessage: String?
    
    private let transactionViewModel = TransactionViewModel()
    private let backgroundQueue = DispatchQueue(label: "com.spendiq.map.background", qos: .utility)
    private let networkMonitor = NWPathMonitor()
    private var hasInitialLoad = false
    private var cancellables = Set<AnyCancellable>()
    private var transactionUpdateTimer: Timer?
    
    init() {
        setupNetworkMonitoring()
        setupObservers()
        startPeriodicUpdates()
        loadInitialData()
    }
    
    // MARK: - Multi-threading Implementation
    private func startPeriodicUpdates() {
        // Monitorea nuevas transacciones cada 30 segundos en segundo plano
        transactionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.backgroundQueue.async {
                self?.checkForNewTransactions()
            }
        }
    }
    
    private func checkForNewTransactions() {
        guard !isOffline else { return }
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "needsSync == YES")
        
        do {
            let unsyncedTransactions = try context.fetch(fetchRequest)
            if !unsyncedTransactions.isEmpty {
                syncTransactions(unsyncedTransactions)
            }
        } catch {
            print("Error checking for unsynced transactions: \(error)")
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = self?.isOffline ?? false
                self?.isOffline = path.status != .satisfied
                
                if wasOffline && path.status == .satisfied {
                    self?.syncWithFirebase()
                }
            }
        }
        networkMonitor.start(queue: backgroundQueue)
    }
    
    // MARK: - Data Loading and Syncing
    private func loadInitialData() {
        isLoading = true
        backgroundQueue.async { [weak self] in
            self?.loadLocalTransactions()
            if !(self?.isOffline ?? true) {
                self?.syncWithFirebase()
            }
        }
    }
    
    private func loadLocalTransactions() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        
        do {
            let transactions = try context.fetch(fetchRequest)
            updateMarkers(from: transactions)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error loading local data"
            }
        }
    }
    
    private func syncWithFirebase() {
        isLoading = true
        transactionViewModel.getTransactionsForAllAccounts()
    }
    
    private func syncTransactions(_ transactions: [TransactionEntity]) {
        for transaction in transactions {
            guard let id = transaction.id else { continue }
            
            let data: [String: Any] = [
                "id": id,
                "latitude": transaction.latitude,
                "longitude": transaction.longitude,
                "transactionType": transaction.transactionType ?? "",
                "amount": transaction.amount,
                "dateTime": transaction.dateTime ?? Date(),
                "amountAnomaly": transaction.amountAnomaly,
                "locationAnomaly": transaction.locationAnomaly
            ]
            
            FirestoreManager.shared.db.collection("transactions").document(id).setData(data) { [weak self] error in
                if let error = error {
                    print("Error syncing transaction: \(error)")
                } else {
                    self?.markTransactionSynced(transaction)
                }
            }
        }
    }
    
    private func markTransactionSynced(_ transaction: TransactionEntity) {
        backgroundQueue.async {
            transaction.needsSync = false
            try? PersistenceController.shared.container.viewContext.save()
        }
    }
    
    // MARK: - Observers Setup
    private func setupObservers() {
        transactionViewModel.$transactions
            .receive(on: backgroundQueue)
            .map { [weak self] transactions -> [TransactionMarker] in
                transactions.map { transaction in
                    self?.createMarker(from: transaction) ?? []
                }.flatMap { $0 }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMarkers in
                self?.markers = newMarkers
                self?.isLoading = false
                if self?.hasInitialLoad == false {
                    self?.hasInitialLoad = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func createMarker(from transaction: Transaction) -> [TransactionMarker] {
        [TransactionMarker(
            id: transaction.id ?? UUID().uuidString,
            coordinate: CLLocationCoordinate2D(
                latitude: transaction.location.latitude,
                longitude: transaction.location.longitude
            ),
            title: "\(transaction.transactionType): $\(transaction.amount)",
            type: transaction.transactionType,
            color: transaction.transactionType.lowercased() == "income" ? .yellow : .red,
            anomaly: transaction.amountAnomaly || transaction.locationAnomaly,
            needsSync: isOffline
        )]
    }
    
    private func updateMarkers(from entities: [TransactionEntity]) {
        let newMarkers = entities.map { entity in
            TransactionMarker(
                id: entity.id ?? UUID().uuidString,
                coordinate: CLLocationCoordinate2D(
                    latitude: entity.latitude,
                    longitude: entity.longitude
                ),
                title: "\(entity.transactionType ?? ""): $\(entity.amount)",
                type: entity.transactionType ?? "",
                color: (entity.transactionType ?? "").lowercased() == "income" ? .yellow : .red,
                anomaly: entity.amountAnomaly || entity.locationAnomaly,
                needsSync: entity.needsSync
            )
        }
        
        DispatchQueue.main.async {
            self.markers = newMarkers
        }
    }
    
    deinit {
        networkMonitor.cancel()
        transactionUpdateTimer?.invalidate()
    }
}

// MARK: - View
struct TransactionsMapView: View {
    @StateObject private var viewModel = TransactionsMapViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: .constant(viewModel.region), annotationItems: viewModel.markers) { marker in
                MapAnnotation(coordinate: marker.coordinate) {
                    VStack(spacing: 2) {
                        Circle()
                            .fill(marker.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 2)
                        
                        if marker.anomaly {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                        }
                        
                        if marker.needsSync {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                                .font(.caption2)
                        }
                        
                        Text(marker.title)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if viewModel.isOffline {
                VStack {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline Mode - Showing cached data")
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationBarTitle("Transaction Locations", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .alert(
            "Notice",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
