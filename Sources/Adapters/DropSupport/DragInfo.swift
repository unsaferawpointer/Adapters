//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 06.09.2022.
//

import AppKit

public struct DragInfo: Hashable {

	let type: NSPasteboard.PasteboardType
	let source: Source
}

public extension DragInfo {

	enum Source {
		/// Destination view equals source view
		case local
		/// Destination app equals source app
		case `internal`
		/// Source is external application
		case external
	}
}
