//
//  SourceList + DropDestination.swift
//  
//
//  Created by Anton Cherkasov on 04.11.2022.
//

import Foundation

public extension SourceList {

	enum DropDestination {
		/// Drop on item
		case dropOn(index: Index?)
		/// Drop at specific offset into item
		case dropInto(target: Index?, offset: Int)
	}

}

extension SourceList.DropDestination {

	/// IndexPath of the drop destination
	public var indexPath: IndexPath {
		switch self {
			case .dropOn(let target), .dropInto(let target, _):
				return target?.indexPath ?? .empty
		}
	}

	public var id: AnyHashable? {
		switch self {
			case .dropOn(let target), .dropInto(let target, _):
				return target?.id
		}
	}
}
