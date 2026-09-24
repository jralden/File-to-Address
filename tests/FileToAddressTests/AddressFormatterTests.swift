import Testing
@testable import FileToAddress

struct AddressFormatterTests {
    @Test func plainPathIsUnquoted() {
        #expect(AddressFormatter.format(["/Users/me/shot.png"]) == "/Users/me/shot.png")
    }

    @Test func pathWithSpacesIsQuoted() {
        let path = "/Users/me/Desktop/Screenshot 2026-09-24 at 10.15.32\u{202F}AM.png"
        #expect(AddressFormatter.format([path]) == "\"\(path)\"")
    }

    @Test func multiplePathsAreSpaceSeparated() {
        #expect(AddressFormatter.format(["/a.png", "/b c.png"]) == "/a.png \"/b c.png\"")
    }

    @Test func emptySelectionIsEmpty() {
        #expect(AddressFormatter.format([]) == "")
    }
}
