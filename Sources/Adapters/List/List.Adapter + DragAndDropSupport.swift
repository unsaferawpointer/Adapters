//
//  List + DragAndDropSupport.swift
//  
//
//  Created by Anton Cherkasov on 24.08.2022.
//

import AppKit
import UniformTypeIdentifiers

extension List.Adapter {

	// MARK: Drag and Drop support

	public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let model = snapshot[row]
		let pasterboardItem = NSPasteboardItem()
		let hasData = writeDataIfNeeded(of: model.dragConfiguration, to: pasterboardItem)
		let hasIndexes = writeIndexIfNeeded(of: model, to: pasterboardItem)
		return hasData || hasIndexes ? pasterboardItem : nil
	}

	public func tableView(_ tableView: NSTableView,
						  validateDrop info: NSDraggingInfo,
						  proposedRow row: Int,
						  proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

		let source = getSource(draggingInfo: info)

		// Local reorder or forced copying
		if source == .local && dropOperation == .above, let movingRows = getIndexes(from: info), movingRows.isEmpty == false {
			switch info.draggingSourceOperationMask {
				case .copy:
					// Support forced drag and drop operation
					let allSatisfy = movingRows.map { snapshot[$0]
						.dragConfiguration }
						.allSatisfy{ $0.isCopyable }
					return dropConfiguration.canHandleCopy() && allSatisfy ? .copy : []
				default:
					let allSatisfy = movingRows.map { snapshot[$0]
						.dragConfiguration }
						.allSatisfy{ $0.isReordable }
					return dropConfiguration.validateMoving(movingRows, destination: row) && allSatisfy ? .move : []
			}
		}

		if snapshot.isEmpty {
			redirectDropToRoot()
		}

		let info = info.types.map { DragInfo(type: $0, source: source) }
		let dropDestination = getDropDestination(row: row, dropOperation: dropOperation)
		switch dropDestination {
			case .onRow(let index):
				return dropConfiguration.canHandleDropInto(info: info, destination: index) ? .copy : []
			case .aboveRow(let index):
				return dropConfiguration.canHandleInsert(info: info, destination: index) ? .copy : []
			case .on:
				return dropConfiguration.canHandleDropOn(info: info) ? .copy : []
		}
	}

	public func tableView(_ tableView: NSTableView,
						  acceptDrop info: NSDraggingInfo,
						  row: Int,
						  dropOperation: NSTableView.DropOperation) -> Bool {
		if getSource(draggingInfo: info) == .local {
			// Support forced drag and drop operation
			if info.draggingSourceOperationMask == .copy && dropConfiguration.canHandleCopy() {
				performInsertCopies(with: info, to: row)
			} else if validateReorder(draggingInfo: info, dropRow: row, operation: dropOperation) {
				performReoder(with: info, row: row)
			}
		} else {
			// Perform insert from external source
			return performInsert(with: info, row: row, dropOperation: dropOperation)
		}
		return true
	}

	public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession,
						  willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {

		session.draggingFormation = .stack
		let pasteboardItems = session.draggingPasteboard.pasteboardItems ?? []
		let movedRows = getIndexes(from: pasteboardItems)
		let isSingleMoving = movedRows.count == 1
		tableView.draggingDestinationFeedbackStyle = isSingleMoving ? .gap : .regular
		session.enumerateDraggingItems(for: tableView, classes: [NSPasteboardItem.self]) { draggingItem, row, stop in
			guard let preview = snapshot[row].dragConfiguration.dragPreview else {
				return
			}
			draggingItem.imageComponentsProvider = {
				let component = NSDraggingImageComponent(key: .icon)
				component.contents = preview
				component.frame = CGRect(origin: .zero, size: preview.size)
				return [component]
			}
		}
	}

	public func tableView(_ tableView: NSTableView,
						  draggingSession session: NSDraggingSession,
						  endedAt screenPoint: NSPoint,
						  operation: NSDragOperation) {
		tableView.draggingDestinationFeedbackStyle = .regular
		if
			let pasteboardItems = session.draggingPasteboard.pasteboardItems, operation == .delete {
			let indexes = getIndexes(from: pasteboardItems)
			dropConfiguration.handleDelete(indexes)
		}
	}
	
}

// MARK: - Helpers
private extension List.Adapter {

	func redirectDropToRoot() {
		tableView.setDropRow(-1, dropOperation: .on)
	}

	func writeDataIfNeeded(of configuration: DragConfiguration, to pasterboardItem: NSPasteboardItem) -> Bool {
		guard configuration.hasData() else {
			return false
		}
		configuration.enumerateData { type, data in
			pasterboardItem.setData(data, forType: type)
		}
		return true
	}

