//
//  List.Adapter + NSTableViewDelegate.swift
//  
//
//  Created by Anton Cherkasov on 08.09.2022.
//

import AppKit

extension List.Adapter: NSTableViewDelegate {

	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let model = snapshot[row]
		return configureCell(model: model)
	}

	public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		if let height = snapshot[row].configuration.height {
			return height
		}
		return tableView.rowHeight
	}

	public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
		return snapshot[row].isGroup
	}

	public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let model = snapshot[row]
		return model.configuration.isSelectable
	}

	public func tableView(_ tableView: NSTableView,
						  rowActionsForRow row: Int,
						  edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		guard let actionRowSupportable = snapshot[row] as? RowActionSupportable else {
			return []
		}
		switch edge {
			case .trailing: return actionRowSupportable.trailingActions
			case .leading:	return actionRowSupportable.leadingActions
			@unknown default:
				return []
		}
	}

}

// MARK: - Notifications
extension List.Adapter {

	public func tableViewSelectionDidChange(_ notification: Notification) {
		guard
			let source = notification.object as? NSTableView,
			source === tableView, isEditing == false
		else {
			return
		}
		selectionDidChanged?(tableView.selectedRowIndexes)
	}
}

// MARK: - Helpers
private extension List.Adapter {

	func configureCell<T: ListItem, Cell: ConfigurableCell>(model: T) -> NSView? where T.Cell == Cell {
		let id = NSUserInterfaceItemIdentifier(Cell.userIdentifier)
		var cell = tableView.makeView(withIdentifier: id, owner: self) as? Cell
		if cell == nil {
			cell = Cell(model)
			cell?.identifier = id
		}
		cell?.model = model
		return cell
	}
}
