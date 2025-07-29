//
//  ViewModelProtocol.swift
//  Routine Anchor
//
//  Protocol for consistent ViewModel initialization and lifecycle management
//

import SwiftUI
import SwiftData

// MARK: - ViewModel Protocol

/// Protocol defining standard ViewModel lifecycle methods
protocol ViewModelLifecycle {
    /// Configure the ViewModel with dependencies
    func configure(with dependencies: ViewModelDependencies) async
    
    /// Clean up resources when ViewModel is no longer needed
    func cleanup()
    
    /// Refresh the ViewModel's data
    func refreshData() async
}

// MARK: - Dependencies Container

/// Container for common dependencies that ViewModels need
struct ViewModelDependencies {
    let dataManager: DataManager
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
    }
}

// MARK: - Base ViewModel Class (Optional)

/// Optional base class for ViewModels that provides common functionality
@Observable
class BaseViewModel: ViewModelLifecycle {
    // MARK: - Properties
    var isLoading = false
    var errorMessage: String?
    
    // Dependencies
    private(set) var dataManager: DataManager?
    private(set) var modelContext: ModelContext?
    
    // MARK: - Lifecycle Methods
    
    func configure(with dependencies: ViewModelDependencies) async {
        self.dataManager = dependencies.dataManager
        self.modelContext = dependencies.modelContext
        
        // Subclasses can override to perform additional setup
        await loadInitialData()
    }
    
    func cleanup() {
        // Subclasses can override to clean up resources
    }
    
    func refreshData() async {
        // Subclasses should override this method
        await loadInitialData()
    }
    
    // MARK: - Protected Methods (for subclasses)
    
    /// Override in subclasses to load initial data
    func loadInitialData() async {
        // Default implementation - subclasses should override
    }
    
    /// Helper to execute async operations with loading state
    func executeWithLoading<T>(_ operation: () async throws -> T) async -> T? {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await operation()
            isLoading = false
            return result
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("ViewModel operation failed: \(error)")
            return nil
        }
    }
    
    /// Clear any error state
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - View Extension for ViewModel Configuration

extension View {
    /// Configure a ViewModel using the model context from the environment
    func configureViewModel<VM: ViewModelLifecycle>(
        _ viewModel: VM,
        modelContext: ModelContext
    ) -> some View {
        self.task {
            let dependencies = ViewModelDependencies(modelContext: modelContext)
            await viewModel.configure(with: dependencies)
        }
    }
}

// MARK: - Example Usage in Views

/*
 Usage in SwiftUI Views:
 
 struct MyView: View {
     @Environment(\.modelContext) private var modelContext
     @State private var viewModel = MyViewModel()
     
     var body: some View {
         VStack {
             // View content
         }
         .configureViewModel(viewModel, modelContext: modelContext)
     }
 }
 
 Or manually:
 
 struct MyView: View {
     @Environment(\.modelContext) private var modelContext
     @State private var viewModel = MyViewModel()
     
     var body: some View {
         VStack {
             // View content
         }
         .task {
             let dependencies = ViewModelDependencies(modelContext: modelContext)
             await viewModel.configure(with: dependencies)
         }
     }
 }
 */
