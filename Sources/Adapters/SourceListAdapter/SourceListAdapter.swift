//
//  SourceListAdapter.swift
//  Adapters
//
//  Created by Anton Cherkasov on 01.01.2022.
//

import AppKit

final public class SourceListAdapter<GroupModel: SourceListGroupRepresentable, ItemModel: SourceListItemRepresentable>: NSObject,
																		   NSOutlineViewDataSource,
																		   NSOutlineViewDelegate {

	class OutlineItem: NSObject {
		var id: AnyHashable
		var model: Any
		init(id: AnyHashable, model: Any) {
			self.id = id
			self.model = model
		}
	}

	let NSOutlineViewNoSelectionIndex: Int = -1

	// MARK: Providers

	public var onDropProvider: 		((ItemModel.ID, [NSPasteboard.PasteboardType: [Any]]) -> Void)?
	public var deleteProvider: 		((ItemModel.ID) -> Void)?
	public var reorderProvider: 	((ItemModel.ID, ReorderOperation) -> Void)?
	public var selectionProvider:	(([ItemModel.ID]) -> Void)?
	public var valueDidChanged:		((ItemModel) -> Void)?

	public enum ReorderOperation {
		case toLocation(location: RelativeLocation<ItemModel.ID>)
		case toRoot
	}

	private (set) var outlineView: NSOutlineView

	// MARK: Snapshot

	var oldRootIdentifiers: [GroupModel.ID] = [] // Generate every time
	var oldNodes: [Node] = [] // Generate every time
	var oldNodesForIdentifiers: [AnyHashable: Node] = [:] // Generate every time

	// Reference - type storage
	var items: [AnyHashable: OutlineItem] = [:]

	// MARK: Temporary states

	var itemBeingDragged: OutlineItem?

	private var isEditing: Bool = false

	public var selectedItem: ItemModel.ID? {
		didSet {
			guard isEditing == false else { return }
			selectItem(selectedItem)
		}
	}

	private func selectItem(_ identifier: ItemModel.ID?) {
		guard let identifier = identifier else {
			outlineView.selectRowIndexes(.init(), byExtendingSelection: false)
			return
		}

		guard let item = items[identifier] else {
			return
		}

		let row = outlineView.row(forItem: item)
		let indexes = IndexSet(integer: row)
		outlineView.selectRowIndexes(indexes, byExtendingSelection: false)

	}

	public var clickedItem: ItemModel.ID? {

		let clickedRow = outlineView.clickedRow
		guard clickedRow != NSOutlineViewNoSelectionIndex else {
			return nil
		}
		guard
			let item = outlineView.item(atRow: clickedRow) as? OutlineItem,
			let model = item.model as? ItemModel
		else {
			return nil
		}
		return model.id
	}

	// MARK: Initialization

	public init(outlineView: NSOutlineView) {
		self.outlineView = outlineView
		super.init()
		configureOutlineView()
	}

	private func configureOutlineView() {
		outlineView.delegate = self
		outlineView.dataSource = self
		outlineView.stronglyReferencesItems = false
		outlineView.setDraggingSourceOperationMask([.move, .delete], forLocal: false)
	}

	// MARK: Apply data

	/// Apply new data
	/// - Parameters:
	///    - groups: Groups of the items
	public func apply(groups: [TreeGroup<GroupModel, ItemModel>]) {

		var newRootIdentifiers: [GroupModel.ID] = [] // Generate every time
		var newNodes: [Node] = [] // Generate every time
		var newNodesForIdentifiers: [AnyHashable: Node] = [:]

		for (offset, group) in groups.enumerated() {
			newRootIdentifiers.append(group.viewModel.id)
			let indexPath = IndexPath(index: offset)
			let groupNode = Node(id: group.viewModel.id,
								 indexPath: indexPath,
								 chidlrenIDs: group.children.map(\.viewModel.id),
								 model: group.viewModel)
			newNodes.append(groupNode)
			newNodesForIdentifiers[group.viewModel.id] = groupNode
			for (offset, item) in group.children.enumerated() {
				let itemNode = Node(id: item.viewModel.id,
									indexPath: indexPath.appending(offset),
									parentID: group.viewModel.id,
									chidlrenIDs: [],
									model: item.viewModel)
				newNodes.append(itemNode)
				newNodesForIdentifiers[item.viewModel.id] = itemNode
			}
		}

		for newNode in newNodes {
			guard let oldNode = oldNodesForIdentifiers[newNode.id],
				  let oldModel = oldNode.model as? ItemModel,
				  let newModel = newNode.model as? ItemModel else {
				continue
			}

			if
				!oldModel.isContentEqual(to: newModel),
				let item = items[oldNode.id]
			{
				let row = outlineView.row(forItem: item)
				if let cell = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemModel.Cell {
					cell.viewModel = newModel
				}

			}
		}

		oldRootIdentifiers = newRootIdentifiers

		oldNodesForIdentifiers = newNodesForIdentifiers

		let difference = newNodes.difference(from: oldNodes).inferringMoves()
		oldNodes = newNodes

		outlineView.beginUpdates()

		for change in difference {
			switch change {
				case .remove( _, let element, let newOffset):
					if newOffset == nil {
						items[element.id] = nil
					}
					let parent = getParent(of: element)
					if let index = element.indexPath.last {
						outlineView.removeItems(at: .init(integer: index), inParent: parent, withAnimation: [.effectFade, .slideDown])
					}

				case .insert( _, let element, let oldOffset):
					if oldOffset == nil {
						let item = OutlineItem(id: element.id, model: element.model)
						items[element.id] = item
						print("item = \(item)")
					}
					let parent = getParent(of: element)
					if let index = element.indexPath.last {
						outlineView.insertItems(at: .init(integer: index), inParent: parent, withAnimation: [.effectFade, .slideUp])
					}
			}
		}

		outlineView.endUpdates()

	}

	private func getParent(of node: Node) -> OutlineItem? {
		guard let id = node.parentID else {
			return nil
		}
		return items[id]
	}

	// MARK: Notifications

	public func outlineViewSelectionDidChange(_ notification: Notification) {
		guard let object = notification.object as? NSOutlineView, object === outlineView else {
			return
		}

		let selectedRows = outlineView.selectedRowIndexes

		let selectedModels = selectedRows.compactMap { row in
			(outlineView.item(atRow: row) as? OutlineItem)?.model as? ItemModel
		}

		let identifiers = selectedModels.map(\.id)

		selectionProvider?(identifiers)

	}

	// MARK: NSOutlineViewDataSource

	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
			let id = groupModel.id
			return oldNodesForIdentifiers[id]?.chidlrenIDs.count ?? 0
		}

		return oldRootIdentifiers.count
	}

	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
			let id = groupModel.id
			guard let childID = oldNodesForIdentifiers[id]?.chidlrenIDs[index] else {
				fatalError("Cant find node with id = \(id)")
			}
			return items[childID]
		}
		let rootID = oldRootIdentifiers[index]
		return items[rootID]
	}

	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
			let id = groupModel.id
			guard let groupNode = oldNodesForIdentifiers[id] else {
				fatalError("Cant find node with id = \(id)")
			}
			return groupNode.chidlrenIDs.count > 0
		}
		return false
	}

	// MARK: NSOutlineViewDelegate

