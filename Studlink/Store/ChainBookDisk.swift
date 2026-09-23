import Foundation

/// File projection of ChainBook. Atomic write, backup, off the main thread.
actor ChainBookDisk {
    static let fileName = "sdl.chainbook.v1.json"

    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL) {
        self.directory = directory
        fileManager = FileManager()
    }

    var fileURL: URL {
        directory.appendingPathComponent(Self.fileName, isDirectory: false)
    }

    var backupURL: URL {
        fileURL.appendingPathExtension("backup")
    }

    func save(_ book: ChainBook) throws -> Data {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try ChainBookCodec.encoder().encode(book)
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        return data
    }

    func load() -> ChainBook? {
        if let data = try? Data(contentsOf: fileURL), let book = ChainBookCodec.decode(data) {
            return book
        }
        if let data = try? Data(contentsOf: backupURL), let book = ChainBookCodec.decode(data) {
            return book
        }
        return nil
    }

    func reset() throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
    }
}
