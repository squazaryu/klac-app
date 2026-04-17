import Foundation

final class SamplePicker<Group: Hashable> {
    private var lastIndexByGroup: [Group: Int] = [:]

    func pick<T>(from pool: [T], group: Group) -> T? {
        guard !pool.isEmpty else { return nil }
        if pool.count == 1 {
            lastIndexByGroup[group] = 0
            return pool[0]
        }

        let previous = lastIndexByGroup[group]
        var idx = Int.random(in: 0 ..< pool.count)
        if let previous {
            var guardCounter = 0
            while idx == previous && guardCounter < 4 {
                idx = Int.random(in: 0 ..< pool.count)
                guardCounter += 1
            }
        }
        lastIndexByGroup[group] = idx
        return pool[idx]
    }
}
