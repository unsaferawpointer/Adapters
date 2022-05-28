//
//  TableItemRepresentable.swift
//  
//
//  Created by Anton Cherkasov on 29.05.2022.
//

import Foundation

public protocol TableItemRepresentable: ItemIdentifiable {
	var isSelectable: Bool { get set }
	var editable: Bool { get set }
}
