//
//  SourceList + Snapshot.swift
//
//
//  Created by Anton Cherkasov on 29.10.2022.
//

import Foundation
import Collections
import os.log

struct Node {

	let id: AnyHashable
	let indexPath: IndexPath
	let children: [AnyHashable]

	init(id: AnyHashable,
		 indexPath: IndexPath,
		 children: [AnyHashable]) {
		self.id = id
		self.indexPath = indexPath
		self.children = children
	}
}

extension SourceList {

	/// Snapshot of the tree data
	public struct TreeSnapshot {

		/// All identifiers
		public var identifiers: Set<AnyHashable> = []

		public var rootIdentifiers: [AnyHashable] = []
		private var cache: [IndexPath: AnyHashable] = [:]

		private var nodes: [AnyHashable: Node] = [:]
		private var elements: [AnyHashable: any ListItem] = [:]

		/// Initialization
		///
		/// - Parameters:
		///    - items: Root items
		public init(_ items: [TreeNode<any ListItem>]) {
			reload(items)
		}

		public init() { }

	}
}

// MARK: - Helpers
extension SourceList.TreeSnapshot {

	mutating func reload(_ newItems: [TreeNode<any ListItem>]) {
		for (offset, item) in newItems.enumerated() {
			let origin = IndexPath(index: offset)
			rootIdentifiers.append(item.value.itemIdentifier)
			item.enumerateNodes(origin: origin) { treeNode, indexPath in
				let children = treeNode.children.map(\.value.itemIdentifier)
				let node = Node(id: treeNode.value.itemIdentifier, indexPath: indexPath, children: children)
				nodes[treeNode.value.itemIdentifier] = node
				elements[treeNode.value.itemIdentifier] = treeNode.value
				cache[indexPath] = treeNode.value.itemIdentifier
				let (insert, _) = identifiers.insert(treeNode.value.itemIdentifier)
				if !insert {
					os_log(.debug, "WARNING! Elements have the same identifier = \(treeNode.value.itemIdentifier)")
				}
			}
		}
	}

}

public extension SourceList.TreeSnapshot {

	var isEmpty: Bool {
		return nodes.isEmpty
	}

	func childrenCount(for parent: AnyHashable?) -> Int {
		guard let identifier = parent else {
			return rootIdentifiers.count
		}
		guard let node = nodes[identifier] else {
			return 0
		}
		return node.children.count
	}

	func childIdentifier(in parent: AnyHashable?, at index: Int) -> AnyHashable? {
		guard let identifier = parent else {
			return rootIdentifiers[index]
		}
		return nodes[identifier]?.children[index]
	}

	func childrenIdentifiers(_ identifier: AnyHashable?) -> [AnyHashable] {
		guard let parent = identifier else {
			return rootIdentifiers
		}
		return nodes[parent]?.children ?? []
	}

	func identifier(atIndexPath indexPath: IndexPath) -> AnyHashable? {
		return cache[indexPath]
	}

	func indexPath(forIdentifier identifier: AnyHashable) -> IndexPath? {
		return nodes[identifier]?.indexPath
	}

	func relativeLocation(in parent: AnyHashable?, at index: Int) -> RelativeLocation<AnyHashable> {
		let children = childrenIdentifiers(parent)
		precondition(children.count > 0, "Cant get relative location when collection is empty")
		if index > 0 {
			let id = children[index - 1]
			return .after(id)
		}

		let id = children[index]
		return .before(id)
	}

	func isGroup(identifier: (some Hashable)) -> Bool {
		return elements[identifier]?.isGroup ?? false
	}

	func index(identifier: (some Hashable)) -> SourceList.DropConfiguration.Index? {
		guard let indexPath = indexPath(forIdentifier: identifier) else {
			return nil
		}
		return .init(id: identifier, indexPath: indexPath)
	}

	mutating func forceUpdate(_ element: any ListItem) {
		elements[element.itemIdentifier] = element
	}

}

// MARK: - Subscripts
public extension SourceList.TreeSnapshot {

	subscript(index: Int) -> (any ListItem)? {
		return self[IndexPath(index: index)]
	}

	/// Returns element by index path
	///
	/// - Parameters:
	///    - indexPath: Index path of the item
	/// - Complexity: O(1)
	/// - Note: First value of the index path is index of root item
	subscript(indexPath: IndexPath) -> (any ListItem)? {
		guard let identifier = cache[indexPath] else {
			return nil
		}
		return elements[identifier]
	}

	/// Returns element by index path
	///
	/// - Parameters:
	///    - identifier: Identifier of the element
	/// - Complexity: O(1)
	subscript(identifier: AnyHashable) -> (any ListItem)? {
		return elements[identifier]
	}
}
