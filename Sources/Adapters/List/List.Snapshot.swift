//
//  ListView.Snapshot.swift
//  
//
//  Created by Anton Cherkasov on 24.08.2022.
//

import Foundation

public extension List {

	/// Snapshot of the list data
	struct Snapshot {

		private (set) var items: [any ListItem] = [] {
			didSet {
				updateCache()
			}
		}

		/// Cache to fast look up the index of  an element with a specific identifier
		private var cache: [AnyHashable: Int] = [:]

		// MARK: - Initialization

		/// Initialization
		///
		/// - Parameters:
		///    - items: Any items
		public init(items: [any ListItem]) {
			self.items = items
			updateCache()
		}

		/// Initialization
		/// 
		/// - Returns: Empty snapshot
		public init() {
			self.items = []
			updateCache()
		}

	}
}

// MARK: - Helpers
private extension List.Snapshot {

	mutating func updateCache() {
		cache.removeAll()
		for index in items.indices {
			let key = items[index].itemIdentifier
			cache[key] = index
		}
	}
}


// MARK: - Helpers
extension List.Snapshot {

	mutating func move(indexes: IndexSet, to destination: Int) {
		items.move(indexes: indexes, to: destination)
	}

}

// MARK: - Public subscripts
public extension List.Snapshot {

	/// - Parameters:
	///    - index: Item index
	/// - Returns: Item with specific index
	/// - Complexity: O(1)
	subscript(index: Int) -> any ListItem {
		return items[index]
	}

	/// - Parameters:
	///    - id: Item identifier
	/// - Returns: Item with specific identifier
	/// - Complexity: O(1)
	subscript(id: AnyHashable) -> (any ListItem)? {
		guard let index = cache[id] else {
			return nil
		}
		return items[index]
	}

}

// MARK: - Public computed fields
public extension List.Snapshot {

	/// Snapshot is empty
	var isEmpty: Bool {
		return items.isEmpty
	}

	/// Count of the items in the snapshot
	var count: Int {
		return items.count
	}

	/// All type-erasured IDs
	var identifiers: [AnyHashable] {
		return items.map { $0.itemIdentifier }
	}

}

// MARK: - Public methods
public extension List.Snapshot {

	/// Returns index for specific id
	///  - Complexity: O(1)
	func getIndex(for id: AnyHashable?) -> Int? {
		guard let id = id else {
			return nil
		}
		return cache[id]
	}

	/// Returns IndexPaths for identifiers
	///
	/// - Complexity: O(n), where `n` is number of identifiers
	func getIndexes(for ids: [AnyHashable]) -> IndexSet {
		let indexes = ids.compactMap { id in
			cache[id]
		}
		return IndexSet(indexes)
	}
}

// MARK: - CustomStringConvertible
extension List.Snapshot: CustomStringConvertible {

	public var description: String {
		return items.map{  String(describing: $0) }.joined(separator: "\n")
	}
}
