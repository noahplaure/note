import Foundation

public final class FilePresenterCoordinator: NSObject, NSFilePresenter, @unchecked Sendable {
    public let presentedItemURL: URL?
    public let presentedItemOperationQueue: OperationQueue

    private var directorySource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChangeHandler: @Sendable () -> Void

    public init(directoryURL: URL, onChange: @escaping @Sendable () -> Void) {
        self.presentedItemURL = directoryURL
        self.presentedItemOperationQueue = OperationQueue()
        self.presentedItemOperationQueue.maxConcurrentOperationCount = 1
        self.onChangeHandler = onChange
        super.init()

        startWatching(url: directoryURL)
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        stopWatching()
        NSFileCoordinator.removeFilePresenter(self)
    }

    private func startWatching(url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .link, .rename, .delete, .extend],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.onChangeHandler()
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        self.directorySource = source
        source.resume()
    }

    private func stopWatching() {
        if let source = directorySource {
            source.cancel()
            directorySource = nil
        }
    }

    // MARK: - NSFilePresenter

    public func presentedItemDidChange() {
        onChangeHandler()
    }

    public func presentedSubitemDidChange(at url: URL) {
        onChangeHandler()
    }
}
