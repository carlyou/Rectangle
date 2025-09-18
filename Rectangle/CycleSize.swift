//
//  CycleSize.swift
//  Rectangle
//
//  Created by Eskil Gjerde Sviggum on 01/08/2024.
//  Copyright © 2024 Ryan Hanson. All rights reserved.
//

import Foundation

struct CycleSize: Hashable, CaseIterable {
    let width: Float
    let height: Float

    // Standard equal width/height sizes
    static let twoThirds = CycleSize(width: 2/3, height: 2/3)
    static let oneHalf = CycleSize(width: 1/2, height: 1/2)
    static let oneThird = CycleSize(width: 1/3, height: 1/3)
    static let oneQuarter = CycleSize(width: 1/4, height: 1/4)
    static let threeQuarters = CycleSize(width: 3/4, height: 3/4)

    // Width-only variations (height = 1.0)
    static let widthTwoThirds = CycleSize(width: 2/3, height: 1.0)
    static let widthOneHalf = CycleSize(width: 1/2, height: 1.0)
    static let widthOneThird = CycleSize(width: 1/3, height: 1.0)
    static let widthOneQuarter = CycleSize(width: 1/4, height: 1.0)
    static let widthThreeQuarters = CycleSize(width: 3/4, height: 1.0)

    // Height-only variations (width = 1.0)
    static let heightTwoThirds = CycleSize(width: 1.0, height: 2/3)
    static let heightOneHalf = CycleSize(width: 1.0, height: 1/2)
    static let heightOneThird = CycleSize(width: 1.0, height: 1/3)
    static let heightOneQuarter = CycleSize(width: 1.0, height: 1/4)
    static let heightThreeQuarters = CycleSize(width: 1.0, height: 3/4)

    static let allCases: [CycleSize] = [.twoThirds, .oneHalf, .oneThird, .oneQuarter, .threeQuarters]

    var rawValue: Int {
        // Use bit representation of Float for exact encoding
        let widthBits = width.bitPattern
        let heightBits = height.bitPattern
        // Combine the two 32-bit patterns into a single Int (only works on 64-bit systems)
        return Int(widthBits) + (Int(heightBits) << 32)
    }

    init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    init?(rawValue: Int) {
        // Extract the bit patterns
        let widthBits = UInt32(rawValue & 0xFFFFFFFF)
        let heightBits = UInt32((rawValue >> 32) & 0xFFFFFFFF)

        // Convert back to Float values
        let width = Float(bitPattern: widthBits)
        let height = Float(bitPattern: heightBits)

        self.init(width: width, height: height)
    }

    static func fromBits(bits: Int) -> Set<CycleSize> {
        // Legacy compatibility - if no bits set, return empty to use defaults elsewhere
        if bits == 0 { return [] }

        var result: Set<CycleSize> = []

        // Check each bit position for legacy compatibility
        if (bits >> 0) & 1 == 1 { result.insert(.twoThirds) }
        if (bits >> 1) & 1 == 1 { result.insert(.oneHalf) }
        if (bits >> 2) & 1 == 1 { result.insert(.oneThird) }
        if (bits >> 3) & 1 == 1 { result.insert(.oneQuarter) }
        if (bits >> 4) & 1 == 1 { result.insert(.threeQuarters) }

        // Handle additional bits for new cycle sizes
        for bit in 5..<32 {
            if (bits >> bit) & 1 == 1 {
                // Try to find a cycle size that maps to this bit
                let allAvailable = [widthOneQuarter, widthOneThird, widthOneHalf, widthTwoThirds, widthThreeQuarters,
                                  heightOneQuarter, heightOneThird, heightOneHalf, heightTwoThirds, heightThreeQuarters]
                for cycleSize in allAvailable {
                    let hash = abs(cycleSize.rawValue) % 20 + 5
                    if hash == bit {
                        result.insert(cycleSize)
                        break
                    }
                }
            }
        }

        return result
    }

    static var firstSize = CycleSize.oneHalf
    static var defaultSizes: Set<CycleSize> = [.oneHalf, .twoThirds, .oneThird]

    // Action-specific available sizes
    static func availableSizes(for action: WindowAction) -> [CycleSize] {
        switch action {
        case .leftHalf, .rightHalf:
            // Left/Right half: only change width, height stays 100%
            return [.widthOneQuarter, .widthOneThird, .widthOneHalf, .widthTwoThirds, .widthThreeQuarters]
        case .topHalf, .bottomHalf:
            // Top/Bottom half: only change height, width stays 100%
            return [.heightOneQuarter, .heightOneThird, .heightOneHalf, .heightTwoThirds, .heightThreeQuarters]
        case .centerHalf:
            // Center half: landscape uses width cycling, portrait uses height cycling
            // This will be determined at runtime based on screen orientation
            return [.widthOneQuarter, .widthOneThird, .widthOneHalf, .widthTwoThirds, .widthThreeQuarters,
                    .heightOneQuarter, .heightOneThird, .heightOneHalf, .heightTwoThirds, .heightThreeQuarters]
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            // Quarter corners: combinations of width x height
            var combinations: [CycleSize] = []
            let fractions: [Float] = [1/4, 1/3, 1/2, 2/3, 3/4]
            for width in fractions {
                for height in fractions {
                    combinations.append(CycleSize(width: width, height: height))
                }
            }
            return combinations
        default:
            // Other actions use standard equal dimensions
            return [.oneQuarter, .oneThird, .oneHalf, .twoThirds, .threeQuarters]
        }
    }

