-- Patrick Star Crafting Installer
local repoURL = "https://raw.githubusercontent.com/GopSalt/lualib/main/"
local filesToDownload = {
    {url = repoURL .. "patrick/startup.lua", path = "craft.lua"}
}

print("=== Patrick Star Installer ===")
local success = true

for _, file in ipairs(filesToDownload) do
    print("Downloading: " .. file.path)
    local res = http.get(file.url)
    if res then
        local f = fs.open(file.path, "w")
        f.write(res.readAll())
        f.close()
        res.close()
    else
        print("ERROR: Failed to download " .. file.path)
        success = false
    end
end

if success then
    print("\nInstallation Complete!")
    print("Starting craft.lua...")
    sleep(1)
    shell.run("craft.lua")
else
    print("\nInstallation failed!")
end
