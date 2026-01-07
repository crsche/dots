return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				nil_ls = {
					enabled = true,
				},
				nixd = {
					enabled = true,
					settings = {
						nixd = {
							options = {
								nixos_vps = {
									expr = '(builtins.getFlake (builtins.toString ./.)).nixosConfigurations."vps".options',
								},
								darwin_macbook = {
									expr = '(builtins.getFlake (builtins.toString ./.)).darwinConfigurations."macbook".options',
								},
								home_manager_macbook = {
									expr = '(builtins.getFlake (builtins.toString ./.)).darwinConfigurations."macbook".options.home-manager.users.type.getSubOptions []',
								},
							},
						},
					},
				},
			},
		},
	},
}
