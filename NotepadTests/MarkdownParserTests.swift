import Testing
import Foundation
@testable import Notepad

@Suite("Markdown Parser & Serializer Tests")
struct MarkdownParserTests {
    let parser = MarkdownParser()
    let serializer = MarkdownSerializer()

    @Test("Headings and Paragraphs parsing & round-trip")
    func testHeadingsAndParagraphs() {
        let input = """
        # Heading 1

        ## Heading 2

        This is a standard paragraph with **bold** and *italic* text.
        """
        let doc = parser.parse(input)
        #expect(doc.blocks.count == 3)

        if case .heading(let level, _, _) = doc.blocks[0] {
            #expect(level == 1)
        } else {
            #expect(Bool(false), "First block should be H1")
        }

        if case .heading(let level, _, _) = doc.blocks[1] {
            #expect(level == 2)
        } else {
            #expect(Bool(false), "Second block should be H2")
        }

        let output = serializer.serialize(doc)
        let roundTripDoc = parser.parse(output)
        #expect(roundTripDoc.blocks.count == 3)
    }

    @Test("Code Block parsing & round-trip")
    func testCodeBlocks() {
        let input = """
        ```swift
        func hello() {
            print("World")
        }
        ```
        """
        let doc = parser.parse(input)
        #expect(doc.blocks.count == 1)

        guard case .codeBlock(let lang, let code) = doc.blocks[0] else {
            #expect(Bool(false), "Expected code block")
            return
        }

        #expect(lang == "swift")
        #expect(code.contains("print(\"World\")"))

        let serialized = serializer.serialize(doc)
        #expect(serialized.contains("```swift"))
        #expect(serialized.contains("print(\"World\")"))
    }

    @Test("GFM Table parsing and alignment")
    func testTables() {
        let input = """
        | Header A | Header B |
        | :--- | :---: |
        | Value 1 | Value 2 |
        | Value 3 | Value 4 |
        """
        let doc = parser.parse(input)
        #expect(doc.blocks.count == 1)

        guard case .table(let table) = doc.blocks[0] else {
            #expect(Bool(false), "Expected table block")
            return
        }

        #expect(table.headers.count == 2)
        #expect(table.headers[0] == "Header A")
        #expect(table.alignments[0] == .left)
        #expect(table.alignments[1] == .center)
        #expect(table.rows.count == 2)
        #expect(table.rows[0][0] == "Value 1")

        let serialized = serializer.serialize(doc)
        #expect(serialized.contains("| Header A | Header B |"))
        #expect(serialized.contains("| :--- | :---: |"))
    }

    @Test("Task lists / Checkboxes parsing")
    func testTaskLists() {
        let input = """
        - [ ] Buy milk
        - [x] Write Swift 6 code
        """
        let doc = parser.parse(input)
        #expect(doc.blocks.count == 1)

        guard case .taskList(let items) = doc.blocks[0] else {
            #expect(Bool(false), "Expected task list")
            return
        }

        #expect(items.count == 2)
        #expect(items[0].isCompleted == false)
        #expect(items[0].inlines.first?.plainText == "Buy milk")
        #expect(items[1].isCompleted == true)
        #expect(items[1].inlines.first?.plainText == "Write Swift 6 code")
    }

    @Test("HTML extensions for alignment, highlight, text color, and underline")
    func testHTMLExtensions() {
        let input = """
        <div align="center">Centered Paragraph</div>

        This has <mark style="background:#FFD60A">highlight</mark>, <span style="color:#FF3B30">red text</span>, and <u>underlined text</u>.
        """
        let doc = parser.parse(input)
        #expect(doc.blocks.count == 2)

        guard case .paragraph(_, let align) = doc.blocks[0] else {
            #expect(Bool(false), "Expected paragraph")
            return
        }
        #expect(align == .center)

        let serialized = serializer.serialize(doc)
        #expect(serialized.contains("<div align=\"center\">"))
        #expect(serialized.contains("<mark style=\"background:#FFD60A\">"))
        #expect(serialized.contains("<span style=\"color:#FF3B30\">"))
        #expect(serialized.contains("<u>underlined text</u>"))
    }
}