//	private func getItemModel(from item: Any) -> ItemModel? {
//
//	}
//
//	private func getGroupModel(from item: Any) -> GroupModel? {
//
//	}

	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		guard let item = item as? OutlineItem else {
			return nil
		}
		switch item.model {
			case let model as GroupModel: return configureCell(viewModel: model)
			case let model as ItemModel: return configureCell(viewModel: model)
			default: return nil
		}
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		if let item = item as? OutlineItem, let itemModel = item.model as? ItemModel {
			return itemModel.isSelectable
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		return outlineView.rowHeight
	}

	public func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
		guard
			let item = item as? OutlineItem, let itemModel = item.model as? ItemModel,
			let model = itemModel as? Colorable
		else {
			return .monochrome
		}
		return .init(preferredColor: model.tintColor ?? .controlAccentColor)
	}

	public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		if let item = item as? OutlineItem, let _ = item.model as? GroupModel {
			return true
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
			return groupModel.alwaysExpanded == false
		}
		return true
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
			return groupModel.alwaysExpanded == false
		}
		return true
	}

	// MARK: Configure cells

	private func configureCell<T: ListItemRepresentable>(viewModel: T) -> T.Cell? {
		let id = NSUserInterfaceItemIdentifier(viewModel.userIdentifier)
		var cell = outlineView.makeView(withIdentifier: id, owner: self) as? T.Cell
		if cell == nil {
			cell = T.Cell()
			cell?.identifier = id
		}
		cell?.viewModel = viewModel
		cell?.valueDidChanged = { [weak self] model in
			guard let model = model as? ItemModel else {
				return
			}
			self?.valueDidChanged?(model)
		}
		return cell
	}

	// MARK: Drag And Drop Support
