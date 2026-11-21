import SwiftUI

#if canImport(UIKit)
import UIKit
import PDFKit
#endif

public final class ExportService: @unchecked Sendable {
    public static let shared = ExportService()

    public init() {}

    public func exportMarkdownFile(note: Note) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let safeName = note.title.replacingOccurrences(of: "/", with: "-")
        let fileURL = tempDir.appendingPathComponent("\(safeName).md")
        let content = note.rawMarkdownWithFrontMatter
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    public func exportPlainTextFile(note: Note) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let safeName = note.title.replacingOccurrences(of: "/", with: "-")
        let fileURL = tempDir.appendingPathComponent("\(safeName).txt")
        let plainText = "\(note.title)\n\n\(note.content)"
        do {
            try plainText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    #if canImport(UIKit)
    @MainActor
    public func exportPDF(note: Note) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let safeName = note.title.replacingOccurrences(of: "/", with: "-")
        let fileURL = tempDir.appendingPathComponent("\(safeName).pdf")

        let html = generateExportHTML(note: note)
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        // US Letter size: 612 x 792 pt, with 36 pt margins
        let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let printableRect = paperRect.insetBy(dx: 36, dy: 36)

        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)

        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        do {
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func generateExportHTML(note: Note) -> String {
        let parser = MarkdownParser()
        let doc = parser.parse(note.content)
        var bodyHtml = ""

        for block in doc.blocks {
            switch block {
            case .heading(let level, let inlines, let align):
                let text = inlinesToHTML(inlines)
                bodyHtml += "<h\(level) style=\"text-align:\(align.rawValue);color:#111;\">\(text)</h\(level)>\n"
            case .paragraph(let inlines, let align):
                let text = inlinesToHTML(inlines)
                bodyHtml += "<p style=\"text-align:\(align.rawValue);line-height:1.5;color:#222;\">\(text)</p>\n"
            case .codeBlock(let lang, let code):
                let escaped = escapeHTML(code)
                bodyHtml += "<pre style=\"background:#f4f4f5;border-radius:6px;padding:12px;font-family:monospace;font-size:12px;\"><code class=\"\(lang)\">\(escaped)</code></pre>\n"
            case .blockquote(let children):
                let childDoc = MarkdownDocument(blocks: children)
                let text = inlinesToHTML([.text(MarkdownSerializer().serialize(childDoc))])
                bodyHtml += "<blockquote style=\"border-left:4px solid #FFD60A;margin:0;padding-left:16px;color:#555;\">\(text)</blockquote>\n"
            case .bulletList(let items):
                bodyHtml += "<ul>\n"
                for item in items {
                    bodyHtml += "<li>\(inlinesToHTML(item.inlines))</li>\n"
                }
                bodyHtml += "</ul>\n"
            case .orderedList(let start, let items):
                bodyHtml += "<ol start=\"\(start)\">\n"
                for item in items {
                    bodyHtml += "<li>\(inlinesToHTML(item.inlines))</li>\n"
                }
                bodyHtml += "</ol>\n"
            case .taskList(let items):
                bodyHtml += "<ul style=\"list-style-type:none;padding-left:0;\">\n"
                for item in items {
                    let mark = item.isCompleted ? "☑" : "☐"
                    bodyHtml += "<li>\(mark) \(inlinesToHTML(item.inlines))</li>\n"
                }
                bodyHtml += "</ul>\n"
            case .table(let table):
                bodyHtml += "<table style=\"border-collapse:collapse;width:100%;margin:16px 0;\">\n<thead><tr>"
                for (idx, h) in table.headers.enumerated() {
                    let align = idx < table.alignments.count ? table.alignments[idx].rawValue : "left"
                    bodyHtml += "<th style=\"border:1px solid #ddd;padding:8px;text-align:\(align);background:#fafafa;\">\(escapeHTML(h))</th>"
                }
                bodyHtml += "</tr></thead><tbody>"
                for row in table.rows {
                    bodyHtml += "<tr>"
                    for (idx, cell) in row.enumerated() {
                        let align = idx < table.alignments.count ? table.alignments[idx].rawValue : "left"
                        bodyHtml += "<td style=\"border:1px solid #ddd;padding:8px;text-align:\(align);\">\(escapeHTML(cell))</td>"
                    }
                    bodyHtml += "</tr>"
                }
                bodyHtml += "</tbody></table>\n"
            case .thematicBreak:
                bodyHtml += "<hr style=\"border:none;border-top:1px solid #eee;margin:20px 0;\" />\n"
            case .rawHTML(let raw):
                bodyHtml += raw
            }
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>\(escapeHTML(note.title))</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 24px; color: #111; }
            h1 { margin-top: 0; font-size: 26px; border-bottom: 2px solid #FFD60A; padding-bottom: 8px; }
            .date { color: #888; font-size: 12px; margin-bottom: 24px; }
        </style>
        </head>
        <body>
            <h1>\(escapeHTML(note.title))</h1>
            <div class="date">Last updated: \(note.formattedModifiedDate)</div>
            \(bodyHtml)
        </body>
        </html>
        """
    }

    private func inlinesToHTML(_ inlines: [InlineNode]) -> String {
        return inlines.map { inline in
            switch inline {
            case .text(let s): return escapeHTML(s)
            case .bold(let i): return "<strong>\(inlinesToHTML(i))</strong>"
            case .italic(let i): return "<em>\(inlinesToHTML(i))</em>"
            case .underline(let i): return "<u>\(inlinesToHTML(i))</u>"
            case .strikethrough(let i): return "<del>\(inlinesToHTML(i))</del>"
            case .code(let s): return "<code>\(escapeHTML(s))</code>"
            case .highlight(let hex, let i): return "<mark style=\"background:\(hex);padding:2px 4px;border-radius:3px;\">\(inlinesToHTML(i))</mark>"
            case .textColor(let hex, let i): return "<span style=\"color:\(hex);\">\(inlinesToHTML(i))</span>"
            case .link(let title, let dest): return "<a href=\"\(dest)\">\(escapeHTML(title))</a>"
            case .image(let alt, let url): return "<img src=\"\(url)\" alt=\"\(escapeHTML(alt))\" style=\"max-width:100%;height:auto;border-radius:8px;margin:8px 0;\" />"
            }
        }.joined()
    }

    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    #endif
}
