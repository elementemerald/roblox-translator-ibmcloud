local Players = game:GetService("Players");
local HTTPService = game:GetService("HttpService");
local StarterGui = game:GetService("StarterGui");

local serviceUrl = "";
local apiKey = "";
local apiKeySerialized = string.format("Basic %s", syn.crypt.base64.encode("apikey:" ..apiKey));

local translateTo = "en";

local translateMsg = function(v, msg)
    -- Detect language using AI
    
    local req = syn.request({
        Url = string.format("%s/v3/identify?version=2018-05-01", serviceUrl),
        Method = "POST",
        Headers = {
            ["Content-Type"] = "text/plain",
            ["Authorization"] = apiKeySerialized
        },
        Body = msg
    });

    local parsed = HTTPService:JSONDecode(req.Body);
    local translateFrom = parsed.languages[1].language;
    
    if translateFrom == "en" then print("Pretty sure the language was English, ignoring") return end;
    
    -- Translate text
    
    local data = {
        ["text"] = { msg },
        ["model_id"] = string.format("%s-%s", translateFrom, translateTo)
    };
    
    local req2 = syn.request({
        Url = string.format("%s/v3/translate?version=2018-05-01", serviceUrl),
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = apiKeySerialized
        },
        Body = HTTPService:JSONEncode(data)
    });

    local parsed2 = HTTPService:JSONDecode(req2.Body);
    local primaryTranslation = parsed2.translations[1].translation;
    
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = string.format("{System} %s [Translated to %s from %s]: %s", v.Name, translateTo, translateFrom, primaryTranslation)
    });
end;

for _,v in pairs(Players:GetPlayers()) do
    if v.Name ~= Players.LocalPlayer.Name then
        v.Chatted:Connect(function(msg)
            translateMsg(v, msg);
        end);
    end;
end;

Players.PlayerAdded:Connect(function(Player)
    Player.Chatted:Connect(function(msg)
        translateMsg(v, msg);
    end);
end);
