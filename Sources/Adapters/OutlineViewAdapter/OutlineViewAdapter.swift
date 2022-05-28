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
 - Group(id: HeaderModel.ID)
 */

final public class OutlineViewAdapter<Cell: CellRepresentable, Header: GroupRepresentable>: NSObject,
																							NSOutlineViewDataSource,
																							NSOutlineViewDelegate where Header.ViewModel: OutlineGroupPresentable,
																														Header.ViewModel.Item == Cell.ViewModel {

	let NSOutlineViewNoSelectionIndex: Int = -1

	// MARK: Models

	public typealias CellModel 	= Cell.ViewModel
	public typealias HeaderModel 	= Header.ViewModel

	// MARK: Providers

	public var onDropProvider: ((CellModel.ID, Any) -> Void)?
	public var deleteProvider: ((CellModel.ID) -> Void)?
	public var reorderProvider: ((CellModel.ID, ReorderOperation) -> Void)?
	public var selectionProvider: ((HeaderModel.ID, CellModel.ID) -> Void)?
	public var valueDidChanged: ((CellModel.ID, [String: Any]) -> Void)?

	public enum ReorderOperation {
		case toFolder(id: CellModel.ID, toLocation: RelativeLocation<CellModel.ID>?)
		case toGroup(id: HeaderModel.ID, toLocation: RelativeLocation<CellModel.ID>?)
	}

	var outlineView: NSOutlineView

	private (set) var data: [GroupProxy<HeaderModel, CellModel>] = []

	private (set) var draggedTypes: [NSPasteboard.PasteboardType] = []

	// MARK: Temporary states

	private (set) var itemBeingDragged: NodeProxy<CellModel>?

	private var isEditing: Bool = false

	public var selectedItem: CellModel.ID? {

		get {
			let selectedRow = outlineView.selectedRow
			guard
				selectedRow > -1,
				let node = outlineView.item(atRow: selectedRow) as? NodeProxy<CellModel>
			else {
				return nil
			}

			return node.model.id
		}

		set {
			guard let newID = newValue else {
				return
			}
			for group in data {
				for node in group.children {
					if let selected = node.findNode(with: newID) {
						let row = outlineView.row(forItem: selected)
						outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
					}
				}
			}
		}
	}

	public var clickedItem: CellModel.ID? {
		let clickedRow = outlineView.clickedRow
		guard clickedRow > -1 else { return nil }
		guard let node = outlineView.item(atRow: clickedRow) as? NodeProxy<CellModel> else {
			return nil
		}
		return node.model.id
	}

	// MARK: Initialization

	public init(outlineView: NSOutlineView, draggedTypes: [NSPasteboard.PasteboardType]) {
		self.outlineView = outlineView
		super.init()
		self.draggedTypes = draggedTypes
		configureOutlineView()
	}

	private func configureOutlineView() {
		outlineView.delegate = self
		outlineView.dataSource = self
		outlineView.setDraggingSourceOperationMask([.move, .delete], forLocal: false)
		outlineView.registerForDraggedTypes(draggedTypes)
	}

	// MARK: Apply data

	/// Apply new data
	/// - Parameters:
	///    - groups: Groups of the items
	public func apply(groups: [HeaderModel]) {

		data = makeTarget(groups)

		outlineView.reloadData()

		for group in groups where group.alwaysExpanded {
			outlineView.expandItem(nil, expandChildren: true)
		}

	}

	private func makeNodeProxies(_ nodes: [CellModel]?) -> [NodeProxy<CellModel>] {
		guard let nodes = nodes else { return [] }
		return nodes.map {
			NodeProxy(value: $0,
					  children: makeNodeProxies($0.children)
			)
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
		let selectedRow = outlineView.selectedRow
		guard
			selectedRow != NSOutlineViewNoSelectionIndex,
			let node = outlineView.item(atRow: selectedRow) as? NodeProxy<CellModel>
		else {
			return
		}
		if let group = findGroup(of: node) {
			selectionProvider?(group.model.id, node.model.id)
		}
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
			return node.model.isEditable
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		if let node = item as? NodeProxy<CellModel> {
			return node.model.isSelectable
		}
		return false
	}

	public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		return outlineView.rowHeight
	}

	public func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
		guard
			let node = item as? NodeProxy<CellModel>,
			let color = node.model.tintColor
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

	public func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
		if let group = item as? GroupProxy<HeaderModel, CellModel> {
			return group.model.alwaysExpanded == false
		}
		return true
	}

	// MARK: Configure cells

	private func configureHeader<T: GroupRepresentable>(headerType: T.Type,
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

	private func configureCell<T: CellRepresentable>(cellType: T.Type,
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

	public func outlineView(_ outlineView: NSOutlineView,
							validateDrop info: NSDraggingInfo,
							proposedItem item: Any?,
							proposedChildIndex index: Int) -> NSDragOperation {

		if isLocalSource(draggingInfo: info) {
			return validateReorder(to: item, childIndex: index) ? .move : []
		}

		// Perform drop from outside source
		let dropOn = (index == NSOutlineViewDropOnItemIndex)

		if dropOn && item is NodeProxy<CellModel> {
			return .move
		}

		return []
	}

	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {

		guard let node = item as? NodeProxy<CellModel> else { return nil }
		let pasterboardItem = NSPasteboardItem()
		if
			let item = node.model as? PasteboardWriting,
			let pasterboardMap = item.pasterboardMap {
			for (type, data) in pasterboardMap {
				pasterboardItem.setData(data, forType: type)
			}
		}
		pasterboardItem.setString("d", forType: .reorder)
		return pasterboardItem
	}

//	func outlineView(_ outlineView: NSOutlineView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
//		draggingInfo.numberOfValidItemsForDrop = 0
//	}

	public func outlineView(_ outlineView: NSOutlineView,
					 draggingSession session: NSDraggingSession,
					 willBeginAt screenPoint: NSPoint,
					 forItems draggedItems: [Any]) {
		if draggedItems.count == 1 {
			itemBeingDragged = draggedItems.last as? NodeProxy<CellModel>
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

		if isLocalSource(draggingInfo: info) && validateReorder(to: item, childIndex: index) {
			return performReoder(destinationItem: item, at: index)
		} else if
			// If it was a drop "on"
			index == NSOutlineViewDropOnItemIndex,
			let node = item as? NodeProxy<CellModel>
		{
			return true//performDrop(node.id, with: info)
		}

		return true
	}

	private func validateReorder(to item: Any?, childIndex index: Int) -> Bool {

		let dropOn = (index == NSOutlineViewDropOnItemIndex)

		guard
			let dragged = itemBeingDragged,
			let sourceGroup = findGroup(of: dragged)
		else {
			return false
		}

		if let targetGroup = item as? GroupProxy<HeaderModel, CellModel> {
			return dropOn == false && sourceGroup === targetGroup
		}

		guard
			let node = item as? NodeProxy<CellModel>,
			let targetGroup = findGroup(of: node)
		else {
			return false
		}

		let destinationID = node.model.id

		let isAncestor = dragged.isAncestor(of: destinationID)
		let inSameGroup = (sourceGroup === targetGroup)

		guard inSameGroup && !isAncestor else { return false }

		if node.isFile && dropOn {
			return false
		}

		return true
	}

	private func findGroup(of node: NodeProxy<CellModel>) -> GroupProxy<HeaderModel, CellModel>? {
		var parentGroup: Any? = node
		while (parentGroup is GroupProxy<HeaderModel, CellModel>) == false {
			parentGroup = outlineView.parent(forItem: parentGroup)
		}
		return parentGroup as? GroupProxy<HeaderModel, CellModel>
	}

	private func validateDropFromExternalSource() -> Bool {
		return false
	}

	private func performDropFromExternalSource(destination: Any?, childIndex index: Int) -> Bool {
		guard let node = destination as? NodeProxy<CellModel> else {
			return false
		}
		return true
	}

	private func performReoder(destinationItem destination: Any?, at index: Int) -> Bool {

		guard let source = itemBeingDragged else { return false }

		let droppedID = source.model.id

		let dropOn = (index == NSOutlineViewDropOnItemIndex)

		if let group = destination as? GroupProxy<HeaderModel, CellModel> {

			if index == 0 {
				let id = group.children[0].model.id
				let location = RelativeLocation<CellModel.ID>.before(id)
				let operation: ReorderOperation = dropOn
				? .toGroup(id: group.model.id, toLocation: nil)
				: .toGroup(id: group.model.id, toLocation: location)
				reorderProvider?(droppedID, operation)
			} else if group.children.count > 1 {
				let id = group.children[index - 1].model.id
				let location = RelativeLocation<CellModel.ID>.after(id)
				let operation: ReorderOperation = dropOn
				? .toGroup(id: group.model.id, toLocation: nil)
				: .toGroup(id: group.model.id, toLocation: location)
				reorderProvider?(droppedID, operation)
			}

		} else if let file = destination as? NodeProxy<CellModel> {

			if let children = file.children {
				if index == 0, let id = file.children?[0].model.id {
					let location = RelativeLocation<CellModel.ID>.before(id)
					let operation: ReorderOperation = dropOn
					? .toFolder(id: id, toLocation: nil)
					: .toFolder(id: id, toLocation: location)
					reorderProvider?(droppedID, operation)
				} else if children.count > 1 {
					let id = children[index - 1].model.id
					let location = RelativeLocation<CellModel.ID>.after(id)
					let operation: ReorderOperation = dropOn
					? .toFolder(id: file.model.id, toLocation: nil)
					: .toFolder(id: file.model.id, toLocation: location)
					reorderProvider?(droppedID, operation)
				}
			}
		}
		return true
	}

	private func performDrop(_ id: CellModel.ID, with draggingInfo: NSDraggingInfo) -> Bool {

//		guard draggedTypes.isEmpty == false else {
//			return false
//		}
//
//		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
//		if let data = pasteboardItems.first?.data(forType: draggedType) {
//			let identifiers = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UUID]
//			onDropProvider?(id, identifiers)
//			return true
//		}
		return false
	}

	private func performDelete(draggedItem: NodeProxy<CellModel>?) {
		if let id = itemBeingDragged?.model.id {
			deleteProvider?(id)
		}
	}

	private func isLocalSource(draggingInfo info: NSDraggingInfo) -> Bool {
		if let source = info.draggingSource as? NSOutlineView, source === outlineView {
			return true
		}
		return false
	}

}
