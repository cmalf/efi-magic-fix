local lfs = require("lfs")
local os = require("os")

-- Color codes
local RED = "\27[31m"
local BLUE = "\27[34m"
local GREEN = "\27[32m"
local YELLOW = "\27[33m"
local UL = "\27[4m"
local RESET = "\27[0m"

-- Display coder sign
local function coder_mark()
    print([[
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃]] .. GREEN .. [[
┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮]] .. BLUE .. [[
┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯]] .. RESET .. [[
╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯

]] .. UL .. GREEN .. "EFI Fixer Hackintosh " .. RESET .. UL .. "v0.1" .. RESET)
end

-- Check if a partition is mounted
local function is_mounted(partition)
    local f = io.popen("mount")
    local output = f:read("*all")
    f:close()
    
    for line in output:gmatch("[^\r\n]+") do
        if line:find(partition) and line:find("type fat32") then
            return true
        end
    end
    return false
end

-- Get the EFI partition from the user
local function get_efi_partition()
    print(YELLOW .. "\n(Executed diskutil list ~ [just copy EFI Partition])" .. RESET)
    os.execute('diskutil list')
    io.write(GREEN .. "\nEnter EFI partition directory" .. RESET .. " (e.g., /dev/disk2s1): ")
    local efi_partition = io.read():gsub("^%s*(.-)%s*$", "%1")

    if not is_mounted(efi_partition) then
        print(RED .. "Partition is not mounted or invalid.\n" .. RESET)
        io.write(YELLOW .. "Do you want to mount now?" .. RED .. " Sudo Password Required!" .. RESET .. " (y/n) ")
        local answer = io.read():lower()
        if answer == 'y' then
            os.execute("sudo diskutil mount " .. efi_partition)
        end
    end

    return efi_partition
end

-- Get the backup directory from the user
local function get_backup_dir()
    print(YELLOW .. "\n(e.g., Below using pwd command ~ [just copy and paste enter])" .. RESET)
    os.execute('pwd')
    io.write(GREEN .. "\nEnter Backup directory: " .. RESET)
    local backup_dir = io.read():gsub("^%s*(.-)%s*$", "%1")
    return backup_dir
end

-- Execute a system command and handle errors
local function execute_command(command)
    local success, exit_type, exit_code = os.execute(command)
    if not success then
        print(RED .. "Error executing command: " .. YELLOW .. command .. RESET)
        if exit_type == "exit" and exit_code == 1 then
            print(YELLOW .. "Trying to force unmount..." .. RESET)
            local force_success = os.execute('sudo diskutil unmount force ' .. efi_partition)
            if not force_success then
                print(RED .. "Forceful unmount failed." .. RESET)
                print(RED .. "Please try rebooting your system and running the script again." .. RESET)
                os.exit(1)
            end
        else
            print(RED .. "Unhandled error." .. RESET)
            print(RED .. "Please check the system logs for more details." .. RESET)
            os.exit(1)
        end
    end
end

-- Main function
local function main()
    os.execute('clear')
    coder_mark()

    local backup_dir = get_backup_dir()
    local efi_partition = get_efi_partition()
    local vol_efi_dir = '/Volumes/EFI/'
    local vol_efi_efi = '/Volumes/EFI/EFI'

    print(YELLOW .. "\nChoose a method: \n" .. RESET)
    print("1. " .. GREEN .. "Format EFI partition and restore backup" .. RESET)
    print("2. " .. BLUE .. "Delete contents of EFI partition and restore backup" .. RESET)
    print("3. " .. RED .. "Exit" .. RESET)

    io.write("\nEnter your choice: ")
    local choice = io.read()

    if choice == '1' then
        print(GREEN .. "Starting format process and backup..." .. RESET)
        execute_command("cd " .. vol_efi_dir .. " && cp -r EFI " .. backup_dir)
        execute_command("sudo diskutil unmount " .. efi_partition)
        execute_command("sudo newfs_msdos -v EFI -F 32 " .. efi_partition)
        execute_command("sudo diskutil mount " .. efi_partition)
        execute_command("cd " .. backup_dir .. " && cp -r EFI " .. vol_efi_dir)
        print(GREEN .. "Fixed EFI Partition Successfully.." .. RESET)
    elseif choice == '2' then
        print(RED .. "Starting deletion process and backup..." .. RESET)
        execute_command("cd " .. vol_efi_dir .. " && cp -r EFI " .. backup_dir)
        execute_command("sudo rm -rf " .. vol_efi_efi)
        execute_command("cd " .. backup_dir .. " && cp -r EFI " .. vol_efi_dir)
        print(GREEN .. "Fixed EFI Partition Successfully.." .. RESET)
    elseif choice == '3' then
        os.execute('clear')
        coder_mark()
        print(GREEN .. "Thanks for using this script!" .. RESET)
    else
        print(RED .. "Invalid choice." .. RESET)
    end
end

main()