    static func defaultSizes(for action: WindowAction) -> Set<CycleSize> {
        switch action {
        case .leftHalf, .rightHalf:
            return Set([.widthOneThird, .widthOneHalf, .widthTwoThirds])
        case .topHalf, .bottomHalf:
            return Set([.heightOneThird, .heightOneHalf, .heightTwoThirds])
        case .centerHalf:
            return Set([.widthOneThird, .widthOneHalf, .widthTwoThirds, .heightOneThird, .heightOneHalf, .heightTwoThirds])
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return Set([
                CycleSize(width: 1/4, height: 1/4),
                CycleSize(width: 1/3, height: 1/3),
                CycleSize(width: 1/2, height: 1/2)
            ])
        default:
            return Set([.oneThird, .oneHalf, .twoThirds])
        }
    }

    // The expected order of the cycle sizes is to start with the
    // first division, then go gradually upwards in size and wrap
    // around to the smaller sizes.
    //
    // For example if all cycles are used, the order should be:
    // 1/2, 2/3, 3/4, 1/4, 1/3
    static var sortedSizes: [CycleSize] = {
        let sortedSizes = Self.allCases.sorted(by: { $0.averageFraction < $1.averageFraction })

        guard let firstSizeIndex = sortedSizes.firstIndex(of: firstSize) else {
            return sortedSizes
        }

        let lessThanFistSizes = sortedSizes[0..<firstSizeIndex]
        let greaterThanFistSizes = sortedSizes[(firstSizeIndex + 1)..<sortedSizes.count]

        return [firstSize] + greaterThanFistSizes + lessThanFistSizes
    }()
}

extension CycleSize {

    var title: String {
        // Handle special cases for width-only and height-only
        if height == 1.0 && width != 1.0 {
            return "\(formatFraction(width)) width"
        } else if width == 1.0 && height != 1.0 {
            return "\(formatFraction(height)) height"
        } else {
            // Both dimensions or equal dimensions
            switch self {
            case .twoThirds:
                return "⅔ × ⅔"
            case .oneHalf:
                return "½ × ½"
            case .oneThird:
                return "⅓ × ⅓"
            case .oneQuarter:
                return "¼ × ¼"
            case .threeQuarters:
                return "¾ × ¾"
            default:
                return "\(formatFraction(width)) × \(formatFraction(height))"
            }
        }
    }

    private func formatFraction(_ value: Float) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == 0.5 { return "½" }
        if rounded == 0.33 || rounded == 0.333 { return "⅓" }
        if rounded == 0.67 || rounded == 0.667 { return "⅔" }
        if rounded == 0.25 { return "¼" }
        if rounded == 0.75 { return "¾" }
        return String(format: "%.2f", rounded)
    }

    var averageFraction: Float {
        (width + height) / 2
    }

    var isAlwaysEnabled: Bool {
        self == Self.firstSize
    }

}

extension Set where Element == CycleSize {
    func toBits() -> Int {
        var bits = 0
        self.forEach { cycleSize in
            // Map to legacy bit positions for compatibility
            switch cycleSize {
            case .twoThirds: bits |= 1 << 0
            case .oneHalf: bits |= 1 << 1
            case .oneThird: bits |= 1 << 2
            case .oneQuarter: bits |= 1 << 3
            case .threeQuarters: bits |= 1 << 4
            default:
                // For new cycle sizes, use a hash-based approach
                let hash = abs(cycleSize.rawValue) % 20 + 5  // Offset to avoid conflicts
                bits |= 1 << hash
            }
        }
        return bits
    }
}

class CycleSizesDefault: Default {
    public private(set) var key: String = "selectedCycleSizes"
    private var initialized = false

    var value: Set<CycleSize> {
        didSet {
            if initialized {
                UserDefaults.standard.set(value.toBits(), forKey: key)
            }
        }
    }

    init() {
        let bits = UserDefaults.standard.integer(forKey: key)
        value = CycleSize.fromBits(bits: bits)
        initialized = true
    }

    func load(from codable: CodableDefault) {
        if let bits = codable.int {
            let divisions = CycleSize.fromBits(bits: bits)
            value = divisions
        }
    }

    func toCodable() -> CodableDefault {
        return CodableDefault(int: value.toBits())
    }

}

class ActionCycleSizesDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var value: Set<CycleSize> {
        didSet {
            if initialized {
                saveCycleSizes()
            }
        }
    }

    init(action: WindowAction) {
        self.key = "cycleSizes_\(action.name)"

        // Initialize value with empty set first
        value = []

        // Load the actual values
        let loadedSizes = loadCycleSizes()

        if loadedSizes.isEmpty {
            // Use action-specific defaults if no custom sizes are set
            value = CycleSize.defaultSizes(for: action)
        } else {
            value = loadedSizes
        }
        initialized = true
    }

    private func saveCycleSizes() {
        // Convert CycleSizes to array of dictionaries for JSON serialization
        let cycleSizeData = value.map { cycleSize in
            return ["width": cycleSize.width, "height": cycleSize.height]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: cycleSizeData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: key)
        } else {
        }
    }

    private func loadCycleSizes() -> Set<CycleSize> {
        guard let jsonString = UserDefaults.standard.string(forKey: key),
              let jsonData = jsonString.data(using: .utf8),
              let cycleSizeData = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Float]] else {
            return []
        }

        var result: Set<CycleSize> = []
        for data in cycleSizeData {
            if let width = data["width"], let height = data["height"] {
                result.insert(CycleSize(width: width, height: height))
            }
        }
        return result
    }

    func load(from codable: CodableDefault) {
        if let bits = codable.int {
            let divisions = CycleSize.fromBits(bits: bits)
            value = divisions
        }
    }

    func toCodable() -> CodableDefault {
        return CodableDefault(int: value.toBits())
    }
}
