//
//  OutlineViewAdapter.swift
//  Adapters
//
//  Created by Anton Cherkasov on 01.01.2022.
//

import AppKit

/*
 - Group(id: HeaderModel.ID)
	- File(id: CellModel.ID)
	- Folder(id: CellModel.ID)
		- File(id: CellModel.ID)
		- File(id: CellModel.ID)
		- Folder(id: CellModel.ID)
	- File(id: CellModel.ID)
 - Group(id: HeaderModel.ID)
 */

final public class OutlineViewAdapter<Cell: OutlineCellRepresentable, Header: OutlineHeaderCellRepresentable>: NSObject,
																											 NSOutlineViewDataSource,
																											 NSOutlineViewDelegate where Header.ViewModel: OutlineGroupRepresentable,
																														Header.ViewModel.Item == Cell.ViewModel {

	let NSOutlineViewNoSelectionIndex: Int = -1

	// MARK: Models

	public typealias CellModel 		= Cell.ViewModel
	public typealias HeaderModel 	= Header.ViewModel

	// MARK: Providers

	public var onDropProvider: 		((CellModel.ID, [NSPasteboard.PasteboardType: [Any]]) -> Void)?
	public var deleteProvider: 		((CellModel.ID) -> Void)?
	public var reorderProvider: 	((CellModel.ID, ReorderOperation) -> Void)?
	public var selectionProvider:	((HeaderModel.ID, CellModel.ID) -> Void)?
	public var valueDidChanged:		((CellModel.ID, [String: Any]) -> Void)?

	public enum ReorderOperation {
		case insertToFolder(id: CellModel.ID, location: RelativeLocation<CellModel.ID>)
		case insertToGroup(id: HeaderModel.ID, location: RelativeLocation<CellModel.ID>)
		case appendToFolder(id: CellModel.ID)
		case appendToGroup(id: HeaderModel.ID)
	}

	private (set) var outlineView: NSOutlineView

	private (set) var data: [GroupProxy<HeaderModel, CellModel>] = []

	// MARK: Temporary states

	var itemBeingDragged: NodeProxy<CellModel>?

	private var isEditing: Bool = false

	public var expanded: Set<CellModel.ID> = []

	private var cache: [CellModel.ID: NodeProxy<CellModel>] = [:]

	public var selectedItem: CellModel.ID? {
		didSet {
			guard isEditing == false else { return }
			selectItem(selectedItem)
		}
	}

	private func selectItem(_ identifier: CellModel.ID?) {
		guard let identifier = identifier else {
			outlineView.selectRowIndexes(.init(), byExtendingSelection: false)
			return
		}
		for group in data {
			for node in group.children {
				if let selected = node.findNode(with: identifier) {
					let row = outlineView.row(forItem: selected)
					print("selected item = \(selected)")
					print("selected row = \(row)")
					let indexes = IndexSet(integer: row)
					outlineView.selectRowIndexes(indexes, byExtendingSelection: false)
				}
			}
		}

	}

	public var clickedItem: CellModel.ID? {

		let clickedRow = outlineView.clickedRow
		guard clickedRow != NSOutlineViewNoSelectionIndex else {
			return nil
		}
		guard let node = outlineView.item(atRow: clickedRow) as? NodeProxy<CellModel> else {
			return nil
		}
		return node.model.id
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
	public func apply(groups: [HeaderModel]) {

		cache.removeAll()
		data = makeTarget(groups)

		outlineView.reloadData()

		for group in data {
			outlineView.expandItem(group, expandChildren: false)
		}

		let expandedUnion = Set.init(cache.keys).intersection(expanded)
		expanded = expandedUnion

		for id in expanded {
			let node = cache[id]
			outlineView.expandItem(node, expandChildren: false)
		}

	}

	private func makeNodeProxies(_ nodes: [CellModel]?) -> [NodeProxy<CellModel>] {
		guard let nodes = nodes else { return [] }
		return nodes.map {
			let result = NodeProxy(value: $0, children: makeNodeProxies($0.children))
			cache[$0.id] = result
			return result
		}
	}

	private func makeTarget(_ groups: [HeaderModel]) -> [GroupProxy<HeaderModel, CellModel>] {
		return groups.map { GroupProxy(model: $0, children: makeNodeProxies($0.children)) }
	}

	// MARK: Notifications

	public func outlineViewSelectionDidChange(_ notification: Notification) {
		guard let object = notification.object as? NSOutlineView, object === outlineView else {
			return
		}

		let selectedRows = outlineView.selectedRowIndexes

		let selectedNodes = selectedRows.compactMap { row in
			outlineView.item(atRow: row) as? NodeProxy<CellModel>
		}

		selectedNodes.forEach{ $0.model.itemDidSelected?() }
//		if let group = findGroup(of: node) {
//			selectionProvider?(group.model.id, node.model.id)
//		}
	}

	// MARK: NSOutlineViewDataSource

	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.children.count
		}
		if let node = item as? NodeProxy<CellModel> {
			return node.children?.count ?? 0
		}
		return data.count
	}

	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.children[index]
		}
		if let node = item as? NodeProxy<CellModel> {
			return node.children![index]
		}
		return data[index]
	}

	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.children.count > 0
		}
		guard
			let node = item as? NodeProxy<CellModel>,
			let children = node.children // It is file
		else {
			return false
		}
		return children.count > 0
	}

	// MARK: NSOutlineViewDelegate

	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return configureHeader(headerType: Header.self, model: group.model)
		}
		if let node = item as? NodeProxy<CellModel> {
			return configureCell(cellType: Cell.self, model: node.model)
		}
		return nil
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
		if let node = item as? NodeProxy<CellModel> {
			return node.model.configuration.isEditable
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		if let node = item as? NodeProxy<CellModel> {
			return node.model.configuration.isSelectable
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		return outlineView.rowHeight
	}

	public func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
		guard
			let node = item as? NodeProxy<CellModel>,
			let color = node.model.configuration.tintColor
		else {
			return .monochrome
		}
		return .init(preferredColor: color)
	}

	public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		if item is GroupProxy<HeaderModel, CellModel> {
			return true
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.model.alwaysExpanded == false
		}
		return true
	}

	public func outlineViewItemDidCollapse(_ notification: Notification) {
		if let node = notification.userInfo?["NSObject"] as? NodeProxy<CellModel> {
			expanded.remove(node.model.id)
		}
	}

	public func outlineViewItemDidExpand(_ notification: Notification) {
		if let node = notification.userInfo?["NSObject"] as? NodeProxy<CellModel> {
			expanded.insert(node.model.id)
		}
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.model.alwaysExpanded == false
		}
		return true
	}

	// MARK: Configure cells

	private func configureHeader<T: OutlineHeaderCellRepresentable>(headerType: T.Type,
														model: T.ViewModel) -> T? where T.ViewModel == HeaderModel {
		let id = NSUserInterfaceItemIdentifier("header")
		var cell = outlineView.makeView(withIdentifier: id, owner: self) as? T
		if cell == nil {
			cell = T()
			cell?.identifier = id
		}
		cell?.model = model
		return cell
	}

	private func configureCell<T: OutlineCellRepresentable>(cellType: T.Type,
													 model: T.ViewModel) -> T? where T.ViewModel == CellModel {
		let id = NSUserInterfaceItemIdentifier("cell")
		var cell = outlineView.makeView(withIdentifier: id, owner: self) as? T
		if cell == nil {
			cell = T()
			cell?.identifier = id
		}
		cell?.model = model
		cell?.valueDidChanged = { [weak self] id, value in
			self?.valueDidChanged?(model.id, value)
		}
		return cell
	}

	// MARK: Drag And Drop Support

	/// - Warning: Support only drop on item
	public func outlineView(_ outlineView: NSOutlineView,
							validateDrop info: NSDraggingInfo,
							proposedItem item: Any?,
							proposedChildIndex index: Int) -> NSDragOperation {

		let dropOn = (index == NSOutlineViewDropOnItemIndex)
		let dropOperation: DropOperation = dropOn ? .dropOn : .dropAbove
		let draggingSource = getDraggingSource(draggingInfo: info)

		// Validate drop from local source
		if draggingSource == .local {
			return validateReorder(to: item, dropOperation: dropOperation) ? .move : []
		}

		// Validate drop from internal or external source
		return validateDrop(from: draggingSource, info: info, proposedItem: item, dropOperation: dropOperation)

	}

	/// Supports dragging nodes only, excluding groups
	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {

		guard let node = item as? NodeProxy<CellModel> else { return nil }
		let pasterboardItem = NSPasteboardItem()
		if let model = node.model as? DragSupportable {
			for type in model.availableTypes {
				if let data = model.providedData(for: type) {
					pasterboardItem.setData(data, forType: type)
				}
			}
		}
		pasterboardItem.setData(Data(), forType: .reorder)
		return pasterboardItem
	}

	/// Supports reordering nodes only, excluding groups
	public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession,
							willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
		if
			let item = draggedItems.last as? NodeProxy<CellModel>,
			draggedItems.count == 1, item.model.configuration.isReorderable {
			itemBeingDragged = item
		}
	}

	public func outlineView(_ outlineView: NSOutlineView,
					 draggingSession session: NSDraggingSession,
					 endedAt screenPoint: NSPoint,
					 operation: NSDragOperation) {
		if operation == .delete {
			performDelete(draggedItem: itemBeingDragged)
		}
		itemBeingDragged = nil
	}

	public func outlineView(_ outlineView: NSOutlineView,
							acceptDrop info: NSDraggingInfo,
							item: Any?,
							childIndex index: Int) -> Bool {

		let draggingSource = getDraggingSource(draggingInfo: info)
		let dropOn = (index == NSOutlineViewDropOnItemIndex)
		let dropOperation: DropOperation = dropOn ? .dropOn : .dropAbove

		if draggingSource == .local {
			return performReoder(destinationItem: item, at: index)
		}

		return performDrop(from: draggingSource, info: info, destination: item, dropOperation: dropOperation)
	}

	// Support reorder

	private func validateReorder(to item: Any?, dropOperation: DropOperation) -> Bool {

		guard
			let dragged = itemBeingDragged,
			let sourceGroup = findGroup(of: dragged)
		else {
			return false
		}

		// Drop into group
		if let targetGroup = item as? GroupProxy<HeaderModel, CellModel> {
			return sourceGroup === targetGroup
		}

		// Drop into/on node
		guard
			let targetNode = item as? NodeProxy<CellModel>,
			let targetGroup = findGroup(of: targetNode)
		else {
			return false
		}

		let dropIntoItself = !(dragged === targetNode)
		let isAncestor = self.isAncestor(dragged, of: targetNode)
		let isSameGroup = (sourceGroup === targetGroup)

		guard isSameGroup && !isAncestor && !dropIntoItself else { return false }

		if targetNode.isFile && dropOperation == .dropOn {
			return false
		}

		return true
	}

	// Support drag and drop from external source

	private func validateDrop(from source: DraggingSource,
							  info: NSDraggingInfo,
							  proposedItem item: Any?,
							  dropOperation: DropOperation) -> NSDragOperation {

		guard
			let node = item as? NodeProxy<CellModel>, dropOperation == .dropOn,
			let model = node.model as? DropSupportable,
			let pasteboardItems = info.draggingPasteboard.pasteboardItems
		else {
			return []
		}

		let flattenTypes = pasteboardItems.flatMap { $0.types }
		print("flattenType = \(flattenTypes)")
		for type in flattenTypes {
			let dragOperation = model.canHandle(operation: dropOperation, from: source, with: type)
			if dragOperation != [] {
				return dragOperation
			}
		}

		return []
	}

	private func performDrop(from source: DraggingSource, info: NSDraggingInfo,
							 destination: Any?, dropOperation: DropOperation) -> Bool {

		guard
			let node = destination as? NodeProxy<CellModel>,
			let model = node.model as? DropSupportable,
			case .dropOn = dropOperation
		else {
			return false
		}

		var dictionary: [NSPasteboard.PasteboardType: [Any]] = [:]
		for pasterboardItem in info.draggingPasteboard.pasteboardItems ?? [] {
			let types = pasterboardItem.types.filter{
				model.canHandle(operation: dropOperation, from: source, with: $0) != []
			}
			types.forEach { type in
				if let data = pasterboardItem.data(forType: type) {
					dictionary[type, default: []].append(data)
				}
			}
		}
		onDropProvider?(node.model.id, dictionary)
		return true
	}

	private func performReoder(destinationItem destination: Any?, at index: Int) -> Bool {

		guard let draggedItem = itemBeingDragged else { return false }

		if let group = destination as? GroupProxy<HeaderModel, CellModel> {
			return performReorder(of: draggedItem, destination: group, index: index)
		}

		if let node = destination as? NodeProxy<CellModel>, node.isFolder {
			return performReorder(of: draggedItem, destination: node, index: index)
		}

		assertionFailure("Operation cannot be performed, because it is leaf")
		return true
	}

	private func performReorder(of node: NodeProxy<CellModel>,
								destination group: GroupProxy<HeaderModel, CellModel>,
								index: Int) -> Bool {

		let dropOn = (index == NSOutlineViewDropOnItemIndex)

		let destinationID = group.model.id
		let draggedID = node.model.id

		if dropOn || group.children.isEmpty {
			let operation: ReorderOperation = .appendToGroup(id: destinationID)
			reorderProvider?(draggedID, operation)
			return true
		}

		if index > 0 {
			let id = group.children[index - 1].model.id
			let operation: ReorderOperation = .insertToGroup(id: destinationID,
															 location: .after(id))
			reorderProvider?(draggedID, operation)
			return true
		} else if data.count > 1 {
			let id = group.children[index].model.id
			let operation: ReorderOperation = .insertToGroup(id: destinationID,
															 location: .before(id))
			reorderProvider?(draggedID, operation)
			return true
		}
		return true
	}

	private func performReorder(of node: NodeProxy<CellModel>,
								destination folder: NodeProxy<CellModel>,
								index: Int) -> Bool {

		let dropOn = (index == NSOutlineViewDropOnItemIndex)

		let destinationID = folder.model.id
		let draggedID = node.model.id

		if dropOn {
			let operation: ReorderOperation = .appendToFolder(id: destinationID)
			reorderProvider?(draggedID, operation)
			return true
		}

		if index > 0 {
			let id = folder.children![index - 1].model.id
			let operation: ReorderOperation = .insertToFolder(id: destinationID,
															  location: .after(id))
			reorderProvider?(draggedID, operation)
			return true
		} else if data.count > 1 {
			let id = folder.children![index].model.id
			let operation: ReorderOperation = .insertToFolder(id: destinationID,
															  location: .before(id))
			reorderProvider?(draggedID, operation)
			return true
		}

		return true
	}

