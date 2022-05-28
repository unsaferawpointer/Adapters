//
//  OutlineViewAdapter extension.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 09.05.2022.
//

import Foundation

/// Reference - type proxy of group
final class GroupProxy<GroupModel: OutlineGroupPresentable, CellModel: OutlineItemRepresentable> {

	var model: GroupModel
	var children: [NodeProxy<CellModel>]

	init(model: GroupModel, children: [NodeProxy<CellModel>]) {
		self.model = model
		self.children = children
	}

}

/// Reference - type proxy of node
class NodeProxy<Model: OutlineItemRepresentable> {

	var model: Model
	var children: [NodeProxy]?

	init(value: Model, children: [NodeProxy]) {
		self.model = value
		self.children = children
	}

	var isFile: Bool {
		return model.isFile
	}

	var isFolder: Bool {
		return model.isFolder
	}

	func findNode(with id: Model.ID) -> NodeProxy? {
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

	func isAncestor(of nodeID: Model.ID) -> Bool {
		return findNode(with: nodeID) != nil
	}

}
