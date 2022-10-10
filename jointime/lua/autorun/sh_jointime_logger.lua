if SERVER then

    CreateConVar( "jointime_printconsole", 1 )      // Print the time to join the server to the server console
    CreateConVar( "jointime_save", 1 )              // Save everything in a log file (with extra information)
    CreateConVar( "jointime_saveindividual", 0 )    // Create a separat log file for every player

    util.AddNetworkString( "FinallyJoined" )
    
    local joiningPlayers = {}
    local downloadSize = 0
    local addonsCount = 0

    for k, v in pairs( engine.GetAddons() ) do
        if v.mounted then
            downloadSize = downloadSize + v.size
            addonsCount = addonsCount + 1
        end
    end

    // Convert Bytes to MB (or GB)
    downloadSize = downloadSize / 1000000 // MB
    if downloadSize >= 1000 then
        downloadSize = downloadSize / 1000 // GB
        downloadSize = downloadSize .. " GB"
    else
        downloadSize = downloadSize .. " MB"
    end

    local function ConvertToHMinSec( formattedTime )
        if formattedTime.h >= 1 then
            return formattedTime.h .. "h " .. formattedTime.m .. "min " .. formattedTime.s .. "sec"
        elseif formattedTime.m >= 1 then
            return formattedTime.m .. "min " .. formattedTime.s .. "sec"
        else
            return formattedTime.s .. "sec"
        end
    end

    local function CalcJoinTime( connectedTime )
        return ConvertToHMinSec( string.FormattedTime( SysTime() - connectedTime ) )
    end

    local function CalcServerTime()
        return ConvertToHMinSec( string.FormattedTime( CurTime() ) )
    end

    hook.Add( "PlayerConnect", "JoinTimeStart", function( name, ip )
        joiningPlayers[ip] = SysTime()
    end )

    net.Receive( "FinallyJoined", function( len, ply )
        local ip = ply:IPAddress()
        if joiningPlayers[ip] then
            local nick = ply:Nick()
            local steamid64 = ply:SteamID64()
            local dateTime = util.DateStamp()
            local joinTime = CalcJoinTime( joiningPlayers[ip] )
            local serverUptime = CalcServerTime()
            local map = game.GetMap()
            local numPlayers = #player.GetAll()
            local numEnts = #ents.GetAll()

            if GetConVar( "jointime_printconsole" ):GetBool() then
                print( "Player \"" .. nick .. "\" (" .. steamid64 .. ") joined the server in " .. joinTime .. "!" )
            end

            if GetConVar( "jointime_save" ):GetBool() then
                local line = "[" .. dateTime .. "] | " .. nick .. " (" .. steamid64 .. ") | Join-Time: " .. joinTime .. " | Addons: " .. addonsCount .. " (" .. downloadSize .. ") | Map: " .. map .. " | Server-Uptime: " .. serverUptime .. " | Player Count: " .. numPlayers .. " | Entity Count: " .. numEnts .. [[

]]
                file.CreateDir( "jointime" )
                file.Append( "jointime/logs.txt", line )
            end

            if GetConVar( "jointime_saveindividual" ):GetBool() then
                local line = "[" .. dateTime .. "] | Join-Time: " .. joinTime .. " | Addons: " .. addonsCount .. " (" .. downloadSize .. ") | Map: " .. map .. " | Server-Uptime: " .. serverUptime .. " | Player Count: " .. numPlayers .. " | Entity Count: " .. numEnts .. [[

]]
                file.CreateDir( "jointime" )
                file.Append( "jointime/" .. steamid64 .. ".txt", line )
            end
            joiningPlayers[ip] = nil
        end
    end )

end

if CLIENT then

    hook.Add( "InitPostEntity", "JoinTimeStop", function()
        net.Start( "FinallyJoined" )
        net.SendToServer()
    end )

end