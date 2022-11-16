//
//  SourceList + DragAndDropSupport.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit

// MARK: - Drang & Drop Support
extension SourceList.Adapter {

	public typealias Index = SourceList.Index

	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		guard
			let outlineItem = item as? OutlineItem, let model = snapshot[outlineItem.id]
		else {
			return nil
		}
		let pasterboardItem = NSPasteboardItem()
		let hasData = writeDataIfNeeded(of: model.dragConfiguration, to: pasterboardItem)
		let canReorder = writeIndexesIfNeeded(of: model, to: pasterboardItem)
		guard hasData || canReorder else {
			return nil
		}
		return pasterboardItem
	}

	public func outlineView(_ outlineView: NSOutlineView,
							validateDrop info: NSDraggingInfo,
							proposedItem item: Any?,
							proposedChildIndex index: Int) -> NSDragOperation {
		let destination = getDestination(proposedItem: item, proposedChildIndex: index)
		let source = getDraggingSource(draggingInfo: info)

		// Supports only local reorder
		if source == .local {
			return validateReorder(to: item, destination: destination, info: info)
		}

		return validateDrop(to: item, destination: destination, info: info)
	}

	public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {

		let destination = getDestination(proposedItem: item, proposedChildIndex: index)
		let source = getDraggingSource(draggingInfo: info)

		if source == .local {
			return performReorder(info: info, targetItem: item, destination: destination)
		}

		return performDrop(draggingInfo: info, item: item, childIndex: index)
	}

	public func outlineView(_ outlineView: NSOutlineView,
							draggingSession session: NSDraggingSession,
							endedAt screenPoint: NSPoint,
							operation: NSDragOperation) {
		if
			let pasteboardItems = session.draggingPasteboard.pasteboardItems, operation == .delete {
			let indexes = getIndexes(from: pasteboardItems)
			dropConfiguration?.handleDelete(indexes)
		}
	}
}

// MARK: - Helpers
extension SourceList.Adapter {

	func writeDataIfNeeded(of configuration: DragConfiguration, to pasterboardItem: NSPasteboardItem) -> Bool {
		guard configuration.hasData() else {
			return false
		}
		configuration.enumerateData { type, data in
			pasterboardItem.setData(data, forType: type)
		}
		return true
	}

	func writeIndexesIfNeeded(of model: any RowRepresentable, to pasterboardItem: NSPasteboardItem) -> Bool {
		let configuration = model.dragConfiguration
		guard
			let indexPath = snapshot.indexPath(forIdentifier: model.itemIdentifier), configuration.isDeletable || configuration.isReordable,
			let indexData = try? NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: true)
		else {
			return false
		}
		pasterboardItem.setData(indexData, forType: .indexes)
		return true
	}

	func getIndexes(from pasteboardItems: [NSPasteboardItem]) -> [Index] {
		var result: [Index] = []
		for item in pasteboardItems {
			guard
				let data = item.data(forType: .indexes),
				let indexPath = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexPath.self, from: data) as? IndexPath,
				let identifier = snapshot.identifier(atIndexPath: indexPath)
			else {
				continue
			}
			let index = Index(id: identifier, indexPath: indexPath)
			result.append(index)
		}
		return result
	}

	func getDestination(proposedItem item: Any?, proposedChildIndex offset: Int) -> SourceList.DropDestination {
		let dropOn = (offset == NSOutlineViewDropOnItemIndex)

		guard let outlineItem = item as? OutlineItem else {
			return dropOn
			? .dropOn(index: nil)
			: .dropInto(target: nil, offset: offset)
		}

		let identifier = outlineItem.id
		guard let index = snapshot.index(identifier: identifier) else {
			fatalError("Identifier = \(identifier) does not found in snapshot")
		}

		return dropOn
		? .dropOn(index: index)
		: .dropInto(target: index, offset: offset)
	}

	func getDraggingSource(draggingInfo info: NSDraggingInfo) -> DragInfo.Source {
		if let source = info.draggingSource as? NSOutlineView, source === outlineView {
			return .local
		} else if let _ = info.draggingSource {
			return .internal
		}
		return .external
	}

}

// MARK: - Helpers for reorder
extension SourceList.Adapter {

	func validateReorder(to proposedItem: Any?, destination: SourceList.DropDestination, info: NSDraggingInfo) -> NSDragOperation {
		guard let configuration = dropConfiguration else {
			return []
		}
		let pasterboardItems = info.draggingPasteboard.pasteboardItems ?? []
		let indexes = getIndexes(from: pasterboardItems)
		let canMove = indexes.map(\.indexPath)
			.allSatisfy {
				!destination.indexPath.starts(with: $0)
			}
		return configuration.moveIsAvailable(for: indexes, to: destination) && canMove ? .move : []
	}

	func performReorder(info: NSDraggingInfo, targetItem: Any?, destination: SourceList.DropDestination) -> Bool {
		guard let configuration = dropConfiguration else {
			return false
		}
		let pasterboardItems = info.pasterboardItems
		let indexes = getIndexes(from: pasterboardItems)
		DispatchQueue.main.async {
			configuration.moveAction?.action(indexes, destination)
		}

		return true
	}

}

// MARK: - Helpers for drops
extension SourceList.Adapter {

	func performDrop(draggingInfo: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {

		let draggingSource = getDraggingSource(draggingInfo: draggingInfo)
		let destination = getDestination(proposedItem: item, proposedChildIndex: index)

		DispatchQueue.main.async { [weak self] in
			self?.emumerateData(types: draggingInfo.types,
								pasteboardItems: draggingInfo.pasterboardItems,
								draggingSource: draggingSource) { [weak self] info, data in
				switch destination {
					case .dropOn(let target):
						self?.dropConfiguration?.handleDrop(info: info, to: target, data: data)
					case .dropInto(let target, let offset):
						self?.dropConfiguration?.handleInsert(info: info, to: target, offset: offset, data: data)
				}
			}
		}

		return true
	}

	func validateDrop(to proposedItem: Any?, destination: SourceList.DropDestination, info: NSDraggingInfo) -> NSDragOperation {
		guard let configuration = dropConfiguration else {
			return []
		}

		let source = getDraggingSource(draggingInfo: info)
		let dragInfo = info.types.map { DragInfo(type: $0, source: source) }

		switch destination {
			case .dropOn(let target):
				return configuration.canHandleDrop(info: dragInfo, to: target) ? .copy : []
			case .dropInto(let target, let offset):
				return configuration.canHandleInsert(info: dragInfo, to: target, offset: offset) ? .copy : []
		}
	}

	func emumerateData(types: [NSPasteboard.PasteboardType],
					   pasteboardItems: [NSPasteboardItem],
					   draggingSource source: DragInfo.Source, action: @escaping (DragInfo, [Data]) -> Void) {
		for type in types {
			let data = pasteboardItems.compactMap { $0.data(forType: type) }
			let dragInfo = DragInfo(type: type, source: source)
			action(dragInfo, data)
		}
	}

}
