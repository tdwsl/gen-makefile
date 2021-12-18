-- tdwsl 2021
--
-- This lua script generates a makefile based on the files in the 'src'
-- directory.
--
-- !!!IMPORTANT!!!
-- This script doesn't work properly if you use '-CCgcc' or '-ooutput'!
-- It won't recognise the importance of these arguments and will simply
-- pass them to the compiler.
--
-- It produces the file 'Makefile' in the current directory. This makefile
-- will put output object files into the 'obj' directory and find header
-- files in the 'include' directory.
--
-- To change the compiler (default is gcc), use '-cc <cxx>', where <cxx>
-- is the compiler.
--
-- Any other arguments will be passed to the compiler when compiling the
-- final executable.

function print_help()
	print("usage:")
	print("lua gen_makefile.lua [options]\n")
	print("options:")
	print("\t-cc [COMPILER]\tset C/C++ compiler to COMPILER")
	print("\t-o\t\tspecify output file in makefile")
	print()
	print("other options will be passed to the compiler")
end

function split_string(str, d)
	local split_table = {}
	for s in string.gmatch(str, "([^"..d.."]+)") do
		table.insert(split_table, s)
	end
	return split_table
end

function get_arg(argstr, ar)
	local args = split_string(argstr, " ")

	for i, a in ipairs(args) do
		if a == ar then
			return args[i+1]
		end
	end

	return nil
end

function get_argstr()
	local argstr = ""
	local i = 1
	while arg[i] ~= nil do
		argstr = argstr .. " " .. arg[i]
		i = i + 1
	end
	return argstr
end

function del_arg(argstr, ar)
	local args = split_string(argstr, " ")

	for i, a in ipairs(args) do
		if a == ar then
			table.remove(args, i)
			table.remove(args, i)
		end
	end

	argstr = ""
	for i, a in ipairs(args) do
		argstr = argstr .. " " .. a
	end

	return argstr
end

function has_arg(argstr, ar)
	local args = split_string(argstr, " ")

	for i, a in ipairs(args) do
		if a == ar then
			return true
		end
	end

	return false
end

function get_objects(keepext)
	local dirstr = io.popen("ls src"):read("*a")
	local objects = {}

	objects = split_string(dirstr, "\n")

	for i, obj in ipairs(objects) do
		if obj == "." or obj == ".." then
			table.remove(obj, i)
		end
	end

	if keepext then
		return objects
	end

	for j, obj in ipairs(objects) do
		local di = -1
		for i = 1, #obj do
			if obj:sub(i, i) == "." then
				di = i
				break
			end
		end

		if di ~= -1 then
			objects[j] = obj:sub(1, di-1)
		else
			table.remove(objects, j)
		end
	end

	return objects
end

local argstr = get_argstr()

if has_arg(argstr, "-h") or has_arg(argstr, "--help") then
	print_help()
	os.exit()
end

local cc = get_arg(argstr, "-cc")
if cc == nil then
	cc = "gcc"
end
argstr = del_arg(argstr, "-cc")

local output = get_arg(argstr, "-o")
if output == nil then
	output = "program"
end
argstr = del_arg(argstr, "-o")

local objects = get_objects(false)
local objects_ext = get_objects(true)

local makefile = io.open("Makefile", "w")
io.output(makefile)

io.write("# Generated with gen_makefile.lua (tdwsl 2021)\n")
io.write("CC = " .. cc .. "\n")
io.write("OUTPUT = " .. output .. "\n\n")

io.write("$(OUTPUT):")
for i, o in ipairs(objects) do
	io.write(" obj/" .. o .. ".o")
end
io.write("\n\t$(CC) obj/* -Iinclude -o $(OUTPUT)" .. argstr .. "\n\n")

for i, o in ipairs(objects) do
	io.write("obj/" .. o .. ".o: src/" .. objects_ext[i] .. "\n")
	io.write("\t$(CC) -c src/" .. objects_ext[i] .. " -Iinclude\n")
end

io.write("\nclean:\n")
io.write("\trm obj/* $(OUTPUT)\n")

io.close(makefile)