	func writeIndexIfNeeded(of model: any ListItem, to pasterboardItem: NSPasteboardItem) -> Bool {
		let configuration = model.dragConfiguration
		guard let index = snapshot.getIndex(for: model.itemIdentifier) else {
			fatalError("Cant find index for item identifier = \(model.itemIdentifier)")
		}
		guard
			configuration.isDeletable || configuration.isReordable || configuration.isCopyable,
			let indexData = try? NSKeyedArchiver.archivedData(withRootObject: NSNumber(value: index), requiringSecureCoding: true)
		else {
			return false
		}
		pasterboardItem.setData(indexData, forType: .indexes)
		return true
	}

	/// Detemine dragging source
	func getSource(draggingInfo info: NSDraggingInfo) -> DragInfo.Source {
		if let source = info.draggingSource as? NSTableView, source === tableView {
			return .local
		}
		return info.draggingSource == nil ? .external : .internal
	}

	func getIndexes(from pasteboardItems: [NSPasteboardItem]) -> IndexSet {
		var result = IndexSet()
		for item in pasteboardItems {
			guard
				let data = item.data(forType: .indexes),
				let number = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: data)
			else {
				continue
			}
			result.insert(number.intValue)
		}
		return result
	}

	func getIndexes(from draggingInfo: NSDraggingInfo) -> IndexSet? {
		guard let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems else {
			return nil
		}
		return getIndexes(from: pasteboardItems)
	}

	func isMultiplyMoving(from draggingInfo: NSDraggingInfo) -> Bool {
		guard let movingRows = getIndexes(from: draggingInfo) else {
			return false
		}
		return movingRows.count > 1
	}

	func performInsert(with draggingInfo: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {

		let draggingSource = getSource(draggingInfo: draggingInfo)
		let dropDestination = getDropDestination(row: row, dropOperation: dropOperation)

		DispatchQueue.main.async { [weak self] in
			self?.emumerateData(types: draggingInfo.types,
						  pasteboardItems: draggingInfo.pasterboardItems,
						  draggingSource: draggingSource) { [weak self] info, data in
				switch dropDestination {
					case .onRow(let index): self?.dropConfiguration.handleDropInto(info: info, destination: index, data: data)
					case .aboveRow(let index): self?.dropConfiguration.handleInsert(info: info, destination: index, data: data)
					case .on: self?.dropConfiguration.handleDropOn(info: info, data: data)
				}
			}
		}

		return true
	}

	func emumerateData(types: [NSPasteboard.PasteboardType],
					   pasteboardItems: [NSPasteboardItem],
					   draggingSource source: DragInfo.Source, action: @escaping (DragInfo, [Data]) -> Void) {
		DispatchQueue.main.async {
			for type in types {
				let data = pasteboardItems.compactMap { $0.data(forType: type) }
				let dragInfo = DragInfo(type: type, source: source)
				action(dragInfo, data)
			}
		}
	}

	func performInsertCopies(with draggingInfo: NSDraggingInfo, to destination: Int) {
		if let indexes = getIndexes(from: draggingInfo) {
			dropConfiguration.handleCopy(indexes, destination: destination)
		}
	}

	func getDropDestination(row: Int, dropOperation: NSTableView.DropOperation) -> List.Adapter.DropDestination {
		guard row != NSTableViewDropToRootIndex else {
			return .on
		}
		switch dropOperation {
			case .on:		return .onRow(atIndex: row)
			case .above: 	return .aboveRow(atIndex: row)
			@unknown default:
				fatalError("Unknown drop operation")
		}

	}

	func performReoder(with draggingInfo: NSDraggingInfo, row: Int) {
		tableView.beginUpdates()
		guard let oldIndexes = getIndexes(from: draggingInfo) else { return }

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

		snapshot.move(indexes: oldIndexes, to: row)
		tableView.endUpdates()
		dropConfiguration.handleMoving(oldIndexes, destination: row)
	}

	func validateReorder(draggingInfo info: NSDraggingInfo,
								 dropRow: Int,
								 operation: NSTableView.DropOperation) -> Bool {
		guard let movedRows = getIndexes(from: info) else { return false }
		// If all rows are selected, it cannot be moved
		return (movedRows.count < snapshot.count)
	}

}

extension List.Adapter {

	enum DropDestination {
		case onRow(atIndex: Int)
		case aboveRow(atIndex: Int)
		case on
	}
}
