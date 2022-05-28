//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 16.06.2022.
//

import Foundation
import AppKit

public struct DropConfiguration<ID: Hashable> {

	public typealias PasteboardType = NSPasteboard.PasteboardType

	public var dropOnProvider: ((ID, [PasteboardType: [Data]], DraggingSource) -> Void)?
	public var dropInProvider: ((RelativeLocation<ID>, [PasteboardType: [Data]], DraggingSource) -> Void)?
	public var dropToRoot: (([PasteboardType: [Data]], DraggingSource) -> Void)?

	public var canHandleDrop: ([PasteboardType], DraggingSource, DropOperation) -> Bool

	public init(canHandleDrop: @escaping ([PasteboardType], DraggingSource, DropOperation) -> Bool) {
		self.canHandleDrop = canHandleDrop
	}

}
