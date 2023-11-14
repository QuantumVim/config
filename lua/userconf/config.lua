local M = {}

-- global options for all user configurations
M.strategy = "force" -- | "keep" | "ignore" | "error" // see: vim.tbl_deep_extend
-- these can override the behavior
M.plugins = {
	-- list github repos here
}
M.specs = {
	-- lazy spec
}

return M
