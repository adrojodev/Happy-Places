//
//  PlaceClassifier.swift
//  Nice Places
//
//  Instant icon+color suggestions for a place, from its name (bilingual
//  Spanish/English keyword matching) or a MapKit POI category.
//  Deterministic, offline, and fast enough to run on every keystroke.
//

import Foundation
import MapKit

enum PlaceClassifier {

    struct Suggestion: Equatable {
        let icon: String
        let color: PlaceColor
    }

    struct Category {
        let name: String
        let icon: String
        let color: PlaceColor
        /// Pre-normalized: lowercase, no diacritics.
        let keywords: [String]
    }

    /// Priority-ordered: on equal match score the earlier category wins.
    static let categories: [Category] = [
        Category(name: "beach", icon: "beach.umbrella", color: .yellow,
                 keywords: ["playa", "beach", "costa", "caleta", "malecon", "cabo", "isla", "island"]),
        Category(name: "pool", icon: "figure.pool.swim", color: .blue,
                 keywords: ["alberca", "piscina", "pool", "balneario", "waterpark", "acuatico"]),
        Category(name: "mountain", icon: "mountain.2.fill", color: .green,
                 keywords: ["montana", "cerro", "volcan", "mountain", "sierra", "nevado", "hike", "senderismo", "trail", "barranca", "canon", "canyon", "cascada", "waterfall"]),
        Category(name: "camping", icon: "tent.fill", color: .green,
                 keywords: ["camping", "campamento", "acampar", "glamping"]),
        Category(name: "park", icon: "tree.fill", color: .green,
                 keywords: ["parque", "park", "bosque", "forest", "jardin", "garden", "reserva", "lago", "lake", "laguna", "rio", "river"]),
        Category(name: "cafe", icon: "cup.and.saucer.fill", color: .orange,
                 keywords: ["cafe", "cafeteria", "coffee", "panaderia", "bakery", "brunch", "postre", "dessert", "heladeria", "helado", "churreria", "pasteleria"]),
        Category(name: "restaurant", icon: "fork.knife", color: .orange,
                 keywords: ["restaurante", "restaurant", "taqueria", "taco", "comida", "food", "mariscos", "cocina", "birria", "fonda", "buffet", "parrilla", "asador", "pizzeria", "pizza", "sushi", "ramen", "burger", "hamburguesa", "tortas", "pozole", "barbacoa", "cenaduria", "antojitos"]),
        Category(name: "bar", icon: "wineglass.fill", color: .purple,
                 keywords: ["bar", "cantina", "pub", "cerveceria", "brewery", "antro", "discoteca", "mezcaleria", "pulqueria", "vinos", "wine", "vineyard", "vinedo"]),
        Category(name: "hotel", icon: "bed.double.fill", color: .blue,
                 keywords: ["hotel", "hostal", "hostel", "motel", "airbnb", "cabana", "resort", "posada"]),
        Category(name: "museum", icon: "building.columns.fill", color: .purple,
                 keywords: ["museo", "museum", "galeria", "gallery", "exposicion", "exhibit"]),
        Category(name: "theater", icon: "theatermasks.fill", color: .purple,
                 keywords: ["teatro", "theater", "theatre", "opera", "ballet"]),
        Category(name: "cinema", icon: "popcorn.fill", color: .red,
                 keywords: ["cine", "cinema", "cinepolis", "pelicula", "movie"]),
        Category(name: "concert", icon: "music.note", color: .pink,
                 keywords: ["concierto", "concert", "festival", "musica", "music", "foro", "palenque"]),
        Category(name: "shopping", icon: "cart.fill", color: .pink,
                 keywords: ["tienda", "mercado", "market", "mall", "shopping", "bazar", "outlet", "boutique", "tianguis"]),
        Category(name: "sports", icon: "sportscourt.fill", color: .red,
                 keywords: ["estadio", "stadium", "cancha", "court", "futbol", "soccer", "beisbol", "baseball", "basketball", "arena", "autodromo", "lucha"]),
        Category(name: "gym", icon: "dumbbell.fill", color: .red,
                 keywords: ["gym", "gimnasio", "crossfit", "fitness", "yoga", "pilates"]),
        Category(name: "school", icon: "graduationcap.fill", color: .blue,
                 keywords: ["escuela", "school", "universidad", "university", "colegio", "facultad", "campus", "prepa", "kinder", "instituto"]),
        Category(name: "home", icon: "house.fill", color: .pink,
                 keywords: ["casa", "home", "depa", "departamento", "apartment", "abuela", "abuelos", "familia", "family", "rancho"]),
        Category(name: "romance", icon: "heart.fill", color: .pink,
                 keywords: ["amor", "love", "novia", "novio", "aniversario", "romantico", "romantic", "beso", "cita"]),
        Category(name: "travel", icon: "airplane.departure", color: .blue,
                 keywords: ["aeropuerto", "airport", "vuelo", "flight", "viaje", "trip"]),
        Category(name: "boat", icon: "sailboat.fill", color: .blue,
                 keywords: ["marina", "muelle", "puerto", "port", "barco", "boat", "velero", "lancha", "ferry", "crucero", "cruise"]),
        Category(name: "transport", icon: "tram.fill", color: .blue,
                 keywords: ["estacion", "station", "tren", "train", "metro", "terminal", "autobus", "bus", "trolebus"]),
        Category(name: "church", icon: "cross.fill", color: .purple,
                 keywords: ["iglesia", "catedral", "templo", "basilica", "church", "capilla", "parroquia", "santuario"]),
        Category(name: "health", icon: "cross.case.fill", color: .red,
                 keywords: ["hospital", "clinica", "clinic", "doctor", "dentista", "dentist", "medico", "farmacia", "pharmacy"]),
        Category(name: "zoo", icon: "pawprint.fill", color: .green,
                 keywords: ["zoologico", "zoo", "acuario", "aquarium", "safari", "granja", "farm", "veterinaria", "vet"]),
        Category(name: "landmark", icon: "binoculars.fill", color: .blue,
                 keywords: ["mirador", "viewpoint", "lookout", "vista", "monumento", "monument", "torre", "tower", "faro", "lighthouse", "ruinas", "ruins", "piramide", "pyramid", "castillo", "castle", "zocalo", "centro"]),
        Category(name: "library", icon: "books.vertical.fill", color: .purple,
                 keywords: ["biblioteca", "library", "libreria", "bookstore"]),
        Category(name: "work", icon: "building.2.fill", color: .blue,
                 keywords: ["oficina", "office", "trabajo", "work", "coworking"]),
        Category(name: "party", icon: "party.popper.fill", color: .pink,
                 keywords: ["fiesta", "party", "boda", "wedding", "cumpleanos", "birthday", "feria", "fair", "carnaval"]),
    ]

