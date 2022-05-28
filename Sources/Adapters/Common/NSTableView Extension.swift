//
//  NSTableView Extension.swift
//  JustTo-DoList
//
//  Created by Anton Cherkasov on 10.08.2021.
//

import AppKit

extension NSTableView {

	static let noSelectionIndex = -1

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
}
