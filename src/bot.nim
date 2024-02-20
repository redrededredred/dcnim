import std/httpclient
import std/parsecfg
import std/json
import htmlgen
import jester
import ed25519
import std/strutils

const
  appId: string = ""
  guildId: string = ""
  discordEndpoint: string = 
    "https://discord.com/api/v10/applications/"

let
  config: Config = loadConfig("bot.ini")
  token: string = config.getSectionValue("Secrets", "token")
  pubKey: string = config.getSectionValue("Secrets", "pubkey")
  authHeaders = newHttpHeaders({
    "Authorization": "Bot " & token
  })
  client: HttpClient = newHttpClient(headers = authHeaders)

type
  AppCommandType = enum
    CHAT_INPUT = 1, USER = 2, MESSAGE = 3
  Bytearray = array[64, byte]

# This is just plain retarded....
proc StrToByteArray(s: string): Bytearray =
  for i, b in toOpenArrayByte(s, 0, s.len - 1):
    result[i] = b

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
    resp %*[{ "name": 2, "age": 30 }]
  post "/":
    let
      signatureRecived: string = request.headers["X-Signature-Ed25519"]
      timestampRecived: string = request.headers["X-Signature-Timestamp"]
      discordJson: JsonNode = parseJson(request.body)
      isVerfied: bool = verify(message = timestampRecived & $request.body, signature = Signature(StrToByteArray(signatureRecived)), publicKey = PublicKey(StrToByteArray(pubKey)))

    if not isVerfied:
      resp(Http401)
    elif discordJson["type"].getInt == 1:
      resp(Http200,  {"Access-Control-Allow-Origin":"*"}, $(%*[{"type": 1}]))
  