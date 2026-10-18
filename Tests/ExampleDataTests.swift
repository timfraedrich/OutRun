//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

@testable import OutRun
@testable import OutRunCore
import Testing

struct ExampleDataTests {
    
    @Test("Check Legacy Backup Data")
    func checkExampleData() throws {
        let v1BackupData: LegacyBackup<LegacyRawDataModelV1.Workout> = try TestUtil.readORBUP(with: "OutRunV1")
        let v2BackupData: LegacyBackup<LegacyRawDataModelV2.Workout> = try TestUtil.readORBUP(with: "OutRunV2")
        let v3BackupData: LegacyBackup<LegacyRawDataModelV3.Workout> = try TestUtil.readORBUP(with: "OutRunV3")
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
