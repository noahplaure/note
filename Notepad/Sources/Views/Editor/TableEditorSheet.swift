import SwiftUI

public struct TableEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var table: TableModel
    public var onSave: (TableModel) -> Void

    public init(initialTable: TableModel? = nil, onSave: @escaping (TableModel) -> Void) {
        if let initial = initialTable, !initial.headers.isEmpty {
            self._table = State(initialValue: initial)
        } else {
            let defaultTable = TableModel(
                headers: ["Item", "Category", "Status"],
                alignments: [.left, .left, .center],
                rows: [
                    ["Project Alpha", "Dev", "In Progress"],
                    ["Design System", "UI", "Done"],
                    ["Database FTS5", "Backend", "Review"]
                ]
            )
            self._table = State(initialValue: defaultTable)
        }
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Toolbar controls: Add/remove row, col
                    HStack(spacing: 12) {
                        Button {
                            addColumn()
                        } label: {
                            Label("Add Column", systemImage: "tablecells.badge.ellipsis")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(hex: "#FFD60A"))

                        Button {
                            addRow()
                        } label: {
                            Label("Add Row", systemImage: "plus.rectangle.on.rectangle")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(hex: "#FFD60A"))

                        Spacer()

                        if table.rowCount > 1 {
                            Button(role: .destructive) {
                                removeLastRow()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Scrollable table grid
                    ScrollView([.horizontal, .vertical]) {
                        VStack(spacing: 2) {
                            // Header Row
                            HStack(spacing: 2) {
                                ForEach(0..<table.headers.count, id: \.self) { colIdx in
                                    VStack(spacing: 4) {
                                        TextField("Header", text: $table.headers[colIdx])
                                            .font(.system(size: 14, weight: .bold))
                                            .multilineTextAlignment(table.alignments[colIdx] == .center ? .center : (table.alignments[colIdx] == .right ? .trailing : .leading))
                                            .padding(8)
                                            .background(Color(hex: "#2C2C2E"))
                                            .cornerRadius(6)

                                        // Column alignment toggle
                                        Menu {
                                            Button("Align Left") { table.alignments[colIdx] = .left }
                                            Button("Align Center") { table.alignments[colIdx] = .center }
                                            Button("Align Right") { table.alignments[colIdx] = .right }
                                        } label: {
                                            Image(systemName: alignmentIcon(for: table.alignments[colIdx]))
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "#FFD60A"))
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .frame(minWidth: 120)
                                }
                            }

                            // Data Rows
                            ForEach(0..<table.rows.count, id: \.self) { rowIdx in
                                HStack(spacing: 2) {
                                    ForEach(0..<table.headers.count, id: \.self) { colIdx in
                                        let binding = Binding<String>(
                                            get: {
                                                colIdx < table.rows[rowIdx].count ? table.rows[rowIdx][colIdx] : ""
                                            },
                                            set: { newVal in
                                                while table.rows[rowIdx].count <= colIdx {
                                                    table.rows[rowIdx].append("")
                                                }
                                                table.rows[rowIdx][colIdx] = newVal
                                            }
                                        )

                                        TextField("Cell", text: binding)
                                            .font(.system(size: 14))
                                            .multilineTextAlignment(table.alignments[colIdx] == .center ? .center : (table.alignments[colIdx] == .right ? .trailing : .leading))
                                            .padding(8)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(6)
                                            .frame(minWidth: 120)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Table Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        onSave(table)
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#FFD60A"))
                    .bold()
                }
            }
        }
    }

    private func addColumn() {
        let newColIndex = table.headers.count + 1
        table.headers.append("Col \(newColIndex)")
        table.alignments.append(.left)
        for r in 0..<table.rows.count {
            table.rows[r].append("")
        }
        HapticManager.impact(.light)
    }

    private func addRow() {
        let newRow = Array(repeating: "", count: table.headers.count)
        table.rows.append(newRow)
        HapticManager.impact(.light)
    }

    private func removeLastRow() {
        guard !table.rows.isEmpty else { return }
        table.rows.removeLast()
        HapticManager.impact(.medium)
    }

    private func alignmentIcon(for align: ColumnAlignment) -> String {
        switch align {
        case .left, .none: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        }
    }
}
