//
//  OutlineItemPresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 10.05.2022.
//

import AppKit

/// Pasterboard configuration for item
public struct PasterboardConfiguration {

	public typealias PasteboardType = NSPasteboard.PasteboardType

	/// Dictionary where `key` is pasterboard type and `value` is drag operation.
	public var acceptedDropTypes: [PasteboardType: NSDragOperation] = [:]

	public init() { }

	public init(acceptedDropTypes: [PasteboardType: NSDragOperation]) {
		self.acceptedDropTypes = acceptedDropTypes
	}

}

public struct OutlineItemConfiguration: Hashable {

	public var tintColor: NSColor?

	/// The ability to be selected
	public var isSelectable: Bool

	public var isEditable: Bool

	/// The ability to reorder using drag and drop
	public var isReorderable: Bool

	public init(tintColor: NSColor? = nil,
				isSelectable: Bool,
				isEditable: Bool,
				isReorderable: Bool = false) {
		self.tintColor = tintColor
		self.isSelectable = isSelectable
		self.isEditable = isEditable
		self.isReorderable = isReorderable
	}

}

public protocol OutlineItemRepresentable: ItemIdentifiable {

	var configuration: OutlineItemConfiguration { get set }

	var children: [Self]? { get set }

	var itemDidSelected: (() -> Void)? { get set }

	var itemDidEdited: ((Self) -> Void)? { get set }

}

extension OutlineItemRepresentable {

	var isFile: Bool {
		return children == nil
	}

	var isFolder: Bool {
		return children != nil
	}

}