//	private func performDrop(_ id: CellModel.ID, with draggingInfo: NSDraggingInfo) -> Bool {
//
////		guard draggedTypes.isEmpty == false else {
////			return false
////		}
////
////		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
////		if let data = pasteboardItems.first?.data(forType: draggedType) {
////			let identifiers = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UUID]
////			onDropProvider?(id, identifiers)
////			return true
////		}
//		return false
//	}

	private func performDelete(draggedItem: NodeProxy<CellModel>?) {
		if let id = itemBeingDragged?.model.id {
			deleteProvider?(id)
		}
	}

	private func getDraggingSource(draggingInfo info: NSDraggingInfo) -> DraggingSource {
		if let source = info.draggingSource as? NSOutlineView, source === outlineView {
			return .local
		} else if let _ = info.draggingSource {
			return .internal
		}
		return .external
	}

	private func findGroup(of node: NodeProxy<CellModel>) -> GroupProxy<HeaderModel, CellModel>? {
		var parent: Any? = node
		while parent != nil {
			parent = outlineView.parent(forItem: parent)
			if let group = parent as? GroupProxy<HeaderModel, CellModel> {
				return group
			}
		}
		return nil
	}

	private func isAncestor(_ putativeAncestor: NodeProxy<CellModel>, of node: NodeProxy<CellModel>) -> Bool {

		var parent: AnyObject? = node
		while parent != nil {
			print(#function)
			parent = outlineView.parent(forItem: parent) as? NodeProxy<CellModel>
			if putativeAncestor === parent {
				return true
			}
		}
		return false
	}

}

extension OutlineViewAdapter {

	public func setFocus(_ identifier: CellModel.ID?) {
		guard let id = identifier else { return }
		var selectedProxyNode: NodeProxy<CellModel>?
		for i in 0..<data.count {
			let nodes = data[i].children
			for node in nodes {
				if let finded = node.findNode(with: id) {
					selectedProxyNode = finded
				}
			}
		}
		if let selectedProxyNode = selectedProxyNode {
			let row = outlineView.row(forItem: selectedProxyNode)
			if let cell = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? Focusable {
				cell.onFocus(true)
			}
		}

	}

}