//
//	/// - Warning: Support only drop on item
//	public func outlineView(_ outlineView: NSOutlineView,
//							validateDrop info: NSDraggingInfo,
//							proposedItem item: Any?,
//							proposedChildIndex index: Int) -> NSDragOperation {
//
//		let dropOn = (index == NSOutlineViewDropOnItemIndex)
//		let dropOperation: DropOperation = dropOn ? .dropOn : .dropAbove
//		let draggingSource = getDraggingSource(draggingInfo: info)
//
//		// Validate drop from local source
//		if draggingSource == .local {
//			return validateReorder(to: item, dropOperation: dropOperation) ? .move : []
//		}
//
//		// Validate drop from internal or external source
//		return validateDrop(from: draggingSource, info: info, proposedItem: item, dropOperation: dropOperation)
//
//	}
//
//	/// Supports dragging nodes only, excluding groups
//	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
//
//		guard let item = item as? OutlineItem, let model = item.model as? ItemModel else { return nil }
//		let pasterboardItem = NSPasteboardItem()
//		if let model = model as? DragSupportable {
//			for type in model.availableTypes {
//				if let data = model.providedData(for: type) {
//					pasterboardItem.setData(data, forType: type)
//				}
//			}
//		}
//		pasterboardItem.setData(Data(), forType: .reorder)
//		return pasterboardItem
//	}
//
//	/// Supports reordering nodes only, excluding groups
//	public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession,
//							willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
//		if
//			let item = draggedItems.last as? OutlineItem, let itemModel = item.model as? ItemModel,
//			let model = itemModel as? Reorderable,
//			draggedItems.count == 1, model.isReorderable {
//			itemBeingDragged = item
//		}
//	}
//
//	public func outlineView(_ outlineView: NSOutlineView,
//					 draggingSession session: NSDraggingSession,
//					 endedAt screenPoint: NSPoint,
//					 operation: NSDragOperation) {
//		if operation == .delete {
//			performDelete(draggedItem: itemBeingDragged)
//		}
//		itemBeingDragged = nil
//	}
//
//	public func outlineView(_ outlineView: NSOutlineView,
//							acceptDrop info: NSDraggingInfo,
//							item: Any?,
//							childIndex index: Int) -> Bool {
//
//		let draggingSource = getDraggingSource(draggingInfo: info)
//		let dropOn = (index == NSOutlineViewDropOnItemIndex)
//		let dropOperation: DropOperation = dropOn ? .dropOn : .dropAbove
//
//		if draggingSource == .local {
//			return performReoder(destinationItem: item, at: index)
//		}
//
//		return performDrop(from: draggingSource, info: info, destination: item, dropOperation: dropOperation)
//	}
//
//	// Support reorder
//
//	private func validateReorder(to item: Any?, dropOperation: DropOperation) -> Bool {
//
//		guard
//			let dragged = itemBeingDragged, let sourceGroup = findGroup(of: dragged),
//			let targetGroup = item as? OutlineItem else {
//			return false
//		}
//
//		let isSameGroup = (sourceGroup === targetGroup)
//
//		return isSameGroup
//	}
//
//	private func performReoder(destinationItem destination: Any?, at index: Int) -> Bool {
//
//		guard let draggedItem = itemBeingDragged else { return false }
//
//		if let item = destination as? OutlineItem, let groupModel = item.model as? GroupModel {
//			return performReorder(of: draggedItem, destination: groupModel, index: index)
//		}
//
//		assertionFailure("Operation cannot be performed, because it is leaf")
//		return true
//	}
//
//	private func performReorder(of node: NodeProxy<ItemModel>,
//								destination group: GroupProxy<GroupModel, ItemModel>,
//								index: Int) -> Bool {
//
//		let identifier = node.model.id
//
//		return dropTo(group: group, at: index) { location in
//			guard let location = location else {
//				let dropOperation: ReorderOperation = .toRoot
//				reorderProvider?(identifier, dropOperation)
//				return true
//			}
//			let dropOperation: ReorderOperation = .toLocation(location: location)
//			reorderProvider?(identifier, dropOperation)
//			return true
//		}
//	}
//
//	// Support drag and drop from external source
//
//	private func validateDrop(from source: DraggingSource,
//							  info: NSDraggingInfo,
//							  proposedItem item: Any?,
//							  dropOperation: DropOperation) -> NSDragOperation {
//
//		guard
//			let node = item as? NodeProxy<ItemModel>, dropOperation == .dropOn,
//			let model = node.model as? DropSupportable,
//			let pasteboardItems = info.draggingPasteboard.pasteboardItems
//		else {
//			return []
//		}
//
//		let flattenTypes = pasteboardItems.flatMap { $0.types }
//		for type in flattenTypes {
//			let dragOperation = model.canHandle(operation: dropOperation, from: source, with: type)
//			if dragOperation != [] {
//				return dragOperation
//			}
//		}
//
//		return []
//	}
//
//
//	private func performDrop(from source: DraggingSource, info: NSDraggingInfo,
//							 destination: Any?, dropOperation: DropOperation) -> Bool {
//
//		guard
//			let node = destination as? NodeProxy<ItemModel>,
//			let model = node.model as? DropSupportable,
//			case .dropOn = dropOperation
//		else {
//			return false
//		}
//
//		var dictionary: [NSPasteboard.PasteboardType: [Any]] = [:]
//		for pasterboardItem in info.draggingPasteboard.pasteboardItems ?? [] {
//			let types = pasterboardItem.types.filter{
//				model.canHandle(operation: dropOperation, from: source, with: $0) != []
//			}
//			types.forEach { type in
//				if let data = pasterboardItem.data(forType: type) {
//					dictionary[type, default: []].append(data)
//				}
//			}
//		}
//		onDropProvider?(node.model.id, dictionary)
//		return true
//	}
//
//	private func dropTo(group: GroupModel, at index: Int, block: (RelativeLocation<ItemModel.ID>?) -> Bool) -> Bool {
//
//		let dropOn = (index == NSOutlineViewDropOnItemIndex)
//
//		if dropOn {
//			return block(nil)
//		}
//
//		if index > 0 {
//			let id = group.children[index - 1].model.id
//			return block(.after(id))
//		} else if data.count > 1 {
//			let id = group.children[index].model.id
//			return block(.before(id))
//		}
//
//		return false
//	}
//
//
//	private func performDelete(draggedItem: NodeProxy<ItemModel>?) {
//		if let id = itemBeingDragged?.model.id {
//			deleteProvider?(id)
//		}
//	}
//
//	private func getDraggingSource(draggingInfo info: NSDraggingInfo) -> DraggingSource {
//		if let source = info.draggingSource as? NSOutlineView, source === outlineView {
//			return .local
//		} else if let _ = info.draggingSource {
//			return .internal
//		}
//		return .external
//	}
//
//	private func findGroup(of node: NodeProxy<ItemModel>) -> GroupProxy<GroupModel, ItemModel>? {
//		var parent: Any? = node
//		while parent != nil {
//			parent = outlineView.parent(forItem: parent)
//			if let group = parent as? GroupProxy<GroupModel, ItemModel> {
//				return group
//			}
//		}
//		return nil
//	}

}

extension SourceListAdapter {

	public func setFocus(_ identifier: ItemModel.ID?) {
		print("count item = \(items.count)")
		guard
			let identifier = identifier,
			let item = items[identifier],
			item.model is ItemModel
		else {
			return
		}

		let row = outlineView.row(forItem: item)
		if let cell = outlineView.view(atColumn: 0, row: row, makeIfNecessary: true) as? Focusable {
			cell.onFocus(true)
		}
	}

}

extension SourceListAdapter {

	struct Group: Hashable {
		var id: GroupModel.ID
		var children: [ItemModel.ID]
	}

	struct Item: Hashable {
		var id: ItemModel.ID
		var indexPath: IndexPath
		var parent: GroupModel.ID
	}

}

extension SourceListAdapter {

	struct Node: Hashable, CustomStringConvertible {

		// MARK: - Hashable

		static func == (lhs: Node, rhs: Node) -> Bool {
			return lhs.id == rhs.id
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}

		// MARK: Node properties

		var id: AnyHashable

		var indexPath: IndexPath

		var parentID: AnyHashable?

		var chidlrenIDs: [AnyHashable]

		var model: AnyHashable

		var description: String {
			return "\(id)"
		}
	}



}
