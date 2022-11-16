//
//  SourceList + Index.swift
//  
//
//  Created by Anton Cherkasov on 13.11.2022.
//

import Foundation

extension SourceList {

	/// The index of the sourcelist item
	public struct Index: Hashable {

		/// Identifier of the item
		public let id: AnyHashable

		/// IndexPath of the item
		public let indexPath: IndexPath

		/// Basic initialization
		///
		/// - Parameters:
		///    - id: Type-erasured identifier of the item
		///    - indexPath: IndexPath of the item
		public init(id: AnyHashable, indexPath: IndexPath) {
			self.id = id
			self.indexPath = indexPath
		}
	}
}
