//
//  NSTableView Extension.swift
//  JustTo-DoList
//
//  Created by Anton Cherkasov on 10.08.2021.
//

import AppKit

extension NSTableView {

	var commonSelection: IndexSet {
		if clickedRow >= 0 {
			if selectedRowIndexes.contains(clickedRow) {
				return selectedRowIndexes
			} else {
				return IndexSet(integer: clickedRow)
			}
		} else {
			return selectedRowIndexes
		}
	}

	func makeView(withIdentifier identifier: String, owner: Any?) {
		let userIdentifier = NSUserInterfaceItemIdentifier(identifier)
		makeView(withIdentifier: userIdentifier, owner: owner)
	}
}
