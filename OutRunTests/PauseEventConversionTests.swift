import Foundation
@testable import OutRun
@testable import OutRunCore
import Testing

@Suite("Pause Event Conversion Tests")
struct PauseEventConversionTests {
    
    private static let startDates: [Date] = [
        .distantPast,                                       // distant past
        .init(timeIntervalSince1970: -315760000),           // ~ -10 years
        .init(timeIntervalSince1970: 0),                    // 1970.01.01
        .init(timeIntervalSince1970: 157785000),            // ~ +5 years
        .init(timeIntervalSinceReferenceDate: -220752000),  // ~ -7 years
        .init(timeIntervalSinceReferenceDate: 0),           // 2001.01.01
        .init(timeIntervalSinceReferenceDate: 419151283.2), // ~ +13.3 years
        .init(timeIntervalSinceReferenceDate: 848952273.6), // ~ +26.9 years
        .init(timeIntervalSinceReferenceDate: 3264859.008), // ~ +103.5 years
        .distantFuture,                                     // distant future
    ]
    
    @Test("No Pause Events", arguments: startDates)
    func noPauseEvents(start: Date) {
        let end = start.addingTimeInterval(10)
        let pauses = LegacyMigrationHelper.calculatePauses(from: [], workoutStart: start, workoutEnd: end)
        #expect(pauses.isEmpty)
    }
    
