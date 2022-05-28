//
//  TableViewAdapter.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 16.10.2021.
//

import AppKit

public final class TableViewAdapter<Cell: CellRepresentable>: NSObject,
													 NSTableViewDataSource,
													 NSTableViewDelegate {

	public typealias ViewModel = Cell.ViewModel
	public typealias ID = Cell.ViewModel.ID

	private (set) var tableView: NSTableView

	private (set) var data: [ViewModel] = []

	public var allowReorder: Bool = true

	private var isEditing = false

	public var selected: [ID] = [] {
		didSet {
			if oldValue != selected {
				let indexes = selected.compactMap { id in
					data.firstIndex {
						$0.id == id
					}
				}
				tableView.selectRowIndexes(IndexSet(indexes), byExtendingSelection: false)
			}
		}
	}

	public var rowHeight: CGFloat = 42.0

	public var dropProvider: (([Any], RelativeLocation<ID>?) -> Void)?
	public var availablePasterboardTypes: [NSPasteboard.PasteboardType]

	public var dataProvider: ((ID, [String: Any]) -> Void)?

	public var selectionAction: (([ID]) -> Void)?
	public var moveAction: (([ID], RelativeLocation<ID>) -> Void)?
	public var duplicateAction: (([ID], RelativeLocation<ID>) -> Void)?
	public var deleteAction: (([ID]) -> Void)?

	public var commonSelection: [ID] {
		let indexes = tableView.commonSelection
		return indexes.map { data[$0].id }
	}

	public init(_ tableView: NSTableView, availablePasterboardTypes types: [NSPasteboard.PasteboardType] = []) {
		self.tableView = tableView
		availablePasterboardTypes = types
		availablePasterboardTypes.append(.reorder)
		tableView.registerForDraggedTypes(availablePasterboardTypes)
		tableView.setDraggingSourceOperationMask([.copy, .delete, .move], forLocal: false)
		super.init()
		tableView.delegate = self
		tableView.dataSource = self
	}

	public func apply(newData: [ViewModel], withAnimation: Bool) {
		let oldData = data

		let newDataSet = Set(newData)

		for object in oldData {
			if let index = newDataSet.firstIndex(of: object) {
				let newObject = newDataSet[index]
				if newObject.isContentEqual(to: object) == false {
					guard let oldIndex = oldData.firstIndex(of: object) else { return }
					if let cell = tableView.view(atColumn: 0, row: oldIndex, makeIfNecessary: false) as? Cell {
						configure(cell, for: newObject)
					}
				}
			}
		}

		isEditing = true
		tableView.beginUpdates()
		let diff = newData.difference(from: data)
		var removed = IndexSet()
		var inserted = IndexSet()
		for change in diff {
			switch change {
				case .remove(let offset, element: _, associatedWith: _):
					removed.insert(offset)
				case .insert(let offset, element: _, associatedWith: _):
					inserted.insert(offset)
			}
		}

		tableView.removeRows(at: removed, withAnimation: [.slideDown, .effectFade])
		tableView.insertRows(at: inserted, withAnimation: [.slideLeft, .effectFade])
		data = newData
		tableView.endUpdates()
		isEditing = false

		let selectedIndexes = IndexSet(
			selected.compactMap { id in
				data.firstIndex { model in
					model.id == id
				}
			}
		)

		tableView.selectRowIndexes(selectedIndexes, byExtendingSelection: false)
	}

	// MARK: Selection support

	public func tableViewSelectionDidChange(_ notification: Notification) {
		guard
			let source = notification.object as? NSTableView, source === tableView,
			isEditing == false
		else {
			return
		}
		let selectedRows = tableView.selectedRowIndexes
		selected = selectedRows.map { data[$0].id }
		selectionAction?(selected)
	}

	// MARK: NSTableViewDataSource

	public func numberOfRows(in tableView: NSTableView) -> Int {
		return data.count
	}

	// MARK: Drag and Drop support

	public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

		let pasterboardItem = NSPasteboardItem()
		if
			let item = data[row] as? PasteboardWriting,
			let pasterboardMap = item.pasterboardMap {
			for (type, data) in pasterboardMap {
				pasterboardItem.setData(data, forType: type)
			}
		}

		if let indexData = try? NSKeyedArchiver.archivedData(withRootObject: row, requiringSecureCoding: true) {
			pasterboardItem.setData(indexData, forType: .reorder)
		}
		return pasterboardItem
	}

	public func tableView(_ tableView: NSTableView,
				   validateDrop info: NSDraggingInfo,
				   proposedRow row: Int,
				   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

		guard dropOperation == .above else { return [] }
		tableView.draggingDestinationFeedbackStyle = .regular
		if isLocalSource(draggingInfo: info) {
			guard allowReorder else { return  [] }
			// Support forced drag and drop operation
			if info.draggingSourceOperationMask == .copy {
				info.animatesToDestination = true
				return .copy
			} else {
				if hasMultiplyDraggableItem(draggingInfo: info) {
					info.animatesToDestination = true
				} else {
					info.animatesToDestination = false
					tableView.draggingDestinationFeedbackStyle = .regular
				}
				return .move
			}
		} else {
			if data.isEmpty {
				tableView.setDropRow(-1, dropOperation: .on)
			}
			return .copy
		}
	}

	public func tableView(_ tableView: NSTableView,
				   acceptDrop info: NSDraggingInfo,
				   row: Int,
				   dropOperation: NSTableView.DropOperation) -> Bool {
		if isLocalSource(draggingInfo: info) {
			if info.draggingSourceOperationMask == .copy {
				performInsertCopies(with: info, at: row)
			} else if validateReorder(draggingInfo: info, dropRow: row, operation: dropOperation) {
				tableView.beginUpdates()
				performReoder(with: info, row: row)
				tableView.endUpdates()
			}
		} else {
			// Perform insert from outside source
			performInsert(with: info, row: row)
		}
		return true
	}

	public func tableView(_ tableView: NSTableView,
				   draggingSession session: NSDraggingSession,
				   endedAt screenPoint: NSPoint,
				   operation: NSDragOperation) {
		if
			operation == .delete,
			let pasteboardItems = session.draggingPasteboard.pasteboardItems,
			let indexes = indexes(from: pasteboardItems) {
			performDelete(indexes: indexes)
		}
	}

	public func tableView(_ tableView: NSTableView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
		draggingInfo.draggingFormation = .list
	}

	// MARK: Drag and Drop private functions

	private func performReoder(with draggingInfo: NSDraggingInfo, row: Int) {

		guard let oldIndexes = indexes(from: draggingInfo) else { return }

		var oldIndexOffset = 0
		var newIndexOffset = 0

		for oldIndex in oldIndexes {
			if oldIndex < row {
				tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
				oldIndexOffset -= 1
			} else {
				tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
				newIndexOffset += 1
			}
		}

		let identifiers = oldIndexes.map { data[$0].id }
		if row > 0 {
			let index = data[row - 1].id
			data.move(indexes: oldIndexes, to: row)
			moveAction?(identifiers, .after(index))
		} else if data.count > 1 {
			let index = data[row].id
			data.move(indexes: oldIndexes, to: row)
			moveAction?(identifiers, .before(index))
		}
	}

	private func performInsert(with draggingInfo: NSDraggingInfo, row: Int) {
		let availableClasses = [NSString.self]
		let pasterboard = draggingInfo.draggingPasteboard
		print(#function)
		guard
			let pasterboardObjects = pasterboard.readObjects(forClasses: availableClasses),
			pasterboardObjects.count > 0
		else {
			return
		}

		let dropOn = (row == -1)
		if dropOn {
			dropProvider?(pasterboardObjects, nil)
		} else {
			if row > 0 {
				let id = data[row - 1].id
				dropProvider?(pasterboardObjects, .after(id))
			} else if data.count > 1 {
				let id = data[row].id
				dropProvider?(pasterboardObjects, .before(id))
			}
		}
	}

	private func performInsertCopies(with draggingInfo: NSDraggingInfo, at row: Int) {
		if
			let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems,
			let indexes = indexes(from: pasteboardItems)
		{
			let identifiers = indexes.map { data[$0].id }
			if row > 0 {
				let after = data[row - 1].id
				duplicateAction?(identifiers, .after(after))
			} else {
				let before = data[row].id
				duplicateAction?(identifiers, .before(before))
			}
		}
	}

	private func performDelete(indexes: IndexSet) {
		let identifiers = indexes.map { data[$0].id }
		deleteAction?(identifiers)
	}

	private func hasMultiplyDraggableItem(draggingInfo info: NSDraggingInfo) -> Bool {
		guard let movedIndexSet = indexes(from: info) else { return false }
		return movedIndexSet.count > 1
	}

	private func indexes(from draggingInfo: NSDraggingInfo) -> IndexSet? {
		let pasterboard = draggingInfo.draggingPasteboard
		return indexes(from: pasterboard.pasteboardItems ?? [])
	}

	private func indexes(from pasteboardItems: [NSPasteboardItem]) -> IndexSet? {
		var result = IndexSet()
		for item in pasteboardItems {
			guard
				let data = item.data(forType: .reorder),
				let number = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: data)
			else {
				continue
			}
			result.insert(number.intValue)
		}
		return result
	}

	// swiftlint:disable vertical_parameter_alignment
	private func validateReorder(draggingInfo info: NSDraggingInfo,
								 dropRow: Int,
								 operation: NSTableView.DropOperation) -> Bool {
		guard let sourceIndexSet = indexes(from: info) else { return false }
		// If all rows are selected, they cannot be moved
		return (sourceIndexSet.count < data.count)
	}

	private func isLocalSource(draggingInfo info: NSDraggingInfo) -> Bool {
		if let source = info.draggingSource as? NSTableView, source === tableView {
			return true
		}
		return false
	}

	// MARK: NSTableViewDelegate

	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		let model = data[row]

		let interfaceIdentifier = NSUserInterfaceItemIdentifier("cell")

		var cell = tableView.makeView(withIdentifier: interfaceIdentifier, owner: self) as? Cell
		if cell == nil {
			cell = Cell()
			cell?.identifier = interfaceIdentifier
		}
		configure(cell, for: model)
		return cell
	}

	public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return rowHeight
	}

	public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let model = data[row]
		return model.isSelectable
	}

	private func configure(_ cell: Cell?, for model: ViewModel) {
		guard let cell = cell else { return }
		cell.model = model
		cell.valueDidChanged = { [weak self] id, changes in
			self?.dataProvider?(id, changes)
		}
	}

}

extension TableViewAdapter {

	public func scrollTo(identifier: ViewModel.ID?) {
		guard let id = identifier else { return }
		let index = data.firstIndex { $0.id == id }
		guard let index = index else { return }
		tableView.scrollRowToVisible(index)
	}

	public func setFocus(_ identifier: ViewModel.ID?) {
		guard let id = identifier else { return }
		let index = data.firstIndex { $0.id == id }
		guard let index = index else { return }
		if let cell = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? Cell {
			cell.setFocus()
		}
	}

}

extension NSPasteboard.PasteboardType {
	static var reorder = NSPasteboard.PasteboardType("private.table.reorder")
}
