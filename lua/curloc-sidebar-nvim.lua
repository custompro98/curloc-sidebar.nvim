local devicons = require("nvim-web-devicons")
local ts_utils = require( "nvim-treesitter.ts_utils")
local Loclist = require("sidebar-nvim.components.loclist")
local sidebar = require("sidebar-nvim")

local icon = devicons.get_icon("", vim.bo.filetype, {})

local methodNeedles = { "name", "identifier" }
local classNeedles = { "name", "identifier" }

local loclist = Loclist:new({
    groups = {
      class = {
        order = 1,
      },
      method = {
        order = 2,
      },
    },
    show_location = false,
    ommit_single_group = true,
    highlights = {
      group = "SidebarNvimCurrentNodeKeyword",
      item_text = "SidebarNvimCurrentNodeValue",
    },
})

-- get_node_name tries to find the name field of the node, otherwise falls back to the next
local function get_node_name(node, needles)
  if not node then
    return "<no match found>"
  end

  local children = ts_utils.get_named_children(node)

  for _, child in ipairs(children) do
    for _, needle in ipairs(needles) do
      if child:type():find(needle) then
        node = child
        break
      end
    end
  end

  -- gsub out any spaces or brackets at the end
  return ts_utils.get_node_text(node, vim.api.nvim_get_current_buf())[1]:gsub("%s*[%[%(%{]*%s*$", "")
end

local function get_current_node()
  return ts_utils.get_node_at_cursor(vim.api.nvim_get_current_win())
end

local function get_current_match(node, rgxs)
  if not node then
    return nil
  end

  local found = false
  local target = node

  while target do
    for _, rgx in ipairs(rgxs) do
      if target and target:type():find(rgx) then
        found = true
        break
      end
    end

    if found then break end

    target = target:parent()
  end

  return found and target or nil
end

local function update()
  loclist:clear()

  local cur_node = get_current_node()

  local classNode = get_current_match(cur_node, { "class_declaration" })
  local methodNode = get_current_match(cur_node, { "method", "function" })

  local class_name = get_node_name(classNode, classNeedles)
  local method_name = get_node_name(methodNode, methodNeedles)

  loclist:add_item({
    group = "class",
    left = {
      {
        text = class_name
      }
    }
  })

  loclist:add_item({
    group = "method",
    left = {
      {
        text = method_name == "" and "<anonymous>" or method_name,
      }
    }
  })
end

return {
  title = "Curent Location",
  icon =  icon,
  setup = function()
    vim.api.nvim_exec(
    [[
      augroup sidebar_nvim_current_func_update
      autocmd!
      autocmd CursorHold * lua require"curloc-sidebar-nvim".update()
      augroup END
    ]],
    false
    )
    update()
  end,
  update = function(ctx)
    if not ctx then
      ctx = { width = sidebar.get_width() }
    end

    update()
  end,
  draw = function(ctx)
    local lines = {}
    local hl = {
      -- { "SidebarNvimCurrentNodeKeyword", lines[0], 0, -1 },
      -- { "SidebarNvimCurrentNodeValue", lines[1], 0, -1 },
      -- { "SidebarNvimCurrentNodeKeyword", lines[2], 0, -1 },
      -- { "SidebarNvimCurrentNodeValue", lines[3], 0, -1 },
    }

    loclist:draw(ctx, lines, hl)

    return { lines = lines, hl = hl }
  end,
  highlights = {
    groups = {},
    links = {
      SidebarNvimCurrentNodeKeyword = "SidebarNvimComment",
      SidebarNvimCurrentNodeValue = "SidebarNvimKeyword",
    },
  },
}
