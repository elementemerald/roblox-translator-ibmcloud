local Players = game:GetService("Players");
local HTTPService = game:GetService("HttpService");
local StarterGui = game:GetService("StarterGui");

local serviceUrl = "";
local apiKey = "";

local function getSpecificFunc(type, data)
    local exec = identifyexecutor();
    if type == "base64" then
        if exec == "ScriptWare" then
            return crypt.base64encode(data);
        elseif exec == "Synapse X" then
            return syn.crypt.base64.encode(data);
        else
            error("Your platform is not supported");
        end;
    elseif type == "request" then
        if exec == "ScriptWare" then
            return http.request(data);
        elseif exec == "Synapse X" then
            return syn.request(data);
        else
            error("Your platform is not supported");
        end;
    end;
end;

local apiKeySerialized = string.format("Basic %s", getSpecificFunc("base64", "apikey:" ..apiKey));

local translateTo = "en";

local translateMsg = function(v, msg)
    -- Detect language using AI
    
    local req = getSpecificFunc("request", {
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
    
    -- Translate text
    
    local data = {
        ["text"] = { msg },
        ["model_id"] = string.format("%s-%s", translateFrom, translateTo)
    };
    
    local req2 = getSpecificFunc("request", {
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
