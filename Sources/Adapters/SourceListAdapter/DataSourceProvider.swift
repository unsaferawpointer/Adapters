//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 28.06.2022.
//

//import AppKit
//
//final class DataSourceProvider: NSOutlineViewDataSource {
//
//	// MARK: Snapshot
//
//	var oldRootIdentifiers: [AnyHashable] = [] // Generate every time
//	var oldNodes: [Node] = [] // Generate every time
//	var oldNodesForIdentifiers: [AnyHashable: Node] = [:] // Generate every time
//
//	// Reference - type storage
//	var items: [AnyHashable: OutlineItem] = [:]
//
//	// MARK: NSOutlineViewDataSource
//
//	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
//		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
//			let id = groupModel.id
//			return oldNodesForIdentifiers[id]?.chidlrenIDs.count ?? 0
//		}
//
//		return oldRootIdentifiers.count
//	}
//
//	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
//		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
//			let id = groupModel.id
//			guard let childID = oldNodesForIdentifiers[id]?.chidlrenIDs[index] else {
//				fatalError("Cant find node with id = \(id)")
//			}
//			return items[childID]
//		}
//		let rootID = oldRootIdentifiers[index]
//		return items[rootID]
//	}
//
//	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
//		if let item = item as? OutlineItem, let groupModel = item.model as? GroupModel {
//			let id = groupModel.id
//			guard let groupNode = oldNodesForIdentifiers[id] else {
//				fatalError("Cant find node with id = \(id)")
//			}
//			return groupNode.chidlrenIDs.count > 0
//		}
//		return false
//	}
//
//}
//
//extension DataSourceProvider {
//
//	struct Node: Hashable, CustomStringConvertible {
//
//		// MARK: - Hashable
//
//		static func == (lhs: Node, rhs: Node) -> Bool {
//			return lhs.id == rhs.id
//		}
//
//		func hash(into hasher: inout Hasher) {
//			hasher.combine(id)
//		}
//
//		// MARK: Node properties
//
//		var id: AnyHashable
//
//		var indexPath: IndexPath
//
//		var parentID: AnyHashable?
//
//		var chidlrenIDs: [AnyHashable]
//
//		var model: Any
//
//		// MARK: CustomStringConvertible
//
//		var description: String {
//			return "\(id)"
//		}
//	}
//
//	class OutlineItem: NSObject {
//		var id: AnyHashable
//		var model: Any
//		init(id: AnyHashable, model: Any) {
//			self.id = id
//			self.model = model
//		}
//	}
//
//}
