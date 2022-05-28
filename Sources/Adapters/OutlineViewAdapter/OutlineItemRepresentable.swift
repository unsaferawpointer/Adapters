//
//  OutlineItemPresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 10.05.2022.
//

import AppKit

public protocol OutlineItemRepresentable: CellModel {

	var icon: String { get set }
	var tintColor: NSColor? { get set }
	var title: String { get set }
	var children: [Self]? { get set }

	var isSelectable: Bool { get set }
	var isEditable: Bool { get set }

	var badge: String { get set }

}

extension OutlineItemRepresentable {

	var isFile: Bool {
		return children == nil
	}

	var isFolder: Bool {
		return children != nil
	}

}
