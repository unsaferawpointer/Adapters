//
//  OutlineViewAdapter extension.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 09.05.2022.
//

import Foundation
import AppKit

/// Reference - type proxy of group
final class GroupProxy<GroupModel: OutlineGroupRepresentable, CellModel: OutlineItemRepresentable>: NSObject {

	var model: GroupModel
	var children: [NodeProxy<CellModel>]

	init(model: GroupModel, children: [NodeProxy<CellModel>]) {
		self.model = model
		self.children = children
	}

}

/// Reference - type proxy of node
class NodeProxy<CellModel: OutlineItemRepresentable>: NSObject {

	var model: CellModel
	var children: [NodeProxy<CellModel>]?

	init(value: CellModel, children: [NodeProxy<CellModel>]) {
		self.model = value
		self.children = children
	}

	var isFile: Bool {
		return model.isFile
	}

	var isFolder: Bool {
		return model.isFolder
	}

	func findNode(with id: CellModel.ID) -> NodeProxy? {
		if self.model.id == id {
			return self
		}
		guard let children = children else { return nil }
		for child in children {
			if let match = child.findNode(with: id) {
				return match
			}
		}
		return nil
	}

	func isAncestor(of nodeID: CellModel.ID) -> Bool {
		return findNode(with: nodeID) != nil
	}

}

extension NodeProxy {

	var id: CellModel.ID {
		return model.id
	}

}
