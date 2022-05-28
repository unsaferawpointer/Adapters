//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 04.06.2022.
//

import AppKit

/// Reference - type proxy for drag support
final class PasterboardWriter: NSObject {

	var model: DragSupportable

	init(model: DragSupportable) {
		self.model = model
		super.init()
	}

}

// MARK: NSPasteboardWriting

//extension PasterboardWriter: NSPasteboardWriting {
//
//	func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
//		return model.availableTypes.map { $0 }
//	}
//
//	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
//		return model.propertyList(for: type)
//	}
//
//}
