import Foundation
import NIOCore

enum MigrationHelper {
    
    struct PauseEvent {
        let date: Date
        let type: PauseEventType
        
        enum PauseEventType: Int {
            case pause = 0
            case autoPause = 1
            case resume = 2
            case autoResume = 3
            
            var isPauseStart: Bool {
                switch self {
                case .pause, .autoPause: true
                case .resume, .autoResume: false
                }
            }
        }
    }
    
    /**
     Computes pauses from workout event data.
     - parameter events: The events from which the pauses are supposed to be calculated
     - parameter workoutStart: The start date of the workout to which the pauses are linked
     - parameter workoutEnd: The start date of the workout to which the pauses are linked
     - parameter minimumDuration: The minimum duration of a pause object. Objects with smaller duration will be filtered out. Provided
       values must be larger than 0.
     - returns: The calculated pause objects
     - complexity: O(*n* log *n*) in the number of events *n*.
     
     Workout event data might be inconsistent, in which case we try to recover pauses as follows:
     - Pauses that extend over the start or end of the workout (start...end) get trimmed at the start or end.
     - Overlapping pauses get merged if their types match
     - User initiated pauses take precedence over automatic pauses
     - Pauses of duration under 1s are ignored
     
     To illustrate, here is an example with user initiated (+) and automatic pauses (\*):
     ```
       start.................................end
     
       |---------------ORIGINAL----------------|
     
            +++++++             ++++
                         +++++++++
     ***     *****            *******        *****
     
       |---------------CONVERTED---------------|
     
            +++++++      +++++++++++         ***
     ```
     */
    static func calculatePauses(
        from events: [PauseEvent],
        workoutStart: Date,
        workoutEnd: Date,
        minimumDuration: TimeInterval = .leastNonzeroMagnitude
    ) -> [RawWorkoutPause] {
        let sortedEvents = events
            .map { PauseEvent(date: max(workoutStart, min(workoutEnd, $0.date)), type: $0.type) }
            .sorted { $0.date < $1.date }
        var pauses = [RawWorkoutPause]()
        var pauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        var autoPauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        for pauseEvent in sortedEvents {
            switch pauseEvent.type {
            case .pause:
                if pauseStarts.isEmpty, let firstAutoPauseStart = autoPauseStarts.first {
                    pauses.append(.init(id: .init(), startDate: firstAutoPauseStart, endDate: pauseEvent.date, userInitiated: false))
                }
                pauseStarts.append(pauseEvent.date)
            case .autoPause:
                autoPauseStarts.append(pauseEvent.date)
            case .resume:
                guard let start = pauseStarts.popLast(), pauseStarts.isEmpty else { continue }
                pauses.append(.init(id: .init(), startDate: start, endDate: pauseEvent.date, userInitiated: true))
            case .autoResume:
                guard let potentialStart = autoPauseStarts.popLast(), autoPauseStarts.isEmpty, pauseStarts.isEmpty else { continue }
                let start = if let lastPauseEnd = pauses.last?.endDate { max(potentialStart, lastPauseEnd) } else { potentialStart }
                pauses.append(.init(id: .init(), startDate: start, endDate: pauseEvent.date, userInitiated: false))
            }
        }
        if let pauseStart = pauseStarts.first {
            pauses.append(.init(id: .init(), startDate: pauseStart, endDate: workoutEnd, userInitiated: true))
        } else if let autoPauseStart = autoPauseStarts.first {
            pauses.append(.init(id: .init(), startDate: autoPauseStart, endDate: workoutEnd, userInitiated: false))
        }
        let safeMinimumDuration = max(minimumDuration, .leastNonzeroMagnitude)
        return pauses.filter { $0.duration >= safeMinimumDuration }
    }
}
