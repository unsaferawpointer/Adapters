//
//  SourceList + Adapter.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit
import Collections

public extension SourceList {

	final class Adapter: NSObject {

		typealias OutlineItem = SourceList.OutlineItem

		let NSOutlineViewNoSelectionIndex: Int = -1

		private (set) var outlineView: NSOutlineView

		/// Reference-type storage
		var items: [AnyHashable: OutlineItem] = [:]

		var isEditing = false

		/// Snapshot to store tree hierarchy of the data
		var snapshot: TreeSnapshot = .init()

		// MARK: - SourceListAdapterProtocol

		public var selectionProvider: SourceList.SelectionProvider? = nil

		public var dropConfiguration: SourceList.DropConfiguration? = nil {
			didSet {
				outlineView.unregisterDraggedTypes()
				guard let configuration = dropConfiguration else {
					return
				}
				let types = configuration.draggedTypes() + [.indexes]
				outlineView.registerForDraggedTypes(types)
			}
		}

		/// Initialization
		/// - Parameters:
		///    - outlineView: Configurable outlineview
		public init(_ outlineView: NSOutlineView) {
			self.outlineView = outlineView
			super.init()
			outlineView.dataSource = self
			outlineView.delegate = self
			outlineView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
		}

		// MARK: - Notifications
		public func outlineViewSelectionDidChange(_ notification: Notification) {
			guard
				let sender = notification.object as? NSOutlineView,
				sender === outlineView, isEditing == false else
			{
				return
			}
			let selection = getSelection()

			for index in selection {
				(snapshot[index.id] as? Selectable)?.itemDidSelected?()
			}

			selectionProvider?.select(selection)
		}

	}
}
