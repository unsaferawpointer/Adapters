//
//  ListViewAdapter.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 16.10.2021.
//

import AppKit

/// Adapter for single - column NSTableView
public final class ListViewAdapter<ViewModel: ListItemRepresentable>: NSObject,
																	  NSTableViewDataSource,
																	  NSTableViewDelegate  {

	private let NSTableViewDropToRootIndex = -1

	public typealias ID = 	ViewModel.ID
	public typealias Cell = ViewModel.Cell

	// MARK: Private properties

	private (set) var tableView: NSTableView
	private (set) var data: [ViewModel] = []

	// State
	private var isEditing = false

	// Cache
	private (set) var cache: [ID: Int] = [:]

	// MARK: Public properties

	/// Allow to reoder table items
	public var allowReorder: Bool = false

	public var selectedIdentifiers: [ID] = [] {
		didSet {
			let indexes = selectedIdentifiers.compactMap { cache[$0] }
			tableView.selectRowIndexes(IndexSet(indexes), byExtendingSelection: false)
		}
	}

	public var rowHeight: CGFloat? = 42.0

	// MARK: Providers

	public var availablePasterboardTypes: [NSPasteboard.PasteboardType]

	public var dropConfiguration: DropConfiguration<ID>?

	public var dataProvider: ((ViewModel) -> Void)?

	public var selectionProvider: (([ID]) -> Void)?
	public var itemsDidReordered: ((IndexSet, Int) -> Void)?
	public var itemsDidDuplicated: ((IndexSet, Int) -> Void)?
	public var itemsDidDeleted: ((IndexSet) -> Void)?

	public var commonSelection: [ID] {
		let indexes = tableView.commonSelection
		return indexes.map { data[$0].id }
	}

	/// Initialization
	///
	/// - Parameters
	/// 

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

		guard withAnimation else {
			data = newData
			updateCache()
			tableView.reloadData()
			return
		}

		let oldData = data
		let newDataSet = Set(newData)

		for object in oldData {
			if let index = newDataSet.firstIndex(of: object) {
				let newObject = newDataSet[index]
				if newObject.isContentEqual(to: object) == false {
					guard let oldIndex = cache[object.id] else { return }
					forceUpdateCell(at: oldIndex, with: newObject)
				}
			}
		}

		// Begin updating
		isEditing = true
		tableView.beginUpdates()

		var removed = IndexSet()
		var inserted = IndexSet()

		let diff = newData.difference(from: data)
		for change in diff {
			switch change {
				case .remove(let offset, _, associatedWith: _):
					removed.insert(offset)
				case .insert(let offset, _, associatedWith: _):
					inserted.insert(offset)
			}
		}

		tableView.removeRows(at: removed, withAnimation: [.slideDown, .effectFade])
		tableView.insertRows(at: inserted, withAnimation: [.slideLeft, .effectFade])
		data = newData

		// update cache
		updateCache()

		// End updating
		tableView.endUpdates()
		isEditing = false

		let rows = selectedIdentifiers.compactMap { cache[$0] }
		let indexSet = IndexSet(rows)

		tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
	}

	private func updateCache() {
		cache.removeAll()
		for (offset, model) in data.enumerated() {
			cache[model.id] = offset
		}
	}

	private func forceUpdateCell(at row: Int, with model: ViewModel) {
		if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? Cell {
			configure(cell, for: model)
		}
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
		selectedIdentifiers = selectedRows.map { data[$0].id }
		selectionProvider?(selectedIdentifiers)
	}

	// MARK: NSTableViewDataSource

	public func numberOfRows(in tableView: NSTableView) -> Int {
		return data.count
	}

	// MARK: Drag and Drop support

	public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let pasterboardItem = NSPasteboardItem()
		setData(of: data[row], to: pasterboardItem)
		if allowReorder {
			setData(of: row, to: pasterboardItem, forType: .reorder)
		}
		setData(of: row, to: pasterboardItem, forType: .delete)
		return pasterboardItem
	}

	public func tableView(_ tableView: NSTableView,
						  validateDrop info: NSDraggingInfo,
						  proposedRow row: Int,
						  proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

		tableView.draggingDestinationFeedbackStyle = .regular
		let draggingSource = getDraggingSource(draggingInfo: info)

		if draggingSource == .local && dropOperation == .above {
			// Support forced drag and drop operation
			if info.draggingSourceOperationMask == .copy {
				info.animatesToDestination = true
				return .copy
			}
			guard allowReorder else {
				return []
			}

			info.animatesToDestination = hasMultiplyDraggableItem(draggingInfo: info)
			return .move
		}

		let types = info.draggingPasteboard.types ?? []

		let dropDestination = getDropDestination(row: row, dropOperation: dropOperation)

		guard  dropConfiguration?.canHandleDrop(types, draggingSource, dropDestination) ?? false else {
			return []
		}

		if data.isEmpty {
			tableView.setDropRow(-1, dropOperation: .on)
		}
		return .copy
	}

	public func tableView(_ tableView: NSTableView,
				   acceptDrop info: NSDraggingInfo,
				   row: Int,
				   dropOperation: NSTableView.DropOperation) -> Bool {
		let draggingSource = getDraggingSource(draggingInfo: info)
		if draggingSource == .local {
			// Support forced drag and drop operation
			if info.draggingSourceOperationMask == .copy {
				performInsertCopies(with: info, at: row)
			} else if validateReorder(draggingInfo: info, dropRow: row, operation: dropOperation) {
				tableView.beginUpdates()
				performReoder(with: info, row: row)
				tableView.endUpdates()
			}
		} else {
			// Perform insert from external source
			performInsert(with: info, row: row, dropOperation: dropOperation)
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
			let indexes = indexes(from: pasteboardItems, forType: .delete) {
			performDelete(indexes: indexes)
		}
	}

	public func tableView(_ tableView: NSTableView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
		draggingInfo.draggingFormation = .list
	}

	// MARK: Drag and Drop private functions

	private func setData(of item: ViewModel, to pasterboardItem: NSPasteboardItem) {
		guard let item = item as? DragSupportable else {
			return
		}
		for type in item.availableTypes {
			if let data = item.providedData(for: type) {
				pasterboardItem.setData(data, forType: type)
			}
		}
	}

	private func setData(of row: Int, to pasterboardItem: NSPasteboardItem, forType type: NSPasteboard.PasteboardType) {
		if let indexData = try? NSKeyedArchiver.archivedData(withRootObject: row, requiringSecureCoding: true) {
			pasterboardItem.setData(indexData, forType: type)
		}
	}

	private func performReoder(with draggingInfo: NSDraggingInfo, row: Int) {

		guard let oldIndexes = indexes(from: draggingInfo, forType: .reorder) else { return }

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

		data.move(indexes: oldIndexes, to: row)
		updateCache()
		itemsDidReordered?(oldIndexes, row)
	}

	private func performInsert(with draggingInfo: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) {

		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
		let draggingSource = getDraggingSource(draggingInfo: draggingInfo)

		var dropData: [NSPasteboard.PasteboardType: [Data]] = [:]

		for type in availablePasterboardTypes {
			var result: [Data] = []
			for pasterboardItem in pasteboardItems {
				guard let data = pasterboardItem.data(forType: type) else {
					continue
				}
				result.append(data)
			}
			if result.isEmpty == false {
				dropData[type] = result
			}
		}

		let dropDestination = getDropDestination(row: row, dropOperation: dropOperation)
		dropConfiguration?.dropProvider?(dropDestination, draggingSource, dropData)
	}

	private func performInsertCopies(with draggingInfo: NSDraggingInfo, at row: Int) {
		if
			let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems,
			let indexes = indexes(from: pasteboardItems, forType: .reorder)
		{
			itemsDidDuplicated?(indexes, row)
		}
	}

	private func getDraggingSource(draggingInfo info: NSDraggingInfo) -> DraggingSource {
		if let source = info.draggingSource as? NSTableView, source === tableView {
			return .local
		} else if let _ = info.draggingSource {
			return .internal
		}
		return .external
	}

	private func getDropDestination(row: Int, dropOperation: NSTableView.DropOperation) -> DropConfiguration<ID>.DropDestination {
		guard row != NSTableViewDropToRootIndex else {
			return .dropToRoot
		}
		switch dropOperation {
			case .on: 		return .dropOn(row: row)
			case .above: 	return .dropAbove(row: row)
			@unknown default:
				fatalError("Unknown drop operation")
		}

	}

	private func performDelete(indexes: IndexSet) {
		itemsDidDeleted?(indexes)
	}

	private func hasMultiplyDraggableItem(draggingInfo info: NSDraggingInfo) -> Bool {
		guard let movedIndexSet = indexes(from: info, forType: .reorder) else { return false }
		return movedIndexSet.count > 1
	}

	private func indexes(from draggingInfo: NSDraggingInfo, forType type: NSPasteboard.PasteboardType) -> IndexSet? {
		let pasterboard = draggingInfo.draggingPasteboard
		return indexes(from: pasterboard.pasteboardItems ?? [], forType: type)
	}

	private func indexes(from pasteboardItems: [NSPasteboardItem], forType type: NSPasteboard.PasteboardType) -> IndexSet? {
		var result = IndexSet()
		for item in pasteboardItems {
			guard
				let data = item.data(forType: type),
				let number = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: data)
			else {
				continue
			}
			result.insert(number.intValue)
		}
		return result
	}

	private func validateReorder(draggingInfo info: NSDraggingInfo,
								 dropRow: Int,
								 operation: NSTableView.DropOperation) -> Bool {
		guard let sourceIndexSet = indexes(from: info, forType: .reorder) else { return false }
		// If all rows are selected, they cannot be moved
		return (sourceIndexSet.count < data.count)
	}

	// MARK: NSTableViewDelegate

	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		let model = data[row]

		let interfaceIdentifier = NSUserInterfaceItemIdentifier(model.userIdentifier)

		var cell = tableView.makeView(withIdentifier: interfaceIdentifier, owner: self) as? Cell
		if cell == nil {
			cell = Cell()
			cell?.identifier = interfaceIdentifier
		}
		configure(cell, for: model)
		return cell
	}

	public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return rowHeight ?? tableView.rowHeight
	}

	public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
		return false
	}

	public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let model = data[row]
		return model.isSelectable
	}

	private func configure(_ cell: Cell?, for model: ViewModel) {
		guard let cell = cell else { return }
		cell.viewModel = model
		cell.valueDidChanged = { [weak self] model in
			self?.dataProvider?(model)
		}
	}

}

extension ListViewAdapter {

	public func scrollTo(identifier: ViewModel.ID?, withAnimation: Bool) {
		guard
			let identifier = identifier,
			let row = cache[identifier]
		else {
			return
		}
		if withAnimation {
			NSAnimationContext.runAnimationGroup { context in
				context.allowsImplicitAnimation = true
				tableView.scrollRowToVisible(row)
			}
		} else {
			tableView.scrollRowToVisible(row)
		}
	}

	public func setFocus(_ identifier: ViewModel.ID?) {
		guard
			let identifier = identifier,
			let row = cache[identifier]
		else {
			return
		}
		if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? Focusable {
			cell.onFocus(true)
		}
	}

}

extension NSPasteboard.PasteboardType {
	static var reorder = NSPasteboard.PasteboardType("private.listview.reorder")
	static var delete = NSPasteboard.PasteboardType("private.listview.delete")
}
