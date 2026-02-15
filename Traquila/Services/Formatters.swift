import Foundation

enum TraquilaFormatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func ounces(_ value: Double, unit: VolumeUnit) -> String {
        switch unit {
        case .oz:
            return "\(value.formatted(.number.precision(.fractionLength(0...2)))) oz"
        case .ml:
            return "\((value * 29.5735).formatted(.number.precision(.fractionLength(0...0)))) ml"
        }
    }
}
