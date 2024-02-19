import std/httpclient
import std/parsecfg


const
  appId: string = ""
  guildId: string = ""
  guildCommandEndpoint: string = 
    "https://discord.com/api/v10/applications/" &
    appId &
    "/guilds/" &
    guildId &
    "/commands"

let
  config: Config = loadConfig("bot.ini")
  token: string = config.getSectionValue("Package", "token")

echo token