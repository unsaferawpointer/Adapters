//
//  ListView.DropConfiguration + ListDropConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 24.09.2022.
//

import AppKit

public protocol ListDropConfiguration {

	@discardableResult
	func onDrop(of type: NSPasteboard.PasteboardType,
				from source: DragInfo.Source,
				handler: @escaping ([Data]) -> Void,
				validate: (() -> Bool)?) -> Self

	@discardableResult
	func onInsert(of type: NSPasteboard.PasteboardType,
				  from source: DragInfo.Source,
				  handler: @escaping (Int, [Data]) -> Void,
				  validate: ((Int) -> Bool)?) -> Self

	@discardableResult
	func onDropInto(of type: NSPasteboard.PasteboardType,
					from source: DragInfo.Source,
					handler: @escaping (Int, [Data]) -> Void,
					validate: ((Int) -> Bool)?) -> Self

	@discardableResult
	func onDelete(action: @escaping (IndexSet) -> Void,
				  validate: ((IndexSet) -> Bool)?) -> Self

	@discardableResult
	func onCopy(action: @escaping (IndexSet, Int) -> Void,
				validate: ((IndexSet, Int) -> Bool)?) -> Self

	@discardableResult
	func onMove(action: @escaping (IndexSet, Int) -> Void,
				validate: ((IndexSet, Int) -> Bool)?) -> Self

}

// MARK: - Public interface
extension List.DropConfiguration: ListDropConfiguration {

	@discardableResult
	public func onDrop(of type: NSPasteboard.PasteboardType,
					   from source: DragInfo.Source,
					   handler: @escaping ([Data]) -> Void,
					   validate: (() -> Bool)? = nil) -> Self {
		var copied = self
		let info = DragInfo(type: type, source: source)
		let action = DropOnAction(action: handler, validation: validate)
		copied.dropOnMap[info] = action
		return copied
	}

	@discardableResult
	public func onInsert(of type: NSPasteboard.PasteboardType,
						 from source: DragInfo.Source,
						 handler: @escaping (Int, [Data]) -> Void,
						 validate: ((Int) -> Bool)? = nil) -> Self {
		var copied = self
		let info = DragInfo(type: type, source: source)
		let action = InsertAction(action: handler, validation: validate)
		copied.insertMap[info] = action
		return copied
	}

	@discardableResult
	public func onDropInto(of type: NSPasteboard.PasteboardType,
						   from source: DragInfo.Source,
						   handler: @escaping (Int, [Data]) -> Void,
						   validate: ((Int) -> Bool)? = nil) -> Self {
		var copied = self
		let info = DragInfo(type: type, source: source)
		let action = DropIntoAction(action: handler, validation: validate)
		copied.dropIntoMap[info] = action
		return copied
	}

	@discardableResult
	public func onDelete(action: @escaping (IndexSet) -> Void,
						 validate: ((IndexSet) -> Bool)? = nil) -> Self {
		var copied = self
		let action = DeleteAction(action: action, validation: validate)
		copied.deleteAction = action
		return copied
	}

	@discardableResult
	public func onCopy(action: @escaping (IndexSet, Int) -> Void,
					   validate: ((IndexSet, Int) -> Bool)? = nil) -> Self {
		var copied = self
		let action = CopyAction(action: action, validation: validate)
		copied.copyAction = action
		return copied
	}

	@discardableResult
	public func onMove(action: @escaping (IndexSet, Int) -> Void,
					   validate: ((IndexSet, Int) -> Bool)? = nil) -> Self {
		var copied = self
		let action = MoveAction(action: action, validation: validate)
		copied.moveAction = action
		return copied
	}

}
