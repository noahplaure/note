import Foundation

public final class Debouncer: @unchecked Sendable {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    public init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    public func call(action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }
}
