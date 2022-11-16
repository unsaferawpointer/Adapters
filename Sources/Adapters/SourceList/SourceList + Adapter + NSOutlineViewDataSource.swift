//
//  SourceList + Adapter + NSOutlineViewDataSource.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit

// MARK: - NSOutlineViewDataSource
extension SourceList.Adapter: NSOutlineViewDataSource {

	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		guard let item = item as? OutlineItem else {
			return snapshot.childrenCount(for: nil)
		}
		return snapshot.childrenCount(for: item.id)
	}

	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		guard let item = item as? OutlineItem else {
			guard let identifier = snapshot.childIdentifier(in: nil, at: index) else {
				fatalError("Can`t find root node at index = \(index) in the snapshot")
			}
			return items[identifier] as Any
		}
		guard let identifier = snapshot.childIdentifier(in: item.id, at: index) else {
			fatalError("Can`t find identifier = \(item.id) in the snapshot")
		}
		return items[identifier] as Any
	}

	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		guard let item = item as? OutlineItem else {
			fatalError("Item must be instance of the 'OutlineItem'")
		}
		return snapshot.childrenCount(for: item.id) > 0
	}
}
