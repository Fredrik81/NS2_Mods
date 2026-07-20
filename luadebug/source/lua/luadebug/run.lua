if jit then
    print("LuaJIT version: " .. jit.version)
    print("LuaJIT version nummer: " .. jit.version_num)
    print("Operativsystem: " .. jit.os)
    print("Arkitektur: " .. jit.arch)
    print("Status: " .. jit.status())
    -- Print all the available JIT options
    print("JIT information:")
    for k, v in pairs(jit) do
        print(k, v)
    end
else
    print("Detta körs inte under LuaJIT (vanlig Lua eller annan kompilator).")
end
