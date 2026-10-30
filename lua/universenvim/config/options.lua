vim.g.autoformat = true
vim.g.markdown_recommended_style = 0

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0

local options = {
	autowrite = true, -- Enable auto write
	backup = false, -- Creates a backup file
	clipboard = "unnamedplus", -- Allows neovim to access the system clipboard
	cmdheight = 2, -- More space in the neovim command line for displaying messages
	completeopt = "menu,menuone,noselect", -- Mostly just for cmp
	conceallevel = 0, -- So that `` is visible in markdown files
	fileencoding = "utf-8", -- The encoding written to a file
	hlsearch = true, -- Highlight all matches on previous search pattern
	ignorecase = true, -- Ignore case in search patterns
	mouse = "a", -- Allow the mouse to be used in neovim
	pumheight = 10, -- Pop up menu height
	showmode = false, -- We don't need to see things like -- INSERT -- anymore
	showtabline = 2, -- Always show tabs
	smartcase = true, -- Smart case
	smartindent = true, -- Make indenting smarter again
	splitbelow = true, -- Force all horizontal splits to go below current window
	splitright = true, -- Force all vertical splits to go to the right of current window
	swapfile = false, -- Creates a swapfile
	termguicolors = true, -- Set term gui colors (most terminals support this)
	timeoutlen = 100, -- Time to wait for a mapped sequence to complete (in milliseconds)
	undofile = true, -- Enable persistent undo
	updatetime = 300, -- Faster completion (4000ms default)
	writebackup = false, -- If a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
	expandtab = true, -- Convert tabs to spaces
	shiftwidth = 2, -- The number of spaces inserted for each indentation
	tabstop = 2, -- Insert 2 spaces for a tab
	cursorline = false, -- Highlight the current line
	number = true, -- Set numbered lines
	relativenumber = true, -- Set relative numbered lines
	numberwidth = 4, -- Set number column width to 2 {default 4}
	signcolumn = "yes", -- Always show the sign column, otherwise it would shift the text each time
	wrap = false, -- Display lines as one long line
	scrolloff = 8, -- Is one of my fav
	sidescrolloff = 8,
	guifont = "monospace:h17", -- The font used in graphical neovim applications
}

vim.opt.shortmess:append("c")

if vim.fn.has("nvim-0.10") == 1 then
	vim.opt.smoothscroll = true
	vim.opt.foldmethod = "expr"
	vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.opt.foldtext = ""
	vim.opt.foldlevel = 99
	vim.opt.foldlevelstart = 99
else
	vim.opt.foldmethod = "indent"
	vim.opt.foldlevel = 99
	vim.opt.foldlevelstart = 99
end

for k, v in pairs(options) do
	vim.opt[k] = v
end

vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[autocmd FileType * setlocal formatoptions-=cro]])

vim.loader.enable()
