import Dispatch
import inotify

public typealias FileDescriptor = Int
public typealias WatchDescriptor = Int

public struct FileSystemEvent {
  public var watchDescriptor: WatchDescriptor
  public var name: String

  public var mask: UInt32
  public var cookie: UInt32
  public var length: UInt32
}

public enum FileSystemEventType: UInt32 {
  case inAccess             = 0x00000001
  case inModify             = 0x00000002
  case inAttrib             = 0x00000004

  case inCloseWrite         = 0x00000008
  case inCloseNoWrite       = 0x00000010
  case inClose              = 0x00000018

  case inOpen               = 0x00000020
  case inMovedFrom          = 0x00000040
  case inMovedTo            = 0x00000080
  case inMove               = 0x000000C0

  case inCreate             = 0x00000100
  case inDelete             = 0x00000200
  case inDeleteSelf         = 0x00000400
  case inMoveSelf           = 0x00000800

  case inUnmount            = 0x00002000
  case inQueueOverflow      = 0x00004000
  case inIgnored            = 0x00008000

  case inOnlyDir            = 0x01000000
  case inDontFollow         = 0x02000000
  case inExcludeUnlink      = 0x04000000

  case inMaskAdd            = 0x20000000

  case inIsDir              = 0x40000000
  case inOneShot            = 0x80000000

  case inAllEvents          = 0x00000FFF

  @available(*, unavailable)
  public static func getTypesFromMask(_ mask: UInt32) -> [FileSystemEventType] {
    return [FileSystemEventType]()
  }
}

public class FileSystemWatcher {
  private let fileDescriptor: FileDescriptor
  private let dispatchQueue: DispatchQueue

  private var watchDescriptors: [WatchDescriptor]
  private var shouldStopWatching: Bool = false

  public init() {
    dispatchQueue = DispatchQueue(label: "inotify.queue", qos: .background,
      attributes: [.initiallyInactive, .concurrent])
    fileDescriptor = FileDescriptor(inotify_init())
    if fileDescriptor < 0 {
      fatalError("Failed to initialize inotify")
    }

    watchDescriptors = [WatchDescriptor]()
  }

  public func start() {
    shouldStopWatching = false
    dispatchQueue.activate()
  }

  public func stop() {
    shouldStopWatching = true
    dispatchQueue.suspend()

    for watchDescriptor in watchDescriptors {
      inotify_rm_watch(Int32(fileDescriptor), Int32(watchDescriptor))
    }
    close(Int32(fileDescriptor))
  }

  public func watch(paths: [String], for events: [FileSystemEventType],
      thenInvoke callback: @escaping (FileSystemEvent) -> Void) -> [WatchDescriptor] {
    var flags: UInt32 = events.count > 0 ? 0 : 1
    for event in events {
      flags |= event.rawValue
    }

    var wds = [WatchDescriptor]() // watch descriptors for the call only

    for path in paths {
      let watchDescriptor = inotify_add_watch(Int32(fileDescriptor), path, flags)
      watchDescriptors.append(WatchDescriptor(watchDescriptor))
      wds.append(WatchDescriptor(watchDescriptor))

      dispatchQueue.async {
        let bufferLength = 32
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength)

        while !self.shouldStopWatching {
          var currentIndex: Int = 0
          let readLength = read(Int32(self.fileDescriptor), buffer, bufferLength)

          while currentIndex < readLength {
            let event = withUnsafePointer(to: &buffer[currentIndex]) {
              return $0.withMemoryRebound(to: inotify_event.self, capacity: 1) {
                return $0.pointee
              }
            }

            if event.len > 0 {
              let fileSystemEvent = FileSystemEvent(
                watchDescriptor: WatchDescriptor(event.wd),
                name: "", // String(cString: event.name), // value of type 'inotify_event' has no member 'name'
                mask: event.mask,
                cookie: event.cookie,
                length: event.len
              )

              self.dispatchQueue.async {
                callback(fileSystemEvent)
              }
            }

            currentIndex += MemoryLayout<inotify_event>.stride + Int(event.len)
          }
        }
      }
    }

    return wds
  }
}
