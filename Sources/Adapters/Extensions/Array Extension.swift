//
//  Array Extension.swift
//  Done
//
//  Created by Anton Cherkasov on 26.12.2021.
//

import Foundation
import Metal

/// Use location for moving and insertions elements in array
public enum RelativeLocation<ID: Hashable>: Hashable {
	/// Use on moving on bottom and middle of the list
	case after(_ identifier: ID)
	/// Use on moving on top and middle of the list
	case before(_ identifier: ID)
}

struct Predicate<Target> {

	var matches: (Target) -> Bool

	init(matcher: @escaping (Target) -> Bool) {
		matches = matcher
	}

	static func && (lhs: Predicate<Target>, rhs: Predicate<Target>) -> Predicate<Target> {
		Predicate { lhs.matches($0) && rhs.matches($0) }
	}

	static func || (lhs: Predicate<Target>, rhs: Predicate<Target>) -> Predicate<Target> {
		Predicate { lhs.matches($0) || rhs.matches($0) }
	}

}

extension Array {

	mutating func move(indexes: IndexSet, to toIndex: Index) {
		let movingData = indexes.map { self[$0] }
		let targetIndex = toIndex - indexes.filter { $0 < toIndex }.count
		for (offset, index) in indexes.enumerated() {
			remove(at: index - offset)
		}
		insert(contentsOf: movingData, at: targetIndex)
	}

}

extension Array {
	subscript(safeAt index: Int) -> Element? {
		guard index >= self.count else {
			return nil
		}
		return self[index]
	}
}

extension Array where Element: Identifiable {

	/// - Parameters:
	/// - identifiers: Identifiers for moving
	/// - location: Relative location
	mutating func move<ID>(_ identifiers: [ID], to location: RelativeLocation<ID>) where Element.ID == ID {
		let indexes = enumerated().reduce(into: IndexSet()) { partialResult, pair in
			let id = pair.element.id
			if identifiers.contains(id) {
				partialResult.insert(pair.offset)
			}
		}
		switch location {
			case .after(let after):
				if let index = firstIndex(where: { $0.id == after }) {
					move(indexes: indexes, to: index + 1)
				}
			case .before(let before):
				if let index = firstIndex(where: { $0.id == before }) {
					move(indexes: indexes, to: index)
				}
		}
	}
	/** - Parameters:
	 - newElements: new elements to insert
	 - location: Relative location
	 */
	mutating func insert<ID>(contentsOf newElements: [Element], at location: RelativeLocation<ID>) where Element.ID == ID {
		switch location {
			case .after(let id):
				if let index = firstIndex(where: { $0.id == id }) {
					insert(contentsOf: newElements, at: index + 1)
				}
			case .before(let id):
				if let index = firstIndex(where: { $0.id == id }) {
					insert(contentsOf: newElements, at: index)
				}
		}
	}

	mutating func remove<ID>(_ identifiers: [ID]) where Element.ID == ID {
		let hashmap = Set(identifiers)
		removeAll { hashmap.contains($0.id) }
	}

	mutating func modificate<ID, Value>(
		_ identifiers: [ID],
		keyPath: WritableKeyPath<Element, Value>,
		newValue value: Value) where Element.ID == ID {
		identifiers.compactMap { id in
			firstIndex(keyPath: \.id, equalsTo: id)
		}.forEach {
			self[$0][keyPath: keyPath] = value
		}
	}

	mutating func modificate<Value>(keyPath: WritableKeyPath<Element, Value>, newValue value: Value) {
		for index in indices {
			self[index][keyPath: keyPath] = value
		}
	}

	func firstIndex<Value: Equatable>(keyPath: KeyPath<Element, Value>, equalsTo value: Value) -> Int? {
		return firstIndex { $0[keyPath: keyPath] == value }
	}

	func count(for predicate: Predicate<Element>) -> Int {
		return filter(predicate.matches).count
	}
}
