//
//  List.DropConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 05.09.2022.
//

import AppKit

public extension List {

	struct DropConfiguration {

		var dropOnMap: [DragInfo: DropOnAction] = [:]

		var dropIntoMap: [DragInfo: DropIntoAction] = [:]

		var insertMap: [DragInfo: InsertAction] = [:]

		var copyAction: CopyAction?

		var deleteAction: DeleteAction?

		var moveAction: MoveAction?

		public init() { }

	}
}

// MARK: - Nested data structs
extension List.DropConfiguration {

	struct DropOnAction {
		var action: ([Data]) -> Void
		var validation: (() -> Bool)?
	}

	struct DropIntoAction {
		var action: (Int, [Data]) -> Void
		var validation: ((Int) -> Bool)?
	}

	struct InsertAction {
		var action: (Int, [Data]) -> Void
		var validation: ((Int) -> Bool)?
	}

	struct CopyAction {
		var action: (IndexSet, Int) -> Void
		var validation: ((IndexSet, Int) -> Bool)?
	}

	struct DeleteAction {
		var action: (IndexSet) -> Void
		var validation: ((IndexSet) -> Bool)?
	}

	struct MoveAction {
		var action: (IndexSet, Int) -> Void
		var validation: ((IndexSet, Int) -> Bool)?
	}
}
