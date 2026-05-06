import CoreLocation
import Foundation

struct RegionInsight: Identifiable {
    let id = UUID()
    let region: String
    let coordinate: CLLocationCoordinate2D
    let topProducts: String
    let reason: String
    let kpi: String
    
    static let all: [RegionInsight] = [
        RegionInsight(
            region: "Norte",
            coordinate: CLLocationCoordinate2D(latitude: 25.6866, longitude: -100.3161),
            topProducts: "Tortillas de harina, pan de caja, bollería, snacks Barcel/Takis",
            reason: "Mayor consumo de tortillas de harina y compras prácticas para lunch/oficina.",
            kpi: "Rotación por SKU salado · Quiebre de stock en tortillas/pan de caja"
        ),
        RegionInsight(
            region: "Centro / Bajío",
            coordinate: CLLocationCoordinate2D(latitude: 20.9674, longitude: -101.3566),
            topProducts: "Pan de caja, pan dulce, pastelitos, galletas",
            reason: "Zona urbana con mucho canal de conveniencia y consumo escolar/laboral.",
            kpi: "Ventas por tienda por día · Top 5 SKUs por tienda"
        ),
        RegionInsight(
            region: "CDMX / Zona Metropolitana",
            coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            topProducts: "Pan de caja, productos individuales, pastelitos, galletas, snacks",
            reason: "Alta densidad, consumo rápido en OXXO/tienditas/súper y compras por conveniencia.",
            kpi: "Ticket promedio por visita · Ventas por canal"
        ),
        RegionInsight(
            region: "Occidente",
            coordinate: CLLocationCoordinate2D(latitude: 20.6597, longitude: -103.3496),
            topProducts: "Pan dulce, bollería, botanas, galletas",
            reason: "Fuerte consumo familiar y de productos para desayuno/merienda.",
            kpi: "Participación de pan dulce en ventas totales"
        ),
        RegionInsight(
            region: "Sur / Sureste",
            coordinate: CLLocationCoordinate2D(latitude: 17.0732, longitude: -96.7266),
            topProducts: "Pan dulce, pastelitos, galletas, productos económicos individuales",
            reason: "Mayor peso del gasto en alimentos dentro del hogar; productos accesibles y de alta frecuencia.",
            kpi: "Sell-out de productos individuales · Precio promedio por unidad"
        ),
        RegionInsight(
            region: "Zonas Turísticas / Costeras",
            coordinate: CLLocationCoordinate2D(latitude: 20.6296, longitude: -87.0739),
            topProducts: "Snacks, pastelitos, pan de caja, productos listos para comer",
            reason: "Consumo de paso, tiendas de conveniencia, turismo y compra impulsiva.",
            kpi: "Ventas por temporada · Rotación en canal conveniencia"
        )
    ]
}
