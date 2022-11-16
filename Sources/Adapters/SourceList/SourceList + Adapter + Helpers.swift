//
//  SourceList + Adapter + Helpers.swift
//
//
//  Created by Anton Cherkasov on 17.09.2022.
//

import AppKit

// MARK: - Helpers
extension SourceList.Adapter {

	/// Force updating for cell
	func configureCell<T: ListItem, Cell: ConfigurableCell>(model: T, at row: Int) where T.Cell == Cell {
		let cell = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? Cell
		cell?.model = model
	}

	/// Make cell if it dont exist otherwise configure it
	func makeCellIfNeeded<T: ListItem, Cell: ConfigurableCell>(model: T) -> NSView? where T.Cell == Cell {
		let id = NSUserInterfaceItemIdentifier(Cell.userIdentifier)
		var cell = outlineView.makeView(withIdentifier: id, owner: self) as? Cell
		if cell == nil {
			cell = Cell(model)
			cell?.identifier = id
		}
		cell?.model = model
		return cell
	}

}
