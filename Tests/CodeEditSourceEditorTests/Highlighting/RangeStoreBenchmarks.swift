import XCTest
@testable import CodeEditSourceEditor

class RangeStoreBenchmarkTests: XCTestCase {
    var rng = RandomNumberGeneratorWithSeed(seed: 942)

    // to keep these stable
    struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
        init(seed: Int) { srand48(seed) }
        func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) } // swiftlint:disable:this legacy_random
    }

    func test_benchmarkInsert() {
        let rangeStore = RangeStore<String>()
        let numberOfInserts = 100_000
        var ranges = (0..<numberOfInserts).map { (value: "Value \($0)", range: $0..<($0 + 5)) }
        ranges.shuffle(using: &rng)

        measure {
            for (value, range) in ranges {
                rangeStore.insert(value: value, range: range)
            }
        }
    }

    func test_benchmarkDelete() {
        let rangeStore = RangeStore<String>()
        let numberOfInserts = 100_000
        var ranges = (0..<numberOfInserts).map { (value: "Value \($0)", range: $0..<($0 + 5)) }

        // Insert ranges in order
        for (value, range) in ranges {
            rangeStore.insert(value: value, range: range)
        }

        ranges.shuffle(using: &rng)
        measure {
            for (_, range) in ranges {
                _ = rangeStore.delete(range: range)
            }
        }
    }

    func test_benchmarkSearch() {
        let rangeStore = RangeStore<String>()
        let numberOfInserts = 100_000
        var ranges = (0..<numberOfInserts).map { (value: "Value \($0)", range: $0..<($0 + 5)) }

        // Insert ranges in order
        for (value, range) in ranges {
            rangeStore.insert(value: value, range: range)
        }

        ranges.shuffle(using: &rng)
        measure {
            for (_, range) in ranges {
                _ = rangeStore.ranges(overlapping: range)
            }
        }
    }
}
