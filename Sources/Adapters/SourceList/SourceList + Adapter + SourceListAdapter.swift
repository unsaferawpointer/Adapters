//
//  SourceList + Adapter + SourceListAdapter.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit
import os.log

// MARK: - SourceListAdapter
extension SourceList.Adapter: SourceListAdapter {

	public func setupFocus(_ identifier: (some Hashable)?) {
		guard let identifier, let outlineItem = items[identifier] else {
			return
		}
		let row = outlineView.row(forItem: outlineItem)
		guard row != NSOutlineViewNoSelectionIndex else {
			os_log(.debug, "Can`t set a focus on this row. May be it is hidden")
			return
		}
		for index in 0..<outlineView.numberOfColumns {
			guard let cell = outlineView.view(atColumn: index, row: row, makeIfNecessary: false) as? Focusable else {
				break
			}
			cell.onFocus(true)
		}
	}

	public func scrollTo(_ identifier: (some Hashable)?, withAnimation: Bool = true) {
		guard let identifier, let outlineItem = items[identifier] else {
			return
		}
		let row = outlineView.row(forItem: outlineItem)
		guard row != NSOutlineViewNoSelectionIndex else {
			os_log(.debug, "Can`t scroll to this row. May be it is hidden")
			return
		}
		if withAnimation {
			NSAnimationContext.runAnimationGroup { context in
				context.allowsImplicitAnimation = true
				outlineView.scrollRowToVisible(row)
			}
		} else {
			outlineView.scrollRowToVisible(row)
		}
	}

	public func select(identifiers: [some Hashable], byExtendingSelection extendSelection: Bool = false) {
		let outlineItems = identifiers.compactMap { items[$0] }
		let rows = outlineItems.map {
			outlineView.row(forItem: $0)
		}.filter { row in
			row != NSOutlineViewNoSelectionIndex
		}
		let selection = IndexSet(rows)
		outlineView.selectRowIndexes(selection, byExtendingSelection: extendSelection)
	}

	public func forceUpdate(_ model: any ListItem) {
		guard let outlineItem = items[model.itemIdentifier] else {
			return
		}
		snapshot.forceUpdate(model)
		let row = outlineView.row(forItem: outlineItem)
		guard row != NSOutlineViewNoSelectionIndex else {
			fatalError()
		}
		configureCell(model: model, at: row)
	}

	public func getSelection() -> [Index] {
		let selectedRows = outlineView.commonSelection
		let items = outlineItems(for: selectedRows)
		let indexes = items.compactMap { item -> SourceList.Index? in
			guard let indexPath = snapshot.indexPath(forIdentifier: item.id) else {
				return nil
			}
			return Index(id: item.id, indexPath: indexPath)
		}
		return indexes
	}

	public func expand(_ identifier: (some Hashable)?, withAnimation: Bool = true, expandChildren: Bool = false) {
		guard let identifier, let outlineItem = items[identifier] else {
			return
		}
		if withAnimation {
			outlineView.animator().expandItem(outlineItem, expandChildren: expandChildren)
		} else {
			outlineView.expandItem(outlineItem)
		}
	}
}

extension SourceList.Adapter {

	func outlineItems(for rows: IndexSet) -> [OutlineItem] {
		return rows.compactMap {
			outlineView.item(atRow: $0) as? OutlineItem
		}
	}

}
