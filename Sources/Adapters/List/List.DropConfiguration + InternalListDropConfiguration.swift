//
//  ListView.DropConfiguration + InternalListDropConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 24.09.2022.
//

import AppKit

public protocol InternalListDropConfiguration {

	var availableTypes: [NSPasteboard.PasteboardType] { get }

	func canHandleInsert<S: Sequence>(info: S, destination: Int) -> Bool where S.Element == DragInfo

	func handleInsert(info: DragInfo, destination: Int, data: [Data])

	func canHandleDropOn<S: Sequence>(info: S) -> Bool where S.Element == DragInfo

	func handleDropOn(info: DragInfo, data: [Data])

	func canHandleDropInto<S: Sequence>(info: S, destination: Int) -> Bool where S.Element == DragInfo

	func handleDropInto(info: DragInfo, destination: Int, data: [Data])

	func validateMoving(_ indexes: IndexSet, destination: Int) -> Bool

	func handleMoving(_ indexes: IndexSet, destination: Int)

	func canHandleCopy() -> Bool

	func handleCopy(_ indexes: IndexSet, destination: Int)

	func canHandleDelete() -> Bool

	func handleDelete(_ indexes: IndexSet)

	func canHandleMove() -> Bool
}

// MARK: - Internal interface
extension List.DropConfiguration: InternalListDropConfiguration {

	public var availableTypes: [NSPasteboard.PasteboardType] {
		return insertMap.keys.map(\.type) + dropOnMap.keys.map(\.type) + dropIntoMap.keys.map(\.type)
	}

	public func canHandleInsert<S: Sequence>(info: S, destination: Int) -> Bool where S.Element == DragInfo {
		for item in info where insertMap.keys.contains(item) {
			return insertMap[item]?.validation?(destination) ?? true
		}
		return false
	}

	public func handleInsert(info: DragInfo, destination: Int, data: [Data]) {
		guard let insertAction = insertMap[info] else {
			return
		}
		insertAction.action(destination, data)
	}

	public func canHandleDropOn<S: Sequence>(info: S) -> Bool where S.Element == DragInfo {
		for item in info where dropOnMap.keys.contains(item) {
			return dropOnMap[item]?.validation?() ?? true
		}
		return false
	}

	public func handleDropOn(info: DragInfo, data: [Data]) {
		guard let dropOnAction = dropOnMap[info] else {
			return
		}
		dropOnAction.action(data)
	}

	public func canHandleDropInto<S: Sequence>(info: S, destination: Int) -> Bool where S.Element == DragInfo {
		for item in info where dropIntoMap.keys.contains(item) {
			return dropIntoMap[item]?.validation?(destination) ?? true
		}
		return false
	}

	public func handleDropInto(info: DragInfo, destination: Int, data: [Data]) {
		guard let dropIntoAction = dropIntoMap[info] else {
			return
		}
		dropIntoAction.action(destination, data)
	}

	public func validateMoving(_ indexes: IndexSet, destination: Int) -> Bool {
		guard moveAction?.validation?(indexes, destination) ?? true else {
			return false
		}
		return true
	}

	public func handleMoving(_ indexes: IndexSet, destination: Int) {
		guard let action = moveAction?.action else {
			return
		}
		action(indexes, destination)
	}

	public func canHandleCopy() -> Bool {
		return copyAction != nil
	}

	public func handleCopy(_ indexes: IndexSet, destination: Int) {
		guard let action = copyAction?.action else {
			return
		}
		action(indexes, destination)
	}

	public func canHandleDelete() -> Bool {
		return deleteAction != nil
	}

	public func handleDelete(_ indexes: IndexSet) {
		guard let action = deleteAction?.action else {
			return
		}
		action(indexes)
	}

	public func canHandleMove() -> Bool {
		return moveAction != nil
	}
}
