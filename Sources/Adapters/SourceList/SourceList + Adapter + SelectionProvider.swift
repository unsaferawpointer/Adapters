//
//  SourceList + Adapter + SelectionProvider.swift
//  
//
//  Created by Anton Cherkasov on 04.11.2022.
//

import Foundation

/// Public interface of the selection provider
public protocol SourceListSelectionProvider {
	typealias Index = SourceList.Index
	func onSelect(action: @escaping ([Index]) -> Void, validate: (([Index]) -> Bool)?) -> Self
}

public extension SourceList {

	final class SelectionProvider {

		public typealias Index = SourceList.Index

		private var action: ([Index]) -> Void
		private var validation: (([Index]) -> Bool)?

		public init(action: @escaping ([Index]) -> Void, validate: (([Index]) -> Bool)? = nil) {
			self.action = action
			self.validation = validate
		}
	}
}

// MARK: - Internal methods
extension SourceList.SelectionProvider {

	func select<S: Sequence>(_ indexes: S) where S.Element == Index {
		action(Array(indexes))
	}

	func validate<S: Sequence>(selection: S) -> Bool where S.Element == Index {
		return validation?(Array(selection)) ?? true
	}
}

extension SourceList.SelectionProvider {

	@discardableResult
	func onSelect(action: @escaping ([Index]) -> Void, validate: (([Index]) -> Bool)? = nil) -> Self {
		self.action = action
		self.validation = validate
		return self
	}
}
