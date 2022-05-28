//
//  DragAndDropSupportable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 14.05.2022.
//

import AppKit

enum DropOperation {
	case dropOn
	case dropIn
}

protocol DropSupportable where Self: ItemIdentifiable {
	/// Can handle drop on item
	func canHandle(operation: DropOperation, pasterboardType: NSPasteboard.PasteboardType) -> Bool
}
