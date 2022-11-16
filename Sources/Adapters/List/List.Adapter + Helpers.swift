//
//  List.Adapter + Helpers.swift
//  
//
//  Created by Anton Cherkasov on 25.09.2022.
//

extension List.Adapter {

	func getRow(for identifier: (any Hashable)?) -> Int? {
		guard let identifier = identifier, let row = snapshot.getIndex(for: AnyHashable(identifier)) else {
			return nil
		}
		return row
	}
}
