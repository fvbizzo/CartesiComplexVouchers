local function generate_source(enum_data, input_file, output_file)
    local indent = string.rep(' ', 4)

    -- Shamelessly stolen from Pallene compiler.
    local function render(code, substs)
        local err
        local out = string.gsub(code, "%$({?)([A-Za-z_][A-Za-z_0-9]*)(}?)",
            function(a, k, b)
                if a == "{" and b == "" then
                    err = "unmatched ${ in template"
                    return ""
                end
                local v = substs[k]
                if not v then
                    err = "missing template variable " .. k
                    return ""
                elseif type(v) ~= "string" then
                    err = "template variable is not a string " .. k
                    return ""
                end
                if a == "" and b == "}" then
                    v = v .. b
                end
                return v
            end
        )

        if err then
            error(err)
        end

        return out
    end


    -- Imports
    local imports_str
    do
        local imports_table = {}

        for _,v in ipairs(enum_data.imports) do
            local s = string.format([[import "%s";]], v)
            table.insert(imports_table, s)
        end

        imports_str = table.concat(imports_table, '\n')
    end


    -- Enum description
    local description_str
    do
        local description_table = {}

        for _,v in ipairs(enum_data.variants) do
            local name, t = v.name, v.typ
            table.insert(description_table, string.format("| %s of %s", name, t))
        end

        local sep = '\n' .. indent .. '// ' .. indent
        description_str = sep .. table.concat(description_table, sep)
    end


    local tag_str
    do
        local tag_table = {}
        local i = indent .. indent

        for _,v in ipairs(enum_data.variants) do
            local name = v.name
            table.insert(tag_table, i .. string.format("%s", name))
        end

        tag_str = '\n' .. table.concat(tag_table, ',\n')
    end


    local methods_str
    do
        local template = [[
    //
    // `${name}` methods
    //

    function enumOf${name}(
        ${typ} memory x
    ) external pure returns (T memory) {
        return T(Tag.${name}, abi.encode(x));
    }

    function is${name}Variant(
        T memory t
    ) external pure returns (bool) {
        return t._tag == Tag.${name};
    }

    function get${name}Variant(
        T memory t
    ) external pure returns (${typ} memory) {
        require(t._tag == Tag.${name});
        return abi.decode(t._data, (${typ}));
    }
]]

        local methods_table = {}

        for _,v in ipairs(enum_data.variants) do
            local name, t = v.name, v.typ
            local s = render(template, { name = name, typ = t })
            table.insert(methods_table, s)
        end

        methods_str = table.concat(methods_table, '\n\n')
    end


    local subs = {
        sol_version = enum_data.sol_version,
        file = input_file,
        output = output_file,
        imports = imports_str,
        name = enum_data.name,
        description = description_str,
        tags = tag_str,
        methods = methods_str,
    }

    local s = render([[
// SPDX-License-Identifier: UNLICENSED
pragma solidity ${sol_version};

// THIS FILE WAS AUTOMATICALLY GENERATED BY `generate_enum_proc.lua`,
// WITH ARGUMENT `${file}`,
// AND OUTPUT AT `${output}`.

${imports}

library ${name} {

    // let type ${name}.T =${description}

    enum Tag {${tags}
    }

    struct T {
        Tag _tag;
        bytes _data;
    }

${methods}}
]], subs)

    return s
end

return {
    source = generate_source
}
