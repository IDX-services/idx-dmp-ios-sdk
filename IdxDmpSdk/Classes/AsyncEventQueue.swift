public final class AsyncEventQueue {
    private let serialQueue = DispatchQueue(label: "sdk.dmp.idx", qos: .background)

    func addTask(_ task: @escaping (@escaping () -> Void) -> Void) {
        serialQueue.async {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            task {
                dispatchGroup.leave()
            }

            dispatchGroup.wait()
        }
    }
}
