import Foundation
import Observation

// S3 — Obsidian 볼트 폴더(보안 스코프 북마크) 관리 + 파일 쓰기.
@Observable
final class VaultStore {
    private let key = "obsidianVaultBookmark"
    private(set) var vaultURL: URL?

    init() { vaultURL = resolve() }

    #if os(macOS)
    private static let createOpts: URL.BookmarkCreationOptions = [.withSecurityScope]
    private static let resolveOpts: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #else
    private static let createOpts: URL.BookmarkCreationOptions = []
    private static let resolveOpts: URL.BookmarkResolutionOptions = []
    #endif

    func setVault(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let data = try? url.bookmarkData(options: Self.createOpts,
                                            includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: key)
            vaultURL = url
        }
    }

    private func resolve() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: Self.resolveOpts,
                        relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    /// 볼트의 하위 폴더에 파일 쓰기(보안 스코프 접근 안에서).
    func write(subdir: String, filename: String, content: String) {
        guard let root = vaultURL else { return }
        let scoped = root.startAccessingSecurityScopedResource()
        defer { if scoped { root.stopAccessingSecurityScopedResource() } }
        let dir = root.appendingPathComponent(subdir, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? content.write(to: dir.appendingPathComponent(filename), atomically: true, encoding: .utf8)
    }

    func deleteFile(subdir: String, filename: String) {
        guard let root = vaultURL else { return }
        let scoped = root.startAccessingSecurityScopedResource()
        defer { if scoped { root.stopAccessingSecurityScopedResource() } }
        let url = root.appendingPathComponent(subdir, isDirectory: true).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
