import Combine
import CoreMotion

/// A helper containing static functions to assist with CoreMotion components.
enum CoreMotionHelper {
    
    /// Requests "Motion & Fitness" authorization by querying the users activity at the current moment.
    /// - warning: This method to aquire the generalized "Motion & Fitness" authorization for all CoreMotion components might break due to
    /// internal API changes. Proceed with caution.
    static func requestMotionAndFitnessAuthorization() async {
        let motionActivityManager = CMMotionActivityManager()
        await withCheckedContinuation { continuation in
            motionActivityManager.queryActivityStarting(from: .now, to: .now, to: .main) { _, _ in
                continuation.resume()
                
            }
        }
    }
}
