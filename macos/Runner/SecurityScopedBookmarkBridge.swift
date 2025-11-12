import Foundation
import FlutterMacOS

class SecurityScopedBookmarkBridge {
  static let shared = SecurityScopedBookmarkBridge()

  private var channel: FlutterMethodChannel?
  private var activeBookmarks: [String: URL] = [:]

  private init() {}

  func configure(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "pastel_diary/security_scoped_bookmarks",
      binaryMessenger: messenger)
    channel?.setMethodCallHandler(nil)
    channel = methodChannel
    methodChannel.setMethodCallHandler(handle)
  }

  func stopAll() {
    for (_, url) in activeBookmarks {
      url.stopAccessingSecurityScopedResource()
    }
    activeBookmarks.removeAll()
    channel?.setMethodCallHandler(nil)
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createBookmark":
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "Missing path", details: nil))
        return
      }
      createBookmark(forPath: path, result: result)

    case "startAccessingBookmark":
      guard
        let arguments = call.arguments as? [String: Any],
        let bookmark = arguments["bookmark"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "Missing bookmark", details: nil))
        return
      }
      startAccessing(bookmark: bookmark, result: result)

    case "stopAccessingBookmark":
      guard
        let arguments = call.arguments as? [String: Any],
        let bookmark = arguments["bookmark"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "Missing bookmark", details: nil))
        return
      }
      stopAccessing(bookmark: bookmark)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func createBookmark(forPath path: String, result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path, isDirectory: true)
    do {
      let bookmarkData = try url.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil)
      result(bookmarkData.base64EncodedString())
    } catch {
      result(
        FlutterError(
          code: "bookmark_error",
          message: "Failed to create bookmark: \(error.localizedDescription)",
          details: nil))
    }
  }

  private func startAccessing(bookmark: String, result: @escaping FlutterResult) {
    guard let bookmarkData = Data(base64Encoded: bookmark) else {
      result(FlutterError(code: "bookmark_error", message: "Invalid bookmark data", details: nil))
      return
    }

    var isStale = false
    do {
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale)

      if let existing = activeBookmarks[bookmark] {
        existing.stopAccessingSecurityScopedResource()
      }

      if !url.startAccessingSecurityScopedResource() {
        result(
          FlutterError(
            code: "bookmark_error",
            message: "Unable to access resource for bookmark.",
            details: nil))
        return
      }

      if isStale {
        let refreshedData = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil)
        let refreshedBookmark = refreshedData.base64EncodedString()
        activeBookmarks.removeValue(forKey: bookmark)
        activeBookmarks[refreshedBookmark] = url
        result(["path": url.path, "bookmark": refreshedBookmark])
      } else {
        activeBookmarks[bookmark] = url
        result(["path": url.path])
      }
    } catch {
      result(
        FlutterError(
          code: "bookmark_error",
          message: "Failed to resolve bookmark: \(error.localizedDescription)",
          details: nil))
    }
  }

  private func stopAccessing(bookmark: String) {
    if let url = activeBookmarks.removeValue(forKey: bookmark) {
      url.stopAccessingSecurityScopedResource()
    }
  }
}
