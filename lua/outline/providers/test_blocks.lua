local ts = vim.treesitter
local is_ancestor = ts.is_ancestor or require("outline.utils").is_ancestor

local M = {
	name = "test_blocks",
}

M.query = "(function_call) @call"

---@class test_blocks.Config
---
---Which test blocks to enable
---Default: { describe = true, it = true }
---@field enable? table<string, boolean>
---
---Whether to activate test_blocks provider for this buffer
---Default: any file ending with `_spec.lua`
---@field supports_buffer? function(bufnr: integer): boolean
---
---Max number of nested nodes to show in the outline
---Default: 5
---@field max_depth? integer
---
---Attempts to resize the outline sidebar for this provider
---Default: uses the global outline.nvim config
---@field sidebar_width? integer

---@type test_blocks.Config
M.defaults = {
	enable = { describe = true, it = true },
	max_depth = 5,
}

local function strip_tsnode(node)
	node.tsnode = nil
	for _, c in ipairs(node.children or {}) do
		strip_tsnode(c)
	end
end

local function prune(node, depth, max_depth)
	if depth >= max_depth then
		node.children = {}
		return
	end
	for _, c in ipairs(node.children) do
		prune(c, depth + 1, max_depth)
	end
end

--- Decide whether to activate on this buffer.
--- default to *_spec.lua.
---@param bufnr integer
---@param opts? test_blocks.Config
function M.supports_buffer(bufnr, opts)
	opts = opts or {}

	if type(opts.supports_buffer) == "function" then
		if not opts.supports_buffer(bufnr) then
			return false
		end
	else
		local fname = vim.api.nvim_buf_get_name(bufnr):match("^.+/(.+)$")
		if not fname or not fname:match("_spec%.lua$") then
			return false
		end
	end

	local ok, parser = pcall(ts.get_parser, bufnr, "lua")
	if not ok or not parser then
		return false
	end

	M.parser = parser

	M.config = {
		enable = opts.enable or M.defaults.enable,
		max_depth = opts.max_depth or M.defaults.max_depth,
		sidebar_width = opts.sidebar_width,
	}

	if not M.query_obj then
		M.query_obj = ts.query.parse("lua", M.query)
	end

	return true
end

--- build and return the outline symbols.
function M.request_symbols(callback, opts)
	local bufnr = (opts and opts.bufnr) or 0
	if not M.parser then
		return callback(nil, opts)
	end

	local tree = M.parser:parse()[1]
	if not tree then
		return callback(nil, opts)
	end
	local root = tree:root()

	local query = M.query_obj
	local sym_root = { children = {}, tsnode = root }
	local stack = { sym_root }

	-- all function_call nodes
	for _, call_node in query:iter_captures(root, bufnr, 0) do
		local name_field = call_node:field("name")[1]
		if name_field then
			local fn = ts.get_node_text(name_field, bufnr)

			if M.config.enable[fn] then
				-- selectionRange from name field
				local ns_r1, ns_c1, ns_r2, ns_c2 = name_field:range()

				-- range start from call node
				local r1, c1 = call_node:range()

				-- end of block (function_definition)
				local end_r, end_c
				local args = call_node:field("arguments")[1]
				if args then
					for i = 0, args:child_count() - 1 do
						local c = args:child(i)
						if c and c:type() == "function_definition" then
							local _, _, fr, fc = c:range()
							end_r, end_c = fr, fc
							break
						end
					end
				end

				if not end_r then
					_, _, end_r, end_c = call_node:range()
				end

				-- first string argument for label
				local raw = ""
				if args then
					for i = 0, args:child_count() - 1 do
						local c = args:child(i)
						if c and c:type() == "string" then
							raw = ts.get_node_text(c, bufnr)
							break
						end
					end
				end

				local sym = {
					kind = 12,
					name = fn .. "(" .. raw .. ")",
					tsnode = call_node,
					selectionRange = {
						start = { line = ns_r1, character = ns_c1 },
						["end"] = { line = ns_r2, character = ns_c2 },
					},
					range = { start = { line = r1, character = c1 }, ["end"] = { line = end_r, character = end_c } },
					children = {},
				}

				while #stack > 0 and not is_ancestor(stack[#stack].tsnode, call_node) do
					table.remove(stack)
				end
				table.insert(stack[#stack].children, sym)
				table.insert(stack, sym)
			end
		end
	end

	-- prune stuff deeper than max_depth and strip internals
	prune(sym_root, 1, M.config.max_depth)
	strip_tsnode(sym_root)

	if M.config.sidebar_width then
		local total_cols = vim.o.columns
		local sidebar_pct = M.config.sidebar_width / 100
		local sidebar_cols = math.floor(total_cols * sidebar_pct)
		local main_cols = total_cols - sidebar_cols
		vim.schedule(function()
			local win = require("outline")._get_sidebar(false).code.win
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_width(win, main_cols)
			end
		end)
	end

	callback(sym_root.children, opts)
end

return M
