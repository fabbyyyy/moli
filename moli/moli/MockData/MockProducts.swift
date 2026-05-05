import Foundation

struct MockProducts {
    static let panBlanco = Product(id: UUID(), name: "Pan Blanco", category: "Pan de Caja", sku: "PB001", shelfLifeDays: 14, brand: "Bimbo", imageName: "pan_blanco")
    static let gansito = Product(id: UUID(), name: "Gansito", category: "Pastelitos", sku: "GAN01", shelfLifeDays: 30, brand: "Marinela", imageName: "gansito")
    static let donas = Product(id: UUID(), name: "Donas Glaseadas", category: "Pan Dulce", sku: "DON01", shelfLifeDays: 10, brand: "Bimbo", imageName: "donas")
    static let frituras = Product(id: UUID(), name: "Frituras Picantes", category: "Botanas", sku: "FRI01", shelfLifeDays: 60, brand: "Barcel", imageName: "frituras")
    static let papas = Product(id: UUID(), name: "Papas Adobadas", category: "Botanas", sku: "PAP01", shelfLifeDays: 60, brand: "Sabritas", imageName: "papas")
    
    static let allProducts = [panBlanco, gansito, donas, frituras, papas]
}