    @Test("Full Pause", arguments: startDates)
    func fullAutoPause(start: Date) {
        let duration: TimeInterval = 10
        let end = start.addingTimeInterval(duration)
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start, type: .pause),
            .init(date: end, type: .resume),
        ]
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start)
        #expect(pauses[0].endDate == end)
        #expect(pauses[0].startDate.distance(to: pauses[0].endDate) == duration)
    }
    
    // MARK: - Basic Pause Types
    
    @Test("Single Manual Pause", arguments: startDates)
    func singleManualPause(start: Date) {
        let duration: TimeInterval = 10
        let end = start.addingTimeInterval(30)
        let pauseStart = start.addingTimeInterval(5)
        let pauseEnd = start.addingTimeInterval(15)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: pauseStart, type: .pause),
            .init(date: pauseEnd, type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == pauseStart)
        #expect(pauses[0].endDate == pauseEnd)
        #expect(pauses[0].userInitiated == true)
        #expect(pauses[0].startDate.distance(to: pauses[0].endDate) == duration)
    }
    
    @Test("Single Auto Pause", arguments: startDates)
    func singleAutoPause(start: Date) {
        let duration: TimeInterval = 8
        let end = start.addingTimeInterval(25)
        let pauseStart = start.addingTimeInterval(3)
        let pauseEnd = start.addingTimeInterval(11)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: pauseStart, type: .autoPause),
            .init(date: pauseEnd, type: .autoResume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == pauseStart)
        #expect(pauses[0].endDate == pauseEnd)
        #expect(pauses[0].userInitiated == false)
        #expect(pauses[0].startDate.distance(to: pauses[0].endDate) == duration)
    }
    
    @Test("Multiple Non-overlapping Pauses", arguments: startDates)
    func multipleNonOverlappingPauses(start: Date) {
        let end = start.addingTimeInterval(100)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(20), type: .resume),
            .init(date: start.addingTimeInterval(40), type: .autoPause),
            .init(date: start.addingTimeInterval(50), type: .autoResume),
            .init(date: start.addingTimeInterval(70), type: .pause),
            .init(date: start.addingTimeInterval(80), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 3)
        
        let sortedPauses = pauses.sorted { $0.startDate < $1.startDate }
        #expect(sortedPauses[0].userInitiated == true)
        #expect(sortedPauses[1].userInitiated == false)
        #expect(sortedPauses[2].userInitiated == true)
    }
    
    @Test("Mixed Manual and Auto Pauses", arguments: startDates)
    func mixedManualAndAutoPauses(start: Date) {
        let end = start.addingTimeInterval(60)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(5), type: .autoPause),
            .init(date: start.addingTimeInterval(15), type: .autoResume),
            .init(date: start.addingTimeInterval(25), type: .pause),
            .init(date: start.addingTimeInterval(35), type: .resume),
            .init(date: start.addingTimeInterval(45), type: .autoPause),
            .init(date: start.addingTimeInterval(55), type: .autoResume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 3)
        
        let sortedPauses = pauses.sorted { $0.startDate < $1.startDate }
        #expect(sortedPauses[0].userInitiated == false)
        #expect(sortedPauses[1].userInitiated == true)
        #expect(sortedPauses[2].userInitiated == false)
    }
    
    // MARK: - Overlapping Pauses
    
    @Test("Manual Pause Overlapping Auto Pause", arguments: startDates)
    func manualOverlappingAuto(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(5), type: .autoPause),
            .init(date: start.addingTimeInterval(15), type: .pause),
            .init(date: start.addingTimeInterval(25), type: .resume),
            .init(date: start.addingTimeInterval(35), type: .autoResume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 3)
        #expect(pauses[0].userInitiated == false)
        #expect(pauses[0].startDate == start.addingTimeInterval(5))
        #expect(pauses[0].endDate == start.addingTimeInterval(15))
        #expect(pauses[1].userInitiated == true)
        #expect(pauses[1].startDate == start.addingTimeInterval(15))
        #expect(pauses[1].endDate == start.addingTimeInterval(25))
        #expect(pauses[2].userInitiated == false)
        #expect(pauses[2].startDate == start.addingTimeInterval(25))
        #expect(pauses[2].endDate == start.addingTimeInterval(35))
    }
    
    @Test("Auto Pause Then Manual Pause", arguments: startDates)
    func autoPauseThenManual(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(5), type: .autoPause),
            .init(date: start.addingTimeInterval(15), type: .pause),
            .init(date: start.addingTimeInterval(25), type: .resume),
            .init(date: start.addingTimeInterval(35), type: .autoResume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        let firstAutoPause = pauses.first { !$0.userInitiated }
        let lastAutoPause = pauses.last { !$0.userInitiated }
        let manualPause = pauses.first { $0.userInitiated }
        #expect(pauses.count == 3)
        #expect(firstAutoPause?.endDate == start.addingTimeInterval(15))
        #expect(manualPause?.startDate == start.addingTimeInterval(15))
        #expect(manualPause?.endDate == start.addingTimeInterval(25))
        #expect(lastAutoPause?.startDate == start.addingTimeInterval(25))
    }
    
    @Test("Multiple Overlapping Manual Pauses", arguments: startDates)
    func multipleOverlappingManualPauses(start: Date) {
        let end = start.addingTimeInterval(60)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(15), type: .pause),
            .init(date: start.addingTimeInterval(25), type: .resume),
            .init(date: start.addingTimeInterval(30), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].userInitiated == true)
        #expect(pauses[0].startDate == start.addingTimeInterval(10))
        #expect(pauses[0].endDate == start.addingTimeInterval(30))
    }
    
    // MARK: - Boundary Cases
    
    @Test("Pause Starts Before Workout", arguments: startDates)
    func pauseStartsBeforeWorkout(start: Date) {
        let end = start.addingTimeInterval(50)
        let pauseStart = start.addingTimeInterval(-10)
        let pauseEnd = start.addingTimeInterval(15)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: pauseStart, type: .pause),
            .init(date: pauseEnd, type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start)
        #expect(pauses[0].endDate == pauseEnd)
    }
    
    @Test("Pause Ends After Workout", arguments: startDates)
    func pauseEndsAfterWorkout(start: Date) {
        let end = start.addingTimeInterval(50)
        let pauseStart = start.addingTimeInterval(30)
        let pauseEnd = start.addingTimeInterval(70)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: pauseStart, type: .pause),
            .init(date: pauseEnd, type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == pauseStart)
        #expect(pauses[0].endDate == end)
    }
    
    @Test("Pause Spans Entire Workout", arguments: startDates)
    func pauseSpansEntireWorkout(start: Date) {
        let end = start.addingTimeInterval(30)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start, type: .pause),
            .init(date: end, type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start)
        #expect(pauses[0].endDate == end)
    }
    
    @Test("Events Outside Workout Range", arguments: startDates)
    func eventsOutsideWorkoutRange(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(-20), type: .pause),
            .init(date: start.addingTimeInterval(-10), type: .resume),
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(20), type: .resume),
            .init(date: start.addingTimeInterval(60), type: .pause),
            .init(date: start.addingTimeInterval(70), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start.addingTimeInterval(10))
        #expect(pauses[0].endDate == start.addingTimeInterval(20))
    }
    
    // MARK: - Minimum Duration Filtering
    
    @Test("Pause Under Minimum Duration", arguments: startDates)
    func pauseUnderMinimumDuration(start: Date) {
        let end = start.addingTimeInterval(50)
        let minimumDuration: TimeInterval = 10
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(15), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end, minimumDuration: minimumDuration)
        #expect(pauses.isEmpty)
    }
    
    @Test("Mixed Duration Pauses", arguments: startDates)
    func mixedDurationPauses(start: Date) {
        let end = start.addingTimeInterval(100)
        let minimumDuration: TimeInterval = 10
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(5), type: .pause),
            .init(date: start.addingTimeInterval(10), type: .resume),
            .init(date: start.addingTimeInterval(20), type: .pause),
            .init(date: start.addingTimeInterval(35), type: .resume),
            .init(date: start.addingTimeInterval(50), type: .pause),
            .init(date: start.addingTimeInterval(55), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end, minimumDuration: minimumDuration)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start.addingTimeInterval(20))
        #expect(pauses[0].endDate == start.addingTimeInterval(35))
    }
    
    // MARK: - Malformed Event Sequences
    
    @Test("Pause Without Resume", arguments: startDates)
    func pauseWithoutResume(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .pause),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start.addingTimeInterval(10))
        #expect(pauses[0].endDate == end)
    }
    
    @Test("Resume Without Pause", arguments: startDates)
    func resumeWithoutPause(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.isEmpty)
    }
    
    @Test("Multiple Pause Events", arguments: startDates)
    func multiplePauseEvents(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(15), type: .pause),
            .init(date: start.addingTimeInterval(30), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start.addingTimeInterval(10))
        #expect(pauses[0].endDate == end)
    }
    
    @Test("Out of Order Events", arguments: startDates)
    func outOfOrderEvents(start: Date) {
        let end = start.addingTimeInterval(50)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(40), type: .resume),
            .init(date: start.addingTimeInterval(20), type: .resume),
            .init(date: start.addingTimeInterval(10), type: .pause),
            .init(date: start.addingTimeInterval(30), type: .pause),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 2)
        
        let sortedPauses = pauses.sorted { $0.startDate < $1.startDate }
        #expect(sortedPauses[0].startDate == start.addingTimeInterval(10))
        #expect(sortedPauses[0].endDate == start.addingTimeInterval(20))
        #expect(sortedPauses[1].startDate == start.addingTimeInterval(30))
        #expect(sortedPauses[1].endDate == start.addingTimeInterval(40))
    }
    
    // MARK: - Edge Cases
    
    @Test("Zero Duration Pause", arguments: startDates)
    func zeroDurationPause(start: Date) {
        let end = start.addingTimeInterval(50)
        let pauseTime = start.addingTimeInterval(25)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: pauseTime, type: .pause),
            .init(date: pauseTime, type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 0)
    }
    
    @Test("Very Short Workout", arguments: startDates)
    func veryShortWorkout(start: Date) {
        let end = start.addingTimeInterval(0.5)
        
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(0.1), type: .pause),
            .init(date: start.addingTimeInterval(0.4), type: .resume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end)
        #expect(pauses.count == 1)
        #expect(pauses[0].startDate == start.addingTimeInterval(0.1))
        #expect(pauses[0].endDate == start.addingTimeInterval(0.4))
    }
    
    // MARK: - Special Documentation Case
    
    @Test("Documentation Example", arguments: startDates)
    func documentationExample(start: Date) {
        let end = start.addingTimeInterval(205)
        let events: [LegacyMigrationHelper.PauseEvent] = [
            .init(date: start.addingTimeInterval(-10), type: .autoPause),
            .init(date: start.addingTimeInterval(5), type: .autoResume),
            .init(date: start.addingTimeInterval(30), type: .pause),
            .init(date: start.addingTimeInterval(35), type: .autoPause),
            .init(date: start.addingTimeInterval(55), type: .autoResume),
            .init(date: start.addingTimeInterval(60), type: .resume),
            .init(date: start.addingTimeInterval(95), type: .pause),
            .init(date: start.addingTimeInterval(120), type: .autoPause),
            .init(date: start.addingTimeInterval(130), type: .pause),
            .init(date: start.addingTimeInterval(135), type: .resume),
            .init(date: start.addingTimeInterval(145), type: .resume),
            .init(date: start.addingTimeInterval(150), type: .autoResume),
            .init(date: start.addingTimeInterval(195), type: .autoPause),
            .init(date: start.addingTimeInterval(215), type: .autoResume),
        ]
        
        let pauses = LegacyMigrationHelper.calculatePauses(from: events, workoutStart: start, workoutEnd: end, minimumDuration: 10)
        
        #expect(pauses.count == 3)
        #expect(pauses[0].userInitiated == true)
        #expect(pauses[0].startDate == start.addingTimeInterval(30))
        #expect(pauses[0].endDate == start.addingTimeInterval(60))
        #expect(pauses[1].userInitiated == true)
        #expect(pauses[1].startDate == start.addingTimeInterval(95))
        #expect(pauses[1].endDate == start.addingTimeInterval(145))
        #expect(pauses[2].userInitiated == false)
        #expect(pauses[2].startDate == start.addingTimeInterval(195))
        #expect(pauses[2].endDate == start.addingTimeInterval(205))
    }
}
