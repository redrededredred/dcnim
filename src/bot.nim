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
  debug: bool = true

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
  InteractionCallbackType = enum
    PONG = 1,
    CHANNEL_MESSAGE_WITH_SOURCE = 4,
    DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE = 5,
    DEFERRED_UPDATE_MESSAGE = 6,
    UPDATE_MESSAGE = 7
    APPLICATION_COMMAND_AUTOCOMPLETE_RESULT = 8
    MODAL = 9
    PREMIUM_REQUIRED = 10
  Bytearray = array[64, byte]
  Pubkeyarray = array[32, byte]

# This is just plain retarded....
proc StrToByteArray(s: string): Bytearray =
  for i, b in toOpenArrayByte(s, 0, s.len - 1):
    result[i] = b

proc StrToPubkeyArray(s: string): Pubkeyarray =
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

proc getCommand(client: HttpClient, commandId: string): JsonNode =
  let response: Response = client.get(discordEndpoint & appId & "guilds" & guildId & "/commands/" & commandId)
  if response.code == Http200:
    result = %*response.body
    echo "[+] Fetched all commands!"
    return
  echo "[!] Failed fetching commands!"
  return %*[]

proc getCommand(client: HttpClient): JsonNode =
  let response: Response = client.get(discordEndpoint & appId & "guilds" & guildId & "/commands")
  if response.code == Http200:
    result = %*response.body
    echo "[+] Fetched all commands!"
    return
  echo "[!] Failed fetching commands!"
  return %*[]

proc editCommand(client: HttpClient, commandId: string, command: JsonNode): JsonNode =
  let response: Response = client.patch(discordEndpoint & appId & "guilds" & guildId & "/commands/" & commandId, body = $command)
  if response.code == Http200:
    result = %*response.body
    echo "[+] Fetched all commands!"
    return
  echo "[!] Failed fetching commands!"
  return %*[]

when debug:
  echo InteractionCallbackType.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE.ord
# Jester handels responding to commands
routes:
  post "/":
    let
      signatureRecived: string = request.headers["X-Signature-Ed25519"]
      timestampRecived: string = request.headers["X-Signature-Timestamp"]
      discordJson: JsonNode = parseJson(request.body)
      # TODO: fix pubkey cancer
      isVerfied: bool = verify(message = timestampRecived & $request.body, signature = Signature(StrToByteArray(signatureRecived)), publicKey = PublicKey(StrToPubkeyArray("FF")))

    if not isVerfied:
      resp(Http401)
    elif discordJson["type"].getInt == InteractionCallbackType.PONG.ord:
      resp(Http200, $(%*[{"type": InteractionCallbackType.PONG.ord}]))
    resp($(%*[{"type": InteractionCallbackType.CHANNEL_MESSAGE_WITH_SOURCE.ord,"data": {"content": "Woah it works!"}}]))