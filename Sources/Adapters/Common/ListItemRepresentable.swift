//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 19.06.2022.
//

import Foundation

public protocol ListItemRepresentable: ItemIdentifiable {

	associatedtype Cell: CellRepresentable where Cell.ViewModel == Self

	var userIdentifier: String { get }

	var cellType: Cell.Type { get set }

	var isSelectable: Bool { get set }

	var isEditable: Bool { get set }

}
