import Foundation

struct DiscoverBottle: Identifiable, Hashable {
    let id: UUID
    let name: String
    let brand: String
    let type: BottleType
    let nom: String?
    let region: Region
}

protocol DiscoverProviding {
    func search(_ query: String) async throws -> [DiscoverBottle]
}

struct StaticCatalogDiscoverProvider: DiscoverProviding {
    func search(_ query: String) async throws -> [DiscoverBottle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return DiscoverService.curatedCatalog.filter { bottle in
            bottle.name.localizedCaseInsensitiveContains(trimmed)
                || bottle.brand.localizedCaseInsensitiveContains(trimmed)
                || (bottle.nom?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || bottle.type.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
        .sorted { $0.name < $1.name }
    }
}

struct OpenFoodFactsDiscoverProvider: DiscoverProviding {
    func search(_ query: String) async throws -> [DiscoverBottle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "30")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Traquila/1.0 (iOS Discover)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        let mapped = decoded.products.compactMap { product -> DiscoverBottle? in
            let rawName = product.productName?.trimmed
            guard let rawName, !rawName.isEmpty else { return nil }
            let brand = product.brands?.trimmed.nonEmpty ?? "Unknown Brand"
            let combined = [rawName, brand, product.categories].compactMap { $0?.lowercased() }.joined(separator: " ")
            let type = BottleType.fromSearchBlob(combined)
            return DiscoverBottle(
                id: UUID(),
                name: rawName,
                brand: brand,
                type: type,
                nom: extractNOM(from: rawName),
                region: .otherUnknown
            )
        }

        var unique = Set<String>()
        return mapped.filter { item in
            let key = "\(item.name.lowercased())|\(item.brand.lowercased())"
            if unique.contains(key) { return false }
            unique.insert(key)
            return true
        }
        .sorted { $0.name < $1.name }
    }

    private func extractNOM(from name: String) -> String? {
        let pattern = #"NOM\s?(\d{3,5})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsRange = NSRange(name.startIndex..<name.endIndex, in: name)
        guard let match = regex.firstMatch(in: name, options: [], range: nsRange),
              let range = Range(match.range(at: 1), in: name) else { return nil }
        return String(name[range])
    }
}

struct PremiumTequilaCatalogProvider: DiscoverProviding {
    func search(_ query: String) async throws -> [DiscoverBottle] {
        // Placeholder for future paid/partner tequila catalog integration.
        _ = query
        return []
    }
}

enum DiscoverService {
    static let curatedCatalog: [DiscoverBottle] = [
        DiscoverBottle(id: UUID(), name: "Fortaleza Blanco", brand: "Tequila Los Abuelos", type: .blanco, nom: "1493", region: .lowlands),
        DiscoverBottle(id: UUID(), name: "G4 Reposado", brand: "El Pandillo", type: .reposado, nom: "1579", region: .highlands),
        DiscoverBottle(id: UUID(), name: "El Tesoro Añejo", brand: "La Alteña", type: .anejo, nom: "1139", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Siete Leguas Blanco", brand: "Siete Leguas", type: .blanco, nom: "1120", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Tapatío Excelencia", brand: "La Alteña", type: .extraAnejo, nom: "1139", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Mijenta Reposado", brand: "Mijenta", type: .reposado, nom: "1499", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Ocho Plata", brand: "Tequila Ocho", type: .blanco, nom: "1474", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Don Fulano Añejo", brand: "La Tequileña", type: .anejo, nom: "1146", region: .highlands),
        DiscoverBottle(id: UUID(), name: "ArteNOM 1146 Añejo", brand: "ArteNOM", type: .anejo, nom: "1146", region: .highlands),
        DiscoverBottle(id: UUID(), name: "Del Maguey Vida", brand: "Del Maguey", type: .mezcal, nom: nil, region: .otherUnknown),
        DiscoverBottle(id: UUID(), name: "Ilegal Joven", brand: "Ilegal", type: .mezcal, nom: nil, region: .otherUnknown),
        DiscoverBottle(id: UUID(), name: "Cascanes No. 9 Blanco", brand: "Cascanes", type: .blanco, nom: "1614", region: .lowlands)
    ]

    private static let liveProvider = OpenFoodFactsDiscoverProvider()
    private static let fallbackProvider = StaticCatalogDiscoverProvider()
    private static let premiumProvider = PremiumTequilaCatalogProvider()

    static var sourceMode: DiscoverySourceMode {
        let raw = UserDefaults.standard.string(forKey: "discoverySourceMode")
        return DiscoverySourceMode(rawValue: raw ?? "") ?? .curatedLocal
    }

    static func popular() -> [DiscoverBottle] {
        Array(curatedCatalog.prefix(8))
    }

    static func search(_ query: String) async -> [DiscoverBottle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        switch sourceMode {
        case .curatedLocal:
            return (try? await fallbackProvider.search(trimmed)) ?? []

        case .hybrid:
            do {
                let live = try await liveProvider.search(trimmed)
                if !live.isEmpty {
                    return live
                }
            } catch {
                // Ignore and fall back to curated static catalog.
            }

            return (try? await fallbackProvider.search(trimmed)) ?? []

        case .premium:
            do {
                let premium = try await premiumProvider.search(trimmed)
                if !premium.isEmpty {
                    return premium
                }
            } catch {
                // Ignore and fall back to curated static catalog.
            }
            return (try? await fallbackProvider.search(trimmed)) ?? []
        }
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let products: [OpenFoodFactsProduct]
}

private struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let brands: String?
    let categories: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case categories
    }
}

private extension BottleType {
    static func fromSearchBlob(_ blob: String) -> BottleType {
        if blob.contains("mezcal") { return .mezcal }
        if blob.contains("extra añejo") || blob.contains("extra anejo") { return .extraAnejo }
        if blob.contains("añejo") || blob.contains("anejo") { return .anejo }
        if blob.contains("reposado") { return .reposado }
        if blob.contains("cristalino") { return .cristalino }
        return .blanco
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nonEmpty: String? { trimmed.isEmpty ? nil : trimmed }
}
