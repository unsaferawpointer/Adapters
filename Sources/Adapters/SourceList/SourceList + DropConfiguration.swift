//
//  SourceList + DropConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 04.11.2022.
//


import AppKit

public extension SourceList {

	final class DropConfiguration {

		public typealias Index = SourceList.Index

		var dropAction: DropAction = .init()

		var insertAction: InsertAction = .init()

		var copyAction: CopyAction?

		var deleteAction: DeleteAction?

		var moveAction: MoveAction?

		public init() { }

	}
}

public extension SourceList.DropConfiguration {

	@discardableResult
	func onDrop(of type: NSPasteboard.PasteboardType,
				from source: DragInfo.Source,
				action: @escaping (Index?, [Data]) -> Void,
				validate: ((Index?) -> Bool)? = nil) -> Self {
		let info = DragInfo(type: type, source: source)
		self.dropAction.actionMap[info] = action
		self.dropAction.validationMap[info] = validate
		return self
	}

	@discardableResult
	func onInsert(of type: NSPasteboard.PasteboardType,
				  from source: DragInfo.Source,
				  action: @escaping (Index?, Int, [Data]) -> Void,
				  validate: ((Index?, Int) -> Bool)? = nil) -> Self {
		let info = DragInfo(type: type, source: source)
		self.insertAction.actionMap[info] = action
		self.insertAction.validationMap[info] = validate
		return self
	}

	@discardableResult
	func onDelete(action: @escaping ([Index]) -> Void,
				  validate: (([Index]) -> Bool)? = nil) -> Self {
		self.deleteAction = DeleteAction(action: action, validation: validate)
		return self
	}

	@discardableResult
	func onCopy(action: @escaping ([Index], SourceList.DropDestination) -> Void,
				validate: (([Index], SourceList.DropDestination) -> Bool)? = nil) -> Self {
		self.copyAction = CopyAction(action: action, validation: validate)
		return self
	}

	@discardableResult
	func onMove(action: @escaping ([Index], SourceList.DropDestination) -> Void,
				validate: (([Index], SourceList.DropDestination) -> Bool)? = nil) -> Self {
		self.moveAction = MoveAction(action: action, validation: validate)
		return self
	}

}

extension SourceList.DropConfiguration {

	func canHandleInsert<S: Sequence>(info: S, to destination: Index?, offset: Int) -> Bool where S.Element == DragInfo {
		for item in info {
			if insertAction.actionMap.keys.contains(item) && insertAction.validationMap[item]?(destination, offset) ?? true {
				return true
			}
		}
		return false
	}

	func handleInsert(info: DragInfo, to destination: Index?, offset: Int, data: [Data]) {
		guard let action = insertAction.actionMap[info] else {
			return
		}
		action(destination, offset, data)
	}

	func canHandleDrop<S: Sequence>(info: S, to destination: Index?) -> Bool where S.Element == DragInfo {
		for item in info {
			if dropAction.actionMap.keys.contains(item) && dropAction.validationMap[item]?(destination) ?? true {
				return true
			}
		}
		return false
	}

	func handleDrop(info: DragInfo, to destination: Index?, data: [Data]) {
		guard let action = dropAction.actionMap[info] else {
			return
		}
		action(destination, data)
	}

	func handleDelete(_ indexes: [Index]) {
		guard let action = deleteAction?.action else {
			return
		}
		action(indexes)
	}

	func copyIsEnable() -> Bool {
		return copyAction != nil
	}

	func deleteIsEnable() -> Bool {
		return deleteAction != nil
	}

	func draggedTypes() -> [NSPasteboard.PasteboardType] {
		return dropAction.actionMap.keys.map(\.type) + insertAction.actionMap.keys.map(\.type)
	}

	func moveIsAvailable(for indexes: [Index], to destination: SourceList.DropDestination) -> Bool {
		guard let moveAction = moveAction else {
			return false
		}
		return moveAction.validation?(indexes, destination) ?? true
	}
}

extension SourceList.DropConfiguration {

	struct CopyAction {
		var action: ([Index], SourceList.DropDestination) -> Void
		var validation: (([Index], SourceList.DropDestination) -> Bool)?
	}

	struct DeleteAction {
		var action: ([Index]) -> Void
		var validation: (([Index]) -> Bool)?
	}

	struct MoveAction {
		var action: ([Index], SourceList.DropDestination) -> Void
		var validation: (([Index], SourceList.DropDestination) -> Bool)?
	}

	struct InsertAction {
		var actionMap: [DragInfo: (Index?, Int, [Data]) -> Void] = [:]
		var validationMap: [DragInfo: (Index?, Int) -> Bool] = [:]
	}

	struct DropAction {
		var actionMap: [DragInfo: (Index?, [Data]) -> Void] = [:]
		var validationMap: [DragInfo: (Index?) -> Bool] = [:]
	}
}