    // MARK: - Name-based suggestion

    /// Suggests an icon+color for a place name, or nil when nothing matches.
    /// Matching is diacritic- and case-insensitive (Spanish + English).
    static func suggest(for name: String) -> Suggestion? {
        let normalized = normalize(name)
        guard !normalized.isEmpty else { return nil }
        let tokens = normalized.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard !tokens.isEmpty else { return nil }

        var best: (category: Category, score: Int)?
        for category in categories {
            var score = 0
            for keyword in category.keywords {
                if tokens.contains(keyword) {
                    score = max(score, 300 + keyword.count)
                } else if keyword.count >= 4, tokens.contains(where: { $0.hasPrefix(keyword) }) {
                    // "taco" matches "tacos", "cafeteria" matches "cafeterias"
                    score = max(score, 200 + keyword.count)
                } else if keyword.count >= 5, normalized.contains(keyword) {
                    score = max(score, 100 + keyword.count)
                }
            }
            if score > 0, score > (best?.score ?? 0) {
                best = (category, score)
            }
        }

        guard let best else { return nil }
        return Suggestion(icon: best.category.icon, color: best.category.color)
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
            .lowercased()
    }

    // MARK: - POI-based suggestion

    private static let poiToCategoryName: [MKPointOfInterestCategory: String] = [
        .airport: "travel",
        .amusementPark: "party",
        .aquarium: "zoo",
        .bakery: "cafe",
        .beach: "beach",
        .brewery: "bar",
        .cafe: "cafe",
        .campground: "camping",
        .fitnessCenter: "gym",
        .foodMarket: "shopping",
        .hospital: "health",
        .hotel: "hotel",
        .library: "library",
        .marina: "boat",
        .movieTheater: "cinema",
        .museum: "museum",
        .nationalPark: "park",
        .nightlife: "bar",
        .park: "park",
        .pharmacy: "health",
        .publicTransport: "transport",
        .restaurant: "restaurant",
        .school: "school",
        .stadium: "sports",
        .store: "shopping",
        .theater: "theater",
        .university: "school",
        .winery: "bar",
        .zoo: "zoo",
    ]

    static func suggest(for poi: MKPointOfInterestCategory) -> Suggestion? {
        guard let name = poiToCategoryName[poi],
              let category = categories.first(where: { $0.name == name }) else { return nil }
        return Suggestion(icon: category.icon, color: category.color)
    }
}
