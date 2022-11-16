//
//  NSDraggingInfo + Extention.swift
//  
//
//  Created by Anton Cherkasov on 24.09.2022.
//

import AppKit

public extension NSDraggingInfo {

	var pasterboardItems: [NSPasteboardItem] {
		return draggingPasteboard.pasteboardItems ?? []
	}

	var types: [NSPasteboard.PasteboardType] {
		return draggingPasteboard.types ?? []
	}
}
