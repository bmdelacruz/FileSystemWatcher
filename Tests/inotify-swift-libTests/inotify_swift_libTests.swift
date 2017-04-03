import XCTest
@testable import inotify_swift_lib

class inotify_swift_libTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(inotify_swift_lib().text, "Hello, World!")
    }


    static var allTests : [(String, (inotify_swift_libTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
