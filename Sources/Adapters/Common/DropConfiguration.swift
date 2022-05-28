//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 16.06.2022.
//

import AppKit

public struct DropConfiguration<ID: Hashable> {

	public enum DropDestination {
		case dropOn(row: Int)
		case dropAbove(row: Int)
		case dropToRoot
	}

	public typealias PasteboardType = NSPasteboard.PasteboardType

	public var dropProvider: ((DropDestination, DraggingSource, [PasteboardType: [Data]]) -> Void)?

	public var canHandleDrop: ([PasteboardType], DraggingSource, DropDestination) -> Bool

	public init(canHandleDrop: @escaping ([PasteboardType], DraggingSource, DropDestination) -> Bool) {
		self.canHandleDrop = canHandleDrop
	}

}
