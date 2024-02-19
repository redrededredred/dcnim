import std/httpclient
import std/parsecfg
import std/json
import htmlgen
import jester

const
  appId: string = ""
  guildId: string = ""
  discordEndpoint: string = 
    "https://discord.com/api/v10/applications/"

let
  config: Config = loadConfig("bot.ini")
  token: string = config.getSectionValue("Package", "token")
  authHeaders = newHttpHeaders({
    "Authorization": "Bot " & token
  })
  client: HttpClient = newHttpClient(headers = authHeaders)

type
  AppCommandType = enum
    CHAT_INPUT = 1, USER = 2, MESSAGE = 3


proc addCommand(client: HttpClient, command: JsonNode) {.discardable.} = 
  if client.post(discordEndpoint & appId & "guilds" & guildId & "/commands", body = $command).code == Http200:
    echo "[+] Commands added!"
    return
  echo "[!] Failed adding commands!"

proc deleteCommand(client: HttpClient, commandId: string) {.discardable.} =
  if client.delete(discordEndpoint & appId & "guilds" & guildId & "/commands/" & commandId).code == Http200:
    echo "[+] Commands added!"
    return
  echo "[!] Failed adding commands!"


# Jester handels responding to commands
routes:
  get "/":
    resp "awd"
