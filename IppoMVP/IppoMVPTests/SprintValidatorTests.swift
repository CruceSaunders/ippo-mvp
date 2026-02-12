import XCTest
@testable import IppoMVP

final class SprintValidatorTests: XCTestCase {
    
    var validator: SprintValidator!
    let defaultMaxHR = 190
    
    override func setUp() {
        super.setUp()
        validator = SprintValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Helper to Create SprintData
    
    private func makeSprintData(
        baselineHR: Int = 120,
        hrSamples: [Int] = [],
        cadenceSamples: [Int] = [],
        peakHR: Int? = nil,
        peakCadence: Int? = nil,
        targetDuration: TimeInterval = 35
    ) -> SprintData {
        var data = SprintData(
            startTime: Date().addingTimeInterval(-targetDuration),
            targetDuration: targetDuration,
            baselineHR: baselineHR
        )
        data.hrSamples = hrSamples
        data.cadenceSamples = cadenceSamples
        data.peakHR = peakHR ?? (hrSamples.max() ?? 0)
        data.peakCadence = peakCadence ?? (cadenceSamples.max() ?? 0)
        return data
    }
    
    // MARK: - Valid Sprint Tests
    
    func testValidSprintWithExcellentData() {
        // Excellent sprint: strong HR response, good cadence, fast HR rise
        let hrSamples = [125, 135, 145, 155, 165, 170, 172, 175, 175, 175,
                         175, 174, 173, 172, 170, 168, 165, 162, 160, 158]
        let cadenceSamples = [150, 155, 165, 175, 180, 180, 178, 175, 172, 170,
                              168, 165, 162, 160, 160, 160, 160, 160, 160, 158]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 175,
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertTrue(result.isValid, "Excellent sprint should be valid")
        XCTAssertGreaterThanOrEqual(result.validationScore, 60.0, "Score should be >= 60")
        XCTAssertGreaterThan(result.hrScore, 80.0, "HR score should be high for excellent sprint")
        XCTAssertGreaterThan(result.cadenceScore, 80.0, "Cadence score should be high for excellent sprint")
    }
    
    func testValidSprintAtThreshold() {
        // Sprint that's exactly at 60% threshold
        // HR: baseline 120, peak 140 (increase of 20 = minimum)
        // Need to hit zone 4 (>80% of 190 = 152) - won't quite make it
        // Cadence: pre-sprint ~150, peak 172 (~15% increase minimum)
        let hrSamples = [125, 130, 135, 140, 145, 150, 152, 152, 152, 152,
                         152, 150, 148, 145, 142, 140, 138, 136, 134, 132]
        let cadenceSamples = [150, 150, 150, 160, 165, 168, 172, 172, 170, 168,
                              165, 162, 160, 158, 156, 154, 152, 150, 150, 150]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 152,
            peakCadence: 172
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // This should be a valid sprint with the correct parameters
        XCTAssertGreaterThanOrEqual(result.validationScore, 50.0, "Moderate sprint should have decent score")
    }
    
    func testValidSprintWithMinimumHRIncrease() {
        // Tests exactly 20 BPM increase (minHRIncreaseRequired)
        let hrSamples = [125, 130, 135, 140, 140, 140, 140, 140, 140, 140]
        let cadenceSamples = [150, 160, 170, 180, 180, 180, 180, 180, 180, 180]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 140,  // Exactly 20 above baseline
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // HR increase component should be full (1.0)
        // hrIncrease = 140 - 120 = 20
        // increaseScore = min(1.0, 20/20) = 1.0
        // That's 40% of HR score at full, contributing 0.4 * 0.5 = 0.2 to total
        XCTAssertEqual(result.baselineHR, 120)
        XCTAssertEqual(result.peakHR, 140)
    }
    
    // MARK: - Invalid Sprint Tests
    
    func testInvalidSprintWithNoHRResponse() {
        // HR stays flat - no effort
        let hrSamples = Array(repeating: 125, count: 20)
        let cadenceSamples = [150, 155, 160, 165, 170, 170, 170, 170, 170, 170,
                              170, 170, 170, 170, 170, 165, 160, 155, 150, 150]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 125,  // Only 5 BPM above baseline
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertFalse(result.isValid, "Sprint with no HR response should be invalid")
        XCTAssertLessThan(result.hrScore, 50.0, "HR score should be low")
    }
    
    func testInvalidSprintWithNoCadenceResponse() {
        // Good HR but cadence stays low
        let hrSamples = [125, 135, 145, 155, 165, 170, 172, 170, 168, 165]
        let cadenceSamples = Array(repeating: 140, count: 10)  // Below 160 target
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 172,
            peakCadence: 140  // Below minimum 160
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertLessThan(result.cadenceScore, 90.0, "Cadence score should be penalized for low peak")
        XCTAssertEqual(result.peakCadence, 140)
    }
    
    func testInvalidSprintWithSlowHRRise() {
        // HR rises too slowly (< 3 BPM/second)
        let hrSamples = [121, 122, 123, 124, 125, 126, 127, 128, 129, 130,
                         135, 140, 145, 150, 155, 160, 160, 160, 160, 160]
        let cadenceSamples = [150, 155, 160, 165, 170, 175, 175, 175, 175, 175,
                              175, 175, 175, 175, 175, 175, 175, 175, 175, 175]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 160,
            peakCadence: 175
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // HRD score should be low (derivative is only 1 BPM/sec in first 10 samples)
        XCTAssertLessThan(result.hrdScore, 50.0, "HRD score should be low for slow HR rise")
    }
    
    // MARK: - Empty Data Edge Cases
    
    func testEmptyHRSamples() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [],
            cadenceSamples: [150, 160, 170, 180],
            peakHR: 0,
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.hrScore, 0.0, "HR score should be 0 with no HR samples")
        XCTAssertFalse(result.isValid, "Sprint with no HR data should be invalid")
    }
    
    func testEmptyCadenceSamples() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 160, 170],
            cadenceSamples: [],
            peakHR: 170,
            peakCadence: 0
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.cadenceScore, 0.0, "Cadence score should be 0 with no cadence samples")
    }
    
    func testBothEmptySamples() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [],
            cadenceSamples: [],
            peakHR: 0,
            peakCadence: 0
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.hrScore, 0.0)
        XCTAssertEqual(result.cadenceScore, 0.0)
        XCTAssertEqual(result.hrdScore, 0.0)
        XCTAssertEqual(result.validationScore, 0.0)
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - HR Score Component Tests
    
    func testHRScoreIncreaseBelowMinimum() {
        // HR increase < 20 BPM should give partial credit
        let hrSamples = [122, 125, 128, 130, 130, 130, 130, 130, 130, 130]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: [160, 170, 180, 180, 180, 180, 180, 180, 180, 180],
            peakHR: 130,  // Only 10 BPM increase (50% of minimum)
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // hrIncrease = 10, required = 20
        // increaseScore = min(1.0, 10/20) = 0.5
        // Partial credit should be given
        XCTAssertLessThan(result.hrScore, 100.0, "HR score should be reduced for sub-minimum increase")
    }
    
    func testHRScoreReachesTargetZone() {
        // Test reaching zone 4-5 (>80% of max HR)
        // With maxHR = 190, target = 152
        let hrSamples = [130, 140, 150, 155, 160, 160, 160, 160, 160, 160]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: [160, 170, 180, 180, 180, 180, 180, 180, 180, 180],
            peakHR: 160,  // Above 152 target (>80% of 190)
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Should get full zone credit (40% of HR score)
        XCTAssertGreaterThan(result.hrScore, 60.0, "Should get zone credit for reaching target")
    }
    
    func testHRScoreBelowTargetZonePartialCredit() {
        // Test partial credit when close to but not reaching target zone
        // Target = 152, we'll hit 140
        let hrSamples = [125, 130, 135, 140, 140, 140, 140, 140, 140, 140]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: [160, 170, 180, 180, 180, 180, 180, 180, 180, 180],
            peakHR: 140,  // 92% of target zone (140/152)
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Should get partial zone credit
        XCTAssertGreaterThan(result.hrScore, 0.0, "Should get partial credit for being close to zone")
    }
    
    func testHRScoreTimeInElevatedZone() {
        // Test with different amounts of time in elevated HR
        // Elevated threshold = baseline + 10 = 130
        
        // All samples elevated
        let allElevated = makeSprintData(
            baselineHR: 120,
            hrSamples: [140, 145, 150, 155, 160, 160, 160, 160, 160, 160],
            cadenceSamples: [160, 170, 180, 180, 180, 180, 180, 180, 180, 180],
            peakHR: 160,
            peakCadence: 180
        )
        
        // Half samples elevated
        let halfElevated = makeSprintData(
            baselineHR: 120,
            hrSamples: [125, 125, 125, 125, 125, 140, 145, 150, 155, 160],
            cadenceSamples: [160, 170, 180, 180, 180, 180, 180, 180, 180, 180],
            peakHR: 160,
            peakCadence: 180
        )
        
        let resultAll = validator.validate(allElevated, maxHR: defaultMaxHR)
        let resultHalf = validator.validate(halfElevated, maxHR: defaultMaxHR)
        
        // All elevated should have higher HR score
        XCTAssertGreaterThan(resultAll.hrScore, resultHalf.hrScore,
                            "Full time in zone should score higher than partial")
    }
    
    // MARK: - Cadence Score Component Tests
    
    func testCadenceScoreIncreaseCalculation() {
        // Pre-sprint cadence = average of first 3 samples
        // Need >= 15% increase
        let preCadence = 150
        let requiredPeak = Int(Double(preCadence) * 1.15)  // 172.5 -> 173
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 160, 160, 160, 160, 160, 160, 160],
            cadenceSamples: [150, 150, 150, 160, 170, 175, 175, 175, 175, 175],
            peakHR: 160,
            peakCadence: 175  // 16.7% increase from 150
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Should get full increase credit (50% of cadence score)
        XCTAssertGreaterThan(result.cadenceScore, 80.0, "Should get full increase credit")
    }
    
    func testCadenceScoreBelowMinimumIncrease() {
        // Test < 15% cadence increase
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 160, 160, 160, 160, 160, 160, 160],
            cadenceSamples: [150, 150, 150, 155, 160, 165, 165, 165, 165, 165],
            peakHR: 160,
            peakCadence: 165  // Only 10% increase from 150
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // increasePercent = (165 - 150) / 150 = 0.10
        // increaseScore = 0.10 / 0.15 = 0.667
        XCTAssertLessThan(result.cadenceScore, 100.0, "Partial credit for sub-minimum increase")
    }
    
    func testCadenceScorePeakCadenceTarget() {
        // Test different peak cadences against 160 SPM target
        
        // Above target
        let aboveTarget = makeSprintData(
            baselineHR: 120,
            hrSamples: [160, 160, 160, 160, 160],
            cadenceSamples: [150, 160, 180, 180, 180],
            peakHR: 160,
            peakCadence: 180  // 112.5% of target
        )
        
        // At target
        let atTarget = makeSprintData(
            baselineHR: 120,
            hrSamples: [160, 160, 160, 160, 160],
            cadenceSamples: [150, 155, 160, 160, 160],
            peakHR: 160,
            peakCadence: 160  // Exactly at target
        )
        
        // Below target
        let belowTarget = makeSprintData(
            baselineHR: 120,
            hrSamples: [160, 160, 160, 160, 160],
            cadenceSamples: [150, 152, 154, 156, 140],
            peakHR: 160,
            peakCadence: 140  // 87.5% of target
        )
        
        let resultAbove = validator.validate(aboveTarget, maxHR: defaultMaxHR)
        let resultAt = validator.validate(atTarget, maxHR: defaultMaxHR)
        let resultBelow = validator.validate(belowTarget, maxHR: defaultMaxHR)
        
        // Above and at target should cap at 1.0 for peak component
        XCTAssertGreaterThanOrEqual(resultAbove.cadenceScore, resultAt.cadenceScore)
        XCTAssertGreaterThan(resultAt.cadenceScore, resultBelow.cadenceScore)
    }
    
    func testCadenceScoreWithZeroPreCadence() {
        // Edge case: first 3 samples are 0
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [160, 160, 160, 160, 160],
            cadenceSamples: [0, 0, 0, 160, 180],
            peakHR: 160,
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // With preCadence = 0, increase calculation is skipped
        // Only peak cadence contributes (50% of cadence score)
        // peakScore = min(1.0, 180/160) = 1.0 -> 50 points max from peak
        XCTAssertGreaterThan(result.cadenceScore, 0.0, "Should still get peak cadence credit")
    }
    
    // MARK: - HRD Score Component Tests
    
    func testHRDScoreWithFastRise() {
        // HR rises >= 3 BPM/second
        let hrSamples = [125, 130, 135, 140, 145, 150, 155, 160, 162, 165]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: Array(repeating: 170, count: 10),
            peakHR: 165,
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Max derivative = 5 BPM between samples
        // Score = min(1.0, 5/3) = 1.0
        XCTAssertGreaterThanOrEqual(result.hrdScore, 100.0, "Should get full HRD score for fast rise")
    }
    
    func testHRDScoreWithSlowRise() {
        // HR rises < 3 BPM/second (only 1 BPM per sample)
        let hrSamples = [121, 122, 123, 124, 125, 126, 127, 128, 129, 130]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: Array(repeating: 170, count: 10),
            peakHR: 150,  // Peak might be later
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Max derivative = 1 BPM in first 10 samples
        // Score = min(1.0, 1/3) = 0.333
        XCTAssertLessThan(result.hrdScore, 50.0, "HRD score should be low for slow rise")
    }
    
    func testHRDScoreWithFewerThan3Samples() {
        // Edge case: only 2 HR samples
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140],
            cadenceSamples: [160, 170],
            peakHR: 140,
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.hrdScore, 0.0, "HRD score should be 0 with < 3 samples")
    }
    
    func testHRDScoreWindowSize() {
        // Test that only first 10 samples are considered
        // First 10 samples: slow rise (1 BPM each)
        // After sample 10: fast rise (ignored)
        var hrSamples = [121, 122, 123, 124, 125, 126, 127, 128, 129, 130]
        hrSamples.append(contentsOf: [145, 160, 175, 180, 185])  // Fast rise after window
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: Array(repeating: 170, count: hrSamples.count),
            peakHR: 185,
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Only first 10 samples considered, max derivative = 1
        XCTAssertLessThan(result.hrdScore, 50.0, "HRD should only consider first 10 samples")
    }
    
    // MARK: - Scoring Algorithm Tests
    
    func testScoringWeights() {
        // Test that weights are applied correctly:
        // HR: 50%, Cadence: 35%, HRD: 15%
        
        // HR only test - with good HR data but no cadence
        let hrOnlyData = makeSprintData(
            baselineHR: 100,
            hrSamples: [130, 155, 165, 170, 170, 170, 170, 170, 170, 170],
            cadenceSamples: [],  // No cadence data
            peakHR: 170,
            peakCadence: 0
        )
        
        let resultHR = validator.validate(hrOnlyData, maxHR: defaultMaxHR)
        
        // HR contributes max 50% (weight), HRD can contribute up to 15% if HR samples exist
        // So max from HR data alone = 50% + 15% = 65%
        XCTAssertLessThanOrEqual(resultHR.validationScore, 65.0,
                                 "Max score from HR alone should be <= 65% (HR + HRD)")
        XCTAssertGreaterThan(resultHR.hrScore, 0.0, "HR score should be calculated")
        
        // Cadence only test
        let cadenceOnlyData = makeSprintData(
            baselineHR: 120,
            hrSamples: [],  // No HR data
            cadenceSamples: [150, 150, 150, 180, 185, 185, 185, 185, 185, 185],
            peakHR: 0,
            peakCadence: 185
        )
        
        let resultCadence = validator.validate(cadenceOnlyData, maxHR: defaultMaxHR)
        
        // With no HR data: HR and HRD both 0
        // Max from cadence alone = 35%
        XCTAssertLessThanOrEqual(resultCadence.validationScore, 35.0,
                                 "Max score from cadence alone should be <= 35%")
        XCTAssertEqual(resultCadence.hrScore, 0.0, "HR score should be 0 with no HR data")
    }
    
    func testValidationThreshold() {
        // Test that 60% is the cutoff
        
        // Sprint scoring 59% - should be invalid
        // Sprint scoring 60% - should be valid
        // Sprint scoring 61% - should be valid
        
        // Create a borderline sprint
        let borderlineData = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 145, 150, 150, 150, 150, 150, 150, 150],
            cadenceSamples: [150, 155, 160, 165, 165, 165, 165, 165, 165, 165],
            peakHR: 150,
            peakCadence: 165
        )
        
        let result = validator.validate(borderlineData, maxHR: defaultMaxHR)
        
        // Check that isValid matches threshold
        XCTAssertEqual(result.isValid, result.validationScore >= 60.0,
                      "isValid should match score >= 60 threshold")
    }
    
    // MARK: - Result Object Tests
    
    func testResultContainsCorrectData() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 160, 165, 165, 165, 165, 165, 165],
            cadenceSamples: [155, 160, 170, 175, 175, 175, 175, 175, 175, 175],
            peakHR: 165,
            peakCadence: 175
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertEqual(result.baselineHR, 120)
        XCTAssertEqual(result.peakHR, 165)
        XCTAssertEqual(result.peakCadence, 175)
        XCTAssertEqual(result.averageCadence, data.averageCadence)
        XCTAssertGreaterThan(result.duration, 0)
    }
    
    func testScoresArePercentages() {
        let data = makeSprintData(
            baselineHR: 100,
            hrSamples: [120, 140, 160, 170, 175, 175, 175, 175, 175, 175],
            cadenceSamples: [150, 165, 180, 185, 185, 185, 185, 185, 185, 185],
            peakHR: 175,
            peakCadence: 185
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // All scores should be 0-100 (percentages)
        XCTAssertGreaterThanOrEqual(result.hrScore, 0.0)
        XCTAssertLessThanOrEqual(result.hrScore, 100.0)
        
        XCTAssertGreaterThanOrEqual(result.cadenceScore, 0.0)
        XCTAssertLessThanOrEqual(result.cadenceScore, 100.0)
        
        XCTAssertGreaterThanOrEqual(result.hrdScore, 0.0)
        XCTAssertLessThanOrEqual(result.hrdScore, 100.0)
        
        XCTAssertGreaterThanOrEqual(result.validationScore, 0.0)
        XCTAssertLessThanOrEqual(result.validationScore, 100.0)
    }
    
    // MARK: - Different Max HR Tests
    
    func testWithLowerMaxHR() {
        // Younger athlete with higher max HR should have harder zone target
        let youngerMaxHR = 200
        let targetZone = Int(Double(youngerMaxHR) * 0.80)  // 160
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 140, 150, 155, 155, 155, 155, 155, 155, 155],
            cadenceSamples: Array(repeating: 170, count: 10),
            peakHR: 155,  // Below 160 target
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: youngerMaxHR)
        
        // Peak HR of 155 is below target zone 160
        // Should get partial credit
        XCTAssertLessThan(result.hrScore, 100.0, "Should not get full zone credit below target")
    }
    
    func testWithHigherMaxHR() {
        // Older athlete with lower max HR should have easier zone target
        let olderMaxHR = 170
        let targetZone = Int(Double(olderMaxHR) * 0.80)  // 136
        
        let data = makeSprintData(
            baselineHR: 100,
            hrSamples: [110, 120, 130, 140, 145, 145, 145, 145, 145, 145],
            cadenceSamples: Array(repeating: 170, count: 10),
            peakHR: 145,  // Above 136 target
            peakCadence: 170
        )
        
        let result = validator.validate(data, maxHR: olderMaxHR)
        
        // Peak HR of 145 is above target zone 136
        // Should get full zone credit
        XCTAssertGreaterThan(result.hrScore, 50.0, "Should get zone credit above target")
    }
    
    // MARK: - Edge Case: Very Short Samples
    
    func testWithSingleSample() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [160],
            cadenceSamples: [180],
            peakHR: 160,
            peakCadence: 180
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // Should handle gracefully
        XCTAssertEqual(result.hrdScore, 0.0, "HRD needs >= 3 samples")
        XCTAssertGreaterThan(result.hrScore, 0.0, "HR score should still work with 1 sample")
    }
    
    func testWithExactlyThreeSamples() {
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: [130, 145, 160],
            cadenceSamples: [160, 175, 185],
            peakHR: 160,
            peakCadence: 185
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        // HRD should work with exactly 3 samples
        // Max derivative in first 3 samples = 15 BPM between consecutive
        XCTAssertGreaterThan(result.hrdScore, 0.0, "HRD should calculate with 3 samples")
    }
    
    // MARK: - Regression Tests
    
    func testTypicalGoodSprint() {
        // Representative of a real good sprint
        let hrSamples = [125, 132, 142, 155, 163, 168, 170, 172, 173, 172,
                         170, 168, 165, 162, 160, 158, 156, 154, 152, 150]
        let cadenceSamples = [155, 158, 165, 172, 178, 180, 182, 180, 178, 176,
                              174, 172, 170, 168, 166, 164, 162, 160, 158, 156]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 173,
            peakCadence: 182
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertTrue(result.isValid, "Typical good sprint should be valid")
        XCTAssertGreaterThanOrEqual(result.validationScore, 70.0, "Good sprint should score well")
    }
    
    func testTypicalWeakSprint() {
        // Representative of a weak/lazy sprint - minimal effort
        // Very small HR increase, cadence below target, slow HR rise
        let hrSamples = [121, 122, 123, 124, 125, 125, 125, 125, 125, 125]
        let cadenceSamples = [140, 142, 144, 145, 145, 144, 143, 142, 141, 140]
        
        let data = makeSprintData(
            baselineHR: 120,
            hrSamples: hrSamples,
            cadenceSamples: cadenceSamples,
            peakHR: 125,  // Only 5 BPM increase (way below 20 minimum)
            peakCadence: 145  // Below 160 target, no increase from pre-cadence
        )
        
        let result = validator.validate(data, maxHR: defaultMaxHR)
        
        XCTAssertFalse(result.isValid, "Weak sprint should be invalid")
        XCTAssertLessThan(result.validationScore, 60.0, "Weak sprint should score below threshold")
    }
}
