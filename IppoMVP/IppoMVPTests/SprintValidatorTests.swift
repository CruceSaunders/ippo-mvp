import XCTest
@testable import IppoMVP

final class SprintValidatorTests: XCTestCase {
    
    var validator: SprintValidator!
    let defaultMaxHR = 190 // Zone 4 threshold = 152 BPM
    
    override func setUp() {
        super.setUp()
        validator = SprintValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    
    private func makeSprintData(
        baselineHR: Int = 120,
        hrSamples: [Int] = [],
        peakHR: Int? = nil,
        targetDuration: TimeInterval = 35
    ) -> SprintData {
        var data = SprintData(
            startTime: Date().addingTimeInterval(-targetDuration),
            targetDuration: targetDuration,
            baselineHR: baselineHR
        )
        data.hrSamples = hrSamples
        data.peakHR = peakHR ?? (hrSamples.max() ?? 0)
        return data
    }
    
    // MARK: - Valid Sprint Tests
    
    func testValidSprintReachesZone4() {
        let data = makeSprintData(
            hrSamples: [125, 135, 145, 155, 165, 170],
            peakHR: 170
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertTrue(result.isValid, "Sprint reaching Zone 4 (170 >= 152) should be valid")
    }
    
    func testValidSprintBarelyReachesZone4() {
        // Zone 4 threshold for maxHR 190 = 152
        let data = makeSprintData(
            hrSamples: [125, 135, 145, 152],
            peakHR: 152
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertTrue(result.isValid, "Sprint exactly at Zone 4 threshold (152) should be valid")
    }
    
    func testValidSprintSingleSampleInZone4() {
        let data = makeSprintData(
            hrSamples: [125, 125, 125, 125, 155, 125, 125],
            peakHR: 155
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertTrue(result.isValid, "Even one sample in Zone 4 should validate the sprint")
    }
    
    // MARK: - Invalid Sprint Tests
    
    func testInvalidSprintBelowZone4() {
        let data = makeSprintData(
            hrSamples: [125, 130, 135, 140, 145, 150],
            peakHR: 150
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertFalse(result.isValid, "Sprint below Zone 4 (150 < 152) should be invalid")
    }
    
    func testInvalidSprintNoHRResponse() {
        let data = makeSprintData(
            hrSamples: Array(repeating: 125, count: 10),
            peakHR: 125
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertFalse(result.isValid, "Sprint with flat HR should be invalid")
    }
    
    func testInvalidSprintEmptyHRSamples() {
        let data = makeSprintData(hrSamples: [], peakHR: 0)
        let result = validator.validate(data, maxHR: defaultMaxHR)
        XCTAssertFalse(result.isValid, "Sprint with no HR data should be invalid")
    }
    
    // MARK: - Zone 4 Threshold Varies by Max HR
    
    func testYoungerAthleteHigherThreshold() {
        let youngerMaxHR = 200 // Zone 4 = 160
        let data = makeSprintData(hrSamples: [130, 140, 155, 158], peakHR: 158)
        let result = validator.validate(data, maxHR: youngerMaxHR)
        XCTAssertFalse(result.isValid, "158 < 160 (80% of 200), should be invalid")
    }
    
    func testOlderAthleteLowerThreshold() {
        let olderMaxHR = 170 // Zone 4 = 136
        let data = makeSprintData(hrSamples: [110, 120, 130, 140], peakHR: 140)
        let result = validator.validate(data, maxHR: olderMaxHR)
        XCTAssertTrue(result.isValid, "140 >= 136 (80% of 170), should be valid")
    }
    
    // MARK: - Result Data
    
    func testResultContainsCorrectData() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 160],
            peakHR: 160
        )
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.baselineHR, 120)
        XCTAssertEqual(result.peakHR, 160)
        XCTAssertEqual(result.zone4Threshold, 152)
        XCTAssertGreaterThan(result.duration, 0)
    }
}
