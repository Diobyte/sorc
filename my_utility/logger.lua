local logger = {}

-- Logger state
local log_file = nil
local is_initialized = false

-- Initialize the logger with a timestamped filename
function logger.init()
    if is_initialized then
        return true
    end
    
    -- Create filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "sorcerer_debug_" .. timestamp .. ".txt"
    
    -- Try to create in a more accessible location first
    local accessible_locations = {
        "C:\\temp\\sorcerer_debug_" .. timestamp .. ".txt",
        "C:\\Users\\Public\\sorcerer_debug_" .. timestamp .. ".txt",
        filename  -- fallback to current directory
    }
    
    -- Try to open the file for writing in accessible locations
    for _, location in ipairs(accessible_locations) do
        log_file = io.open(location, "w")
        if log_file then
            is_initialized = true
            log_file:write("=== Sorcerer Plugin Debug Log Started ===\n")
            log_file:write("Location: " .. location .. "\n")
            log_file:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
            log_file:write("==========================================\n\n")
            log_file:flush() -- Ensure immediate write
            console.print("[LOGGER INFO] Log file created at: " .. location)
            return true
        end
    end
    
    console.print("[LOGGER ERROR] Failed to create log file in any accessible location")
    return false
end

-- Log a message with timestamp (accepts varargs)
function logger.log(...)
    if not is_initialized or not log_file then
        return false
    end

    -- Build message string from varargs
    local parts = {...}
    if #parts == 0 then parts = {""} end
    for i = 1, #parts do
        parts[i] = tostring(parts[i])
    end
    local message = table.concat(parts, " ")

    -- Format timestamp with integer milliseconds (Lua 5.1-safe)
    local ms = math.floor((get_time_since_inject() * 1000) % 1000)
    local timestamp = os.date("%H:%M:%S.") .. string.format("%03d", ms)
    local log_entry = "[" .. timestamp .. "] " .. message .. "\n"

    log_file:write(log_entry)
    log_file:flush() -- Ensure immediate write
    return true
end

-- Close the logger
function logger.close()
    if log_file then
        log_file:write("\n=== Sorcerer Plugin Debug Log Ended ===\n")
        log_file:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        log_file:close()
        log_file = nil
    end
    is_initialized = false
end

-- Check if logger is ready
function logger.is_ready()
    return is_initialized and log_file ~= nil
end

return logger 