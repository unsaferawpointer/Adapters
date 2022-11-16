//
//  SourceList + NSOutlineViewDelegate.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit

// MARK: - NSOutlineViewDelegate
extension SourceList.Adapter: NSOutlineViewDelegate {

	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		guard let item = item as? OutlineItem, let model = snapshot[item.id] else {
			fatalError("Cant find model for the item = \(item)")
		}
		return makeCellIfNeeded(model: model)
	}

	public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		guard let item = item as? OutlineItem, let model = snapshot[item.id] else {
			return false
		}
		return model.isGroup
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		guard let item = item as? OutlineItem, let model = snapshot[item.id] else {
			return false
		}
		return model.isSelectable && !snapshot.isGroup(identifier: item.id)
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
		guard let item = item as? OutlineItem else {
			return true
		}
		return !snapshot.isGroup(identifier: item.id)
	}

	public func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
		guard let item = item as? OutlineItem else {
			return true
		}
		return true /*item.model.alwaysExpanded == false*/
	}

	public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		guard let item = item as? OutlineItem, let height = snapshot[item.id]?.height else {
			return outlineView.rowHeight
		}
		return height
	}

	@available(macOS 11.0, *)
	public func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
		guard let item = item as? OutlineItem, let model = snapshot[item.id] as? Colorable else {
			return .init(preferredColor: .controlAccentColor)
		}
		guard let color = model.tintColor else {
			return .monochrome
		}
		return .init(preferredColor: color)
	}
}
