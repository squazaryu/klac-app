import Foundation

struct VelocityLayerChangePlan: Equatable {
    let nextLastReportedLayer: VelocityLayer
    let shouldNotify: Bool
}

enum VelocityLayerChangeCoordinator {
    static func makePlan(lastReportedLayer: VelocityLayer?, nextLayer: VelocityLayer) -> VelocityLayerChangePlan {
        VelocityLayerChangePlan(
            nextLastReportedLayer: nextLayer,
            shouldNotify: lastReportedLayer != nextLayer
        )
    }
}
