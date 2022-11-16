//
//  List.Adapter.swift
//  
//
//  Created by Anton Cherkasov on 08.09.2022.
//

import Foundation

extension List.Adapter {

	public func apply(_ newSnapshot: List.Snapshot, animate: Bool = true) {

		/// Save selection state
		let selectedRows = tableView.selectedRowIndexes
		let selectedIdentifiers = selectedRows.compactMap {
			snapshot[$0].itemIdentifier
		}

		if newSnapshot.isEmpty || snapshot.isEmpty || !animate {
			forceReload(newSnapshot)
			return
		}

		let newIdentifiers = newSnapshot.identifiers
		let oldIdentifiers = snapshot.identifiers

		for oldIdentifier in oldIdentifiers {
			if
				let oldIndex = snapshot.getIndex(for: oldIdentifier),
				let newModel = newSnapshot[oldIdentifier],
				snapshot[oldIndex].isContentEqual(to: newModel) == false
			{
				updateCell(at: oldIndex, with: newModel)
			}
		}

		var removed = IndexSet()
		var inserted = IndexSet()

		let diff = newIdentifiers.difference(from: oldIdentifiers)
		for change in diff {
			switch change {
				case .remove(let offset, _, _: _): removed.insert(offset)
				case .insert(let offset, _, _: _): inserted.insert(offset)
			}
		}

		updateTable(removedRows: removed, insertedRows: inserted) { [weak self] in
			self?.snapshot = newSnapshot
		}

		let rows = selectedIdentifiers.compactMap { snapshot.getIndex(for: $0) }
		tableView.selectRowIndexes(IndexSet(rows), byExtendingSelection: false)
	}

}

private extension List.Adapter {

	func updateTable(removedRows: IndexSet, insertedRows: IndexSet, completionHandler: @escaping () -> Void) {

		isEditing = true
		self.tableView.beginUpdates()
		self.tableView.removeRows(at: removedRows, withAnimation: [.slideDown, .effectFade])
		self.tableView.insertRows(at: insertedRows, withAnimation: [.slideLeft, .effectFade])
		completionHandler()
		self.tableView.endUpdates()
		isEditing = false

	}

	func forceReload(_ newSnapshot: List.Snapshot) {
		self.snapshot = newSnapshot
		tableView.reloadData()
	}

	func updateCell<T: ListItem>(at row: Int, with model: T) {
		if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? T.Cell {
			cell.model = model
		}
	}

}
