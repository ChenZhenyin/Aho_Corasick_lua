-- 项目场景(配置表)
local world_list = {}
world_list[1] = { id = 1, word = "He" }
world_list[2] = { id = 2, word = "sHe" }
world_list[3] = { id = 3, word = "Hers" }
world_list[4] = { id = 4, word = "hish" }
world_list[5] = { id = 5, word = "is" }

-- AC自动机根节点(data为服务器内存字段的模块名)
data = {}	-- 项目中为module模块
data.ac_auto_machine_root = {
	ch = "root",
	word_length = nil,
	child = {},
	fail = nil,
}

local function build_node(root, word)
	if not word or type(word) ~= 'string' then
		return
	end
	local node = root
	for i = 1, #word do
		local ch = string.sub(word, i, i)
		if node.child[ch] then
			node = node.child[ch]
			if not node.word_length and i == #word then
				node.word_length = #word
			end
		else
			local temp_node = {}
			temp_node.ch = ch
			temp_node.word_length = i == #word and #word or nil
			temp_node.child = {}
			temp_node.fail = {}
			node.child[ch] = temp_node
			node = node.child[ch]
		end
	end
end

local function build_fail(root)
	root.fail = nil

	local queue = {}
	table.insert(queue, root)

	-- BFS建立fail指针
	while #queue > 0 do
		local parent = queue[1]
		table.remove(queue, 1)	-- 先进先出

		for ch, node in pairs(parent.child) do
			local fafail = parent.fail
			while fafail and not fafail.child[ch] do
				fafail = fafail.fail
			end
			if not fafail then
				node.fail = root
			else
				node.fail = fafail.child[ch]
			end

			if node.fail.word_length and not node.word_length then
				node.word_length = node.fail.word_length
			end

			table.insert(queue, node)
		end
	end
end

-- 考虑热更新时将配置表加载到服务器内存字段中, 避免重复建树
function ac_build(world_list)
	if not world_list or #world_list <= 0 then
		return
	end
	for _, infos in pairs(world_list) do
		local word = infos.word and string.lower(infos.word)
		build_node(data.ac_auto_machine_root, word)
	end

	build_fail(data.ac_auto_machine_root)
end

local function word_shield(str, start, len, mark)
	if not str or type(str) ~= 'string' or #str <= 0 then
		return
	end

	local temp = ""
	for i = 1, len do
		temp = temp .. mark
	end
	return string.sub(str, 1, start - 1) .. temp .. string.sub(str, start + len)
end

function check_word_shield(str, mark)
	if not str or type(str) ~= 'string' or #str <= 0 then
		return
	end

	local mark = mark or '*'
	local node = data.ac_auto_machine_root
	local result = str
	local lower_str = string.lower(str)
	for i = 1, #lower_str do
		local ch = string.sub(lower_str, i, i)
		while not node.child[ch] and node.fail do
			node = node.fail
		end

		if node.child[ch] then
			node = node.child[ch]
		end

		if node.word_length then
			result = word_shield(result, i - node.word_length + 1, node.word_length, mark)
		end
	end
	return result
end

-- 测试脚本入口
ac_build(world_list)
local str = "aHiSheRshEiSHiSeR"
local result = check_word_shield(str, '*')
print(string.format("The result is %s", result))
