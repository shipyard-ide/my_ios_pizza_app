//
//  ContentView.swift
//  my_ios_pizza_app
//
//  Created by Zachary Grimaldi on 12/27/25.
//

import SwiftUI
import Combine

struct Pizza: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let basePrice: Double
    let imageName: String
    let color: Color
}

struct Topping: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let price: Double
    let emoji: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Topping, rhs: Topping) -> Bool {
        lhs.id == rhs.id
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let pizza: Pizza
    let size: PizzaSize
    let toppings: [Topping]
    
    var totalPrice: Double {
        pizza.basePrice * size.multiplier + toppings.reduce(0) { $0 + $1.price }
    }
}

enum PizzaSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var multiplier: Double {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.3
        }
    }
    
    var inches: String {
        switch self {
        case .small: return "10\""
        case .medium: return "12\""
        case .large: return "14\""
        }
    }
}

class CartManager: ObservableObject {
    @Published var items: [CartItem] = []
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    func addItem(_ item: CartItem) {
        items.append(item)
    }
    
    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func clearCart() {
        items.removeAll()
    }
}

struct ContentView: View {
    @StateObject private var cartManager = CartManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MenuView(cartManager: cartManager)
                .tabItem {
                    Label("Menu", systemImage: "menucard")
                }
                .tag(0)
            
            CartView(cartManager: cartManager)
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
                .badge(cartManager.items.count)
                .tag(1)
        }
        .tint(.orange)
    }
}

struct MenuView: View {
    @ObservedObject var cartManager: CartManager
    @State private var showingCustomization = false
    @State private var selectedPizza: Pizza?
    
    let pizzas = [
        Pizza(name: "Margherita", description: "Fresh tomatoes, mozzarella, basil", basePrice: 12.99, imageName: "leaf", color: .green),
        Pizza(name: "Pepperoni", description: "Classic pepperoni with extra cheese", basePrice: 14.99, imageName: "flame", color: .red),
        Pizza(name: "Hawaiian", description: "Ham, pineapple, mozzarella", basePrice: 15.99, imageName: "sun.max", color: .yellow),
        Pizza(name: "BBQ Chicken", description: "Grilled chicken, BBQ sauce, red onions", basePrice: 16.99, imageName: "fork.knife", color: .brown),
        Pizza(name: "Veggie Supreme", description: "Bell peppers, mushrooms, olives, onions", basePrice: 14.99, imageName: "carrot", color: .orange),
        Pizza(name: "Meat Lovers", description: "Pepperoni, sausage, bacon, ham", basePrice: 17.99, imageName: "flame.fill", color: .red),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    
                    LazyVStack(spacing: 16) {
                        ForEach(pizzas) { pizza in
                            PizzaCard(pizza: pizza) {
                                selectedPizza = pizza
                                showingCustomization = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🍕 Pizza Menu")
            .sheet(isPresented: $showingCustomization) {
                if let pizza = selectedPizza {
                    CustomizationView(pizza: pizza, cartManager: cartManager, isPresented: $showingCustomization)
                }
            }
        }
    }
    
    var headerView: some View {
        VStack(spacing: 8) {
            Text("Fresh from the oven!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                Text("Delivery: 30-45 min")
            }
            .font(.subheadline)
            .foregroundColor(.orange)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
    }
}

struct PizzaCard: View {
    let pizza: Pizza
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(pizza.color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: pizza.imageName)
                        .font(.system(size: 28))
                        .foregroundColor(pizza.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pizza.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(pizza.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text("$\(pizza.basePrice, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomizationView: View {
    let pizza: Pizza
    @ObservedObject var cartManager: CartManager
    @Binding var isPresented: Bool
    
    @State private var selectedSize: PizzaSize = .medium
    @State private var selectedToppings: Set<Topping> = []
    
    let availableToppings = [
        Topping(name: "Extra Cheese", price: 1.50, emoji: "🧀"),
        Topping(name: "Mushrooms", price: 1.00, emoji: "🍄"),
        Topping(name: "Peppers", price: 1.00, emoji: "🫑"),
        Topping(name: "Onions", price: 0.75, emoji: "🧅"),
        Topping(name: "Olives", price: 1.00, emoji: "🫒"),
        Topping(name: "Jalapeños", price: 0.75, emoji: "🌶️"),
        Topping(name: "Bacon", price: 2.00, emoji: "🥓"),
        Topping(name: "Pineapple", price: 1.00, emoji: "🍍"),
    ]
    
    var totalPrice: Double {
        pizza.basePrice * selectedSize.multiplier + selectedToppings.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    pizzaHeader
                    sizeSelector
                    toppingsSection
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addToCartButton
            }
        }
    }
    
    var pizzaHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(pizza.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: pizza.imageName)
                    .font(.system(size: 44))
                    .foregroundColor(pizza.color)
            }
            
            Text(pizza.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(pizza.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    var sizeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Size")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(PizzaSize.allCases, id: \.self) { size in
                    Button {
                        selectedSize = size
                    } label: {
                        VStack(spacing: 4) {
                            Text(size.rawValue)
                                .font(.headline)
                            Text(size.inches)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedSize == size ? Color.orange : Color(.systemBackground))
                        .foregroundColor(selectedSize == size ? .white : .primary)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    var toppingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Toppings")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(availableToppings) { topping in
                    ToppingButton(
                        topping: topping,
                        isSelected: selectedToppings.contains(topping)
                    ) {
                        if selectedToppings.contains(topping) {
                            selectedToppings.remove(topping)
                        } else {
                            selectedToppings.insert(topping)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    var addToCartButton: some View {
        Button {
            let item = CartItem(
                pizza: pizza,
                size: selectedSize,
                toppings: Array(selectedToppings)
            )
            cartManager.addItem(item)
            isPresented = false
        } label: {
            HStack {
                Text("Add to Cart")
                    .fontWeight(.semibold)
                Spacer()
                Text("$\(totalPrice, specifier: "%.2f")")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .cornerRadius(16)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct ToppingButton: View {
    let topping: Topping
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(topping.emoji)
                VStack(alignment: .leading, spacing: 2) {
                    Text(topping.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text("+$\(topping.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(12)
            .background(isSelected ? Color.orange.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CartView: View {
    @ObservedObject var cartManager: CartManager
    @State private var showingCheckout = false
    
    var body: some View {
        NavigationStack {
            Group {
                if cartManager.items.isEmpty {
                    emptyCartView
                } else {
                    cartList
                }
            }
            .navigationTitle("🛒 Your Cart")
            .alert("Order Placed! 🎉", isPresented: $showingCheckout) {
                Button("OK") {
                    cartManager.clearCart()
                }
            } message: {
                Text("Your delicious pizzas are on the way! Estimated delivery: 30-45 minutes.")
            }
        }
    }
    
    var emptyCartView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add some delicious pizzas from the menu!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    var cartList: some View {
        List {
            ForEach(cartManager.items) { item in
                CartItemRow(item: item)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    cartManager.removeItem(cartManager.items[index])
                }
            }
            
            Section {
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$\(cartManager.totalPrice, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .listRowBackground(Color.clear)
            }
            
            Section {
                Button {
                    showingCheckout = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Place Order")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct CartItemRow: View {
    let item: CartItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.pizza.name)
                    .font(.headline)
                Spacer()
                Text("$\(item.totalPrice, specifier: "%.2f")")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            HStack {
                Text(item.size.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
                
                if !item.toppings.isEmpty {
                    Text(item.toppings.map { $0.emoji }.joined())
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
