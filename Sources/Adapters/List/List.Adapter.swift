//
//  ListView.Adapter.swift
//  
//
//  Created by Anton Cherkasov on 22.08.2022.
//

import AppKit

/// Public interface of the list adapter
protocol ListAdapter {
	init(_ tableView: NSTableView)
	func scrollTo(identifier: (any Hashable)?, withAnimation: Bool)
	func select(identifiers: [any Hashable])
	func setFocus(_ identifier: (any Hashable)?)
}

extension List {

	/// Adapter for single - column NSTableView
	public final class Adapter: NSObject {

		// MARK: Drag&Drop Support

		let NSTableViewDropToRootIndex = -1

		public var dropConfiguration: InternalListDropConfiguration = List.DropConfiguration() {
			didSet {
				let types = dropConfiguration.availableTypes + [.indexes]
				tableView.unregisterDraggedTypes()
				tableView.registerForDraggedTypes(types)
			}
		}

		// MARK: - Private properties

		private (set) var tableView: NSTableView

		// MARK: - State

		var snapshot: List.Snapshot = .init()

		var isEditing = false

		var selectionDidChanged: ((IndexSet) -> Void)?

		public var commonSelection: [AnyHashable] {
			let indexes = tableView.commonSelection
			return indexes.map { snapshot[$0].itemIdentifier }
		}

		/// Initialization
		///
		/// - Parameters
		///
		public init(_ tableView: NSTableView) {
			self.tableView = tableView
			super.init()
			tableView.delegate = self
			tableView.dataSource = self
			tableView.setDraggingSourceOperationMask([.delete, .copy], forLocal: false)
		}

	}

	
}

extension List.Adapter: ListAdapter {

	public func scrollTo(identifier: (any Hashable)?, withAnimation: Bool) {
		guard let row = getRow(for: identifier) else {
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

	public func select(identifiers: [any Hashable]) {
		let anyIdentifiers = identifiers.map { AnyHashable($0) }
		let indexes = snapshot.getIndexes(for: anyIdentifiers)
		tableView.selectRowIndexes(indexes, byExtendingSelection: false)
	}

	public func setFocus(_ identifier: (any Hashable)?) {
		guard let row = getRow(for: identifier) else {
			return
		}
		if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? Focusable {
			cell.onFocus(true)
		}
	}

	public func update(item: any ListItem) {
//		guard let row = snapshot[item.id] else {
//			return
//		}
		fatalError()
	}

}

public extension List.Adapter {

	@discardableResult
	func onSelect(action: ((IndexSet) -> Void)?) -> Self {
		selectionDidChanged = action
		return self
	}

}
