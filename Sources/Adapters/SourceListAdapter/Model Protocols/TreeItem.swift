//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 26.06.2022.
//

public struct TreeItem<ItemModel> {

	public var viewModel: ItemModel

	public init(viewModel: ItemModel) {
		self.viewModel = viewModel
	}
}
