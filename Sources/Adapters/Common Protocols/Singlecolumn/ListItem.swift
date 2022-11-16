//
//  ListItem.swift
//  
//
//  Created by Anton Cherkasov on 17.09.2022.
//
import CoreGraphics

/// Public interface for list (single column table)
public protocol ListItem: RowRepresentable {

	/// Displayed cell
	associatedtype Cell: ConfigurableCell where Cell.Model == Self

}
