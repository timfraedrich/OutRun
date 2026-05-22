@testable import OutRun
@testable import OutRunCore
import Testing

struct ExampleDataTests {
    
    @Test("Check Legacy Backup Data")
    func checkExampleData() throws {
        let v1BackupData: LegacyBackup<LegacyRawDataModelV1.Workout> = try TestUtil.readJSON(with: "OutRunV1")
        let v2BackupData: LegacyBackup<LegacyRawDataModelV2.Workout> = try TestUtil.readJSON(with: "OutRunV2")
        let v3BackupData: LegacyBackup<LegacyRawDataModelV3.Workout> = try TestUtil.readJSON(with: "OutRunV3")
        #expect(v1BackupData.workoutData.count == 3)
        #expect(v2BackupData.workoutData.count == 3)
        #expect(v3BackupData.workoutData.count == 3)
    }
    
    @Test("Check Expected Legacy Migration Data")
    func checkExpectedData() throws {
        let v1ExpectedData: [RawWorkout] = try TestUtil.readJSON(with: "ExpectationOutRunV1")
        let v2ExpectedData: [RawWorkout] = try TestUtil.readJSON(with: "ExpectationOutRunV2")
        let v3ExpectedData: [RawWorkout] = try TestUtil.readJSON(with: "ExpectationOutRunV3")
        #expect(v1ExpectedData.count == 3)
        #expect(v2ExpectedData.count == 3)
        #expect(v3ExpectedData.count == 3)
    }
}
