//
//  DragAndDropSupportable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 14.05.2022.
//

import AppKit

public enum DropOperation: Hashable {

	case dropOn
	case dropAbove

}

public protocol DropSupportable {

	/// Can handle drop on item
	func canHandle(operation: DropOperation,
				   from source: DraggingSource,
				   with pasterboardType: NSPasteboard.PasteboardType) -> NSDragOperation

}
