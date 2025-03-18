



if (explorer==nil or type(explorer) ~= 'table') then explorer={} end 
if explorer.debug==nil then explorer.debug=false end 
if (explorer.printAdvert==nil) then explorer.printAdvert=true end 
if (explorer.exitOnNotUnityGame==nil) then explorer.exitOnNotUnityGame=true end 

local libStart=0x0 
explorer.maxStringLength=1000 
local alphabet={} 

if explorer.printAdvert then 
    print("✨ Made with UnityExplorer by HTCheater") 
end 

if (explorer.exitOnNotUnityGame and #gg.getRangesList("libunity.so") < 1) then 
    print("🔴 Please, select a Unity game") 
    os.exit() 
end 

string.startsWith=function(self, str) return self:find("^"..str) ~= nil end 
string.endsWith=function(str, ending) return ending=="" or str:sub(-(#ending))==ending end 
string.toUpper=function(str) res, c=str:gsub("^%l", string.upper) return res end 
string.removeEnd=function(str, rem) return (str:gsub("^(.-)"..rem.."$", "%1")) end 
string.removeStart=function(str, rem) return (str:gsub("^"..rem.."(.-)$", "%1")) end 

local isx64=gg.getTargetInfo().x64 
local metadata=gg.getRangesList("libunity.so") 
if #metadata > 0 then metadata=metadata[1] end 

function explorer.setAllRanges() 
    gg.setRanges(gg.REGION_JAVA_HEAP|gg.REGION_C_HEAP|gg.REGION_C_ALLOC|gg.REGION_C_DATA|gg.REGION_C_BSS | 
                 gg.REGION_PPSSPP|gg.REGION_ANONYMOUS|gg.REGION_JAVA|gg.REGION_STACK|gg.REGION_ASHMEM | 
                 gg.REGION_VIDEO|gg.REGION_OTHER|gg.REGION_BAD|gg.REGION_CODE_APP|gg.REGION_CODE_SYS) 
end 

function explorer.getLibStart() 
    return libStart 
end 

function explorer.getLib() 
    explorer.setAllRanges() 
    if gg.getRangesList("libunity.so")[1] ~= nil then 
        libStart=gg.getRangesList("libunity.so")[1].start 
        return 
    end 

    local ranges=gg.getRangesList("bionic_alloc_small_objects") 
    for i, range in pairs(ranges) do 
        gg.searchNumber("47;117;110;105;116;121;46;115;111;0::10", gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range['start'], range['end'], 1) 
        gg.refineNumber("47", gg.TYPE_BYTE) 
        if gg.getResultsCount() ~= 0 then 
            local str=gg.getResults(1)[1] 
            gg.clearResults() 
            addr=str.address 
            while explorer.readByte(addr) ~= 0 do addr=addr-1 end 

            local t={} 
            t[1]={} 
            t[1].address=addr+1 
            t[1].flags=gg.TYPE_BYTE 

            for k, v in pairs(gg.getRangesList("linker_alloc")) do 
                gg.clearResults() 
                gg.loadResults(t) 
                gg.searchPointer(0, v['start'], v['end']) 

                for index, res in pairs(gg.getResults(1)) do 
                    local t={} 
                    t[1]={} 
                    t[1].address=res.address-(isx64 and 0x8 or 0x4) 
                    t[1].flags=isx64 and gg.TYPE_QWORD or gg.TYPE_DWORD 
                    gg.loadResults(t) 

                    local pointers=gg.getResults(1, 0, nil, nil, nil, nil, nil, nil, gg.POINTER_EXECUTABLE) 
                    if #pointers ~= 0 then 
                        libStart=explorer.readPointer(t[1].address) 
                        break 
                    end 
                end 
            end 
            break 
        end 
    end 

    if libStart==0x0 then 
        explorer.print("🔴 explorer.getLib: failed to get libunity.so address, try entering the game first") 
    end 
end 

function explorer.patchLib(offset, offsetX32, patchedBytes, patchedBytesX32) 
    gg.clearResults() 
    if libStart==0 then 
        explorer.getLib() 
    end 

    local patch={} 
    if not isx64 then 
        patchedBytes=patchedBytesX32 
        offset=offsetX32 
    end 

    if (patchedBytes==nil or offset==nil) then 
        explorer.print("🔴 explorer.patchLib: there is no valid patch for current architecture") 
        return 
    end 

    local currAddress=libStart+offset 
    for k, v in ipairs(patchedBytes) do 
        local t={} 
        t[1]={} 
        t[1].address=currAddress 
        t[1].flags=gg.TYPE_DWORD 

        if type(v)=="number" then 
            t[1].value=v 
            gg.setValues(t) 
        elseif type(v)=="string" then 
            if v:startsWith("h") then 
                t[1].value=v 
                gg.setValues(t) 
            else 
                t[1].value=(isx64 and "~A8 " or "~A ")..v 
                gg.setValues(t) 
            end 
        end 
        currAddress=currAddress+4 
    end 
end 

function explorer.readValue(addr, valueType) 
    if type(addr) ~= 'number' then 
        explorer.print("🔴 explorer.readValue: expected number for parameter addr, got "..type(addr)) 
        return 
    end 
    if type(valueType) ~= 'number' then 
        explorer.print("🔴 explorer.readValue: expected number for parameter valueType, got "..type(valueType)) 
        return 
    end 

    local t={} 
    t[1]={} 
    t[1].address=addr 
    t[1].flags=valueType 
    t=gg.getValues(t) 
    return t[1].value 
end 

function explorer.readByte(addr) 
    return explorer.readValue(addr, gg.TYPE_BYTE) 
end 

function explorer.readShort(addr) 
    return explorer.readValue(addr, gg.TYPE_WORD) 
end 

function explorer.readInt(addr) 
    return explorer.readValue(addr, gg.TYPE_DWORD) 
end 

function explorer.readPointer(addr) 
    return explorer.readValue(addr, isx64 and gg.TYPE_QWORD or gg.TYPE_DWORD) 
end 

function explorer.print(str) 
    if explorer.debug then 
        print(str) 
    end 
end 

function explorer.readString(addr) 
    if type(addr) ~= 'number' then 
        explorer.print('🔴 explorer.readString: expected number, got ' .. type(addr)) 
        return "" 
    end 

    local len=explorer.readInt(addr+(isx64 and 0x10 or 0x8)) 
    if len > explorer.maxStringLength then 
        explorer.print('🟡 explorer.readString: string is too large, length is '..len) 
        return "" 
    end 

    local str="" 
    for i=1, len, 1 do 
        local c=explorer.readShort(addr+(isx64 and 0x14 or 0xC)+(2 * (i-1))) 
        if (c > -1 and c < 129) then 
            str=str..string.char(c)  
        else 
            if (alphabet[c] ~= nil) then 
                str=str..alphabet[c] 
            else 
                explorer.print('🟡 explorer.readString: unrecognized character '..c) 
            end 
        end 
    end 
    return str 
end 

