//
//  RowActionSupportable.swift
//  
//
//  Created by Anton Cherkasov on 25.08.2022.
//

import AppKit

public protocol RowActionSupportable {
	var leadingActions: [NSTableViewRowAction] { get set }
	var trailingActions: [NSTableViewRowAction] { get set }
}
