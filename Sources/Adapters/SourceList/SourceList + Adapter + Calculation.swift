//
//  SourceList + Adapter + Calculation.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit
import Foundation
import Collections

extension SourceList.Adapter {

	typealias TreeSnapshot = SourceList.TreeSnapshot

	func calculate(oldState: [AnyHashable],
				   newState: [AnyHashable],
				   oldSnapshot: TreeSnapshot,
				   newSnapshot: TreeSnapshot,
				   inParent parent: OutlineItem? = nil) {

		var oldBuffer = oldState
		let newBuffer = newState

		guard !oldState.isEmpty || !newState.isEmpty else {
			// Early exit. No state to compare.
			return
		}

		let difference = newBuffer.difference(from: oldBuffer)

		if !difference.isEmpty {
			// Parent needs to be update as the children have changed.
			// Children are not reloaded to allow animation.
			outlineView.reloadItem(parent, reloadChildren: false)
		}

		var removed: Set<AnyHashable> = []

		for change in difference {
			switch change {
				case .remove(let offset, let element, _):
					removed.insert(element)
					outlineView.removeItems(at: IndexSet(integer: offset),
											inParent: parent,
											withAnimation: [.effectFade])
				case .insert(let offset, _, _):
					outlineView.insertItems(at: IndexSet(integer: offset),
											inParent: parent,
											withAnimation: [.effectFade])
			}
		}

		oldBuffer.removeAll{ removed.contains($0) }
		oldBuffer.forEach {
			let parent = items[$0]

			calculate(oldState: oldSnapshot.childrenIdentifiers($0),
					  newState: newSnapshot.childrenIdentifiers($0),
					  oldSnapshot: oldSnapshot,
					  newSnapshot: newSnapshot,
					  inParent: parent)
		}

	}

}

// MARK: - Apply new data
public extension SourceList.Adapter {

	func apply(_ newItems: [TreeNode<any ListItem>], animate: Bool) {

		let newSnapshot = TreeSnapshot(newItems)
		let oldSnapshot = snapshot

		guard animate else {
			forceReload(newSnapshot)
			return
		}

		updateItemContentIfNeeded(oldSnapshot: oldSnapshot, newSnapshot: newSnapshot)

		outlineView.beginUpdates()
		updateOutlineItems(oldSnapshot: oldSnapshot, newSnapshot: newSnapshot)
		self.snapshot = newSnapshot
		calculate(oldState: oldSnapshot.rootIdentifiers,
				  newState: newSnapshot.rootIdentifiers,
				  oldSnapshot: oldSnapshot,
				  newSnapshot: newSnapshot)
		outlineView.endUpdates()
	}

}

// MARK: - Helpers
private extension SourceList.Adapter {

	/// - Complexity: O(n)
	func updateItemContentIfNeeded(oldSnapshot: TreeSnapshot, newSnapshot: TreeSnapshot) {

		let oldSet = oldSnapshot.identifiers
		let newSet = newSnapshot.identifiers

		let intersection = newSet.intersection(oldSet)

		for identifier in intersection {
			guard
				let oldModel = oldSnapshot[identifier],
				let newModel = newSnapshot[identifier]
			else {
				continue
			}

			if
				!oldModel.isContentEqual(to: newModel),
				let item = items[oldModel.itemIdentifier]
			{
				let row = outlineView.row(forItem: item)
				configureCell(model: newModel, at: row)
			}
		}

	}

	func updateOutlineItems(oldSnapshot: TreeSnapshot, newSnapshot: TreeSnapshot) {
		let oldSet = oldSnapshot.identifiers
		let newSet = newSnapshot.identifiers

		let inserted = newSet.subtracting(oldSet)
		let removed = oldSet.subtracting(newSet)

		for toInsert in inserted {
			items[toInsert] = OutlineItem(id: toInsert)
		}

		for toRemove in removed {
			items[toRemove] = nil
		}
	}

	func forceReload(_ newSnapshot: TreeSnapshot) {
		updateOutlineItems(oldSnapshot: snapshot, newSnapshot: newSnapshot)
		snapshot = newSnapshot
		outlineView.reloadData()
	}

}
