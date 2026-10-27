-- Patch multi-speaker: sobrescribe solo los 3 archivos modificados.
local FILES = {
['/sys/mobile/sound.lua'] = [[local M = {}
local speakers

local function getSpeakers()
if speakers then return speakers end
speakers = {}
if not peripheral or type(peripheral.find) ~= "function" then return speakers end
local ok, found = pcall(peripheral.find, "speaker")
if ok and type(found) == "table" then
for _, sp in ipairs(found) do
if type(sp.playNote) == "function" then speakers[#speakers + 1] = sp end
end
end
return speakers
end

function M.play(kind, enabled)
if enabled == false then return false end
local devices = getSpeakers()
if #devices == 0 then return false end

local notes
if kind == "action" then
notes = { { "chime", 0.65, 17 }, { "pling", 0.45, 21 } }
elseif kind == "startup" then
notes = { { "chime", 0.65, 12 }, { "bell", 0.65, 16 }, { "pling", 0.6, 19 },
{ "chime", 0.55, 21 }, { "pling", 0.45, 24 } }
elseif kind == "shutdown" then
notes = { { "pling", 0.55, 22 }, { "bell", 0.6, 19 }, { "chime", 0.55, 16 },
{ "bell", 0.45, 12 }, { "chime", 0.35, 9 } }
else
notes = { { "hat", 0.35, 18 } }
end

local played = false
for _, device in ipairs(devices) do
for _, note in ipairs(notes) do
local ok = pcall(device.playNote, note[1], note[2], note[3])
played = played or ok
end
end
return played
end

return M
]],
['/apps/music.lua'] = [[local ui = require("sys.mobile.ui")
local lib = require("sys.mobile.lib")
local M = { title = "Streaming Music" }

local API = "https://ipod-2to6magyna-uc.a.run.app/"
local VERSION = "2.1"
local state = { query = "", results = {}, selected = 1, page = 1,
message = "Busca una cancion o pega un enlace de YouTube.", searching = false,
playing = false, stop = false, speakers = {}, speakerNames = {}, now = nil,
searchUrl = nil, downloadUrl = nil, decoders = {} }

local function compact(value, width)
value = tostring(value or ""):gsub("[%c]", " ")
if #value > width then return value:sub(1, math.max(1, width - 1)) .. "~" end
return value
end

local function stopPlayback()
state.stop = true
for _, sp in ipairs(state.speakers) do
if sp.stop then pcall(sp.stop) end
end
for _, name in ipairs(state.speakerNames) do
os.queueEvent("speaker_audio_empty", name)
end
state.playing = false
state.speakers, state.speakerNames, state.decoders = {}, {}, {}
end

local function search(ctx)
local query = lib.prompt(ctx, "Buscar musica:", state.query)
if not query or not query:match("%S") then return end
state.query, state.results, state.page = query, {}, 1
state.searching, state.message = true, "Buscando..."
local url = API .. "?v=" .. VERSION .. "&search=" .. textutils.urlEncode(query)
state.searchUrl = url
local ok, reason = pcall(http.request, url)
if not ok then state.searching = false; state.message = "HTTP no disponible: " .. tostring(reason) end
end

local function playItem(ctx, item)
local allSpeakers = { peripheral.find("speaker") }
local valid = {}
for _, sp in ipairs(allSpeakers) do
if type(sp.playAudio) == "function" then valid[#valid + 1] = sp end
end
if #valid == 0 then state.message = "Conecta un speaker para reproducir."; return end

local ok, decoderModule = pcall(require, "cc.audio.dfpwm")
if not ok then state.message = "Requiere CC:Tweaked 1.100+ (cc.audio.dfpwm)."; return end

stopPlayback()
state.stop, state.playing, state.speakers, state.now = false, true, valid, item
state.speakerNames, state.decoders = {}, {}
for i, sp in ipairs(valid) do
local nameOk, name = pcall(peripheral.getName, sp)
state.speakerNames[i] = nameOk and name or nil
state.decoders[i] = decoderModule.make_decoder()
end

state.message = "Cargando (" .. #valid .. " spk): " .. compact(item.name, 20)
state.downloadUrl = API .. "?v=" .. VERSION .. "&id=" .. textutils.urlEncode(item.id)
local ok, reason = pcall(http.request, { url = state.downloadUrl, binary = true })
if not ok then state.playing = false; state.message = "HTTP no disponible: " .. tostring(reason) end
end

function M.event(ctx, event, url, handle)
if event == "http_success" then
if url == state.searchUrl then
local raw = handle.readAll(); handle.close()
local ok, data = pcall(textutils.unserialiseJSON, raw or "[]")
if not ok or type(data) ~= "table" then
state.searching, state.message = false, "Respuesta invalida"; return
end
state.results = {}
for _, item in ipairs(data) do
if type(item) == "table" and item.id then
state.results[#state.results + 1] = { id = tostring(item.id),
name = tostring(item.name or "Sin titulo"), artist = tostring(item.artist or "YouTube") }
end
end
state.searching = false
state.message = #state.results > 0 and ("Resultados: " .. #state.results)
or "No se encontraron resultados."
elseif url == state.downloadUrl then
local input = handle
ctx.spawn(function()
local first = input.read(4)
if not first then input.close(); error("Audio vacio") end
local firstChunk = true
while not state.stop do
local chunk = input.read(16380)
if not chunk then break end
if firstChunk then chunk, firstChunk = first .. chunk, false end
for i, sp in ipairs(state.speakers) do
local audio = state.decoders[i](chunk)
while not state.stop and not sp.playAudio(audio) do
coroutine.yield("speaker_audio_empty", state.speakerNames[i])
end
end
end
input.close()
if not state.stop then state.message = "Reproduccion terminada" end
state.playing = false
end, function(err)
state.playing = false; state.message = "Error de audio: " .. tostring(err)
end)
end
elseif event == "http_failure" then
if url == state.searchUrl then
state.searching, state.message = false, "No se pudo conectar al servicio."
elseif url == state.downloadUrl then
state.playing, state.message = false, "No se pudo descargar el audio."
end
end
end

function M.open()
state.results, state.selected, state.page = {}, 1, 1
state.message = "Busca una cancion o pega un enlace de YouTube."
end

function M.close() stopPlayback() end

function M.draw()
local w, h = term.getSize()
ui.fill(2, 3, math.max(1, w - 3), 1, colors.blue)
local spCount = #state.speakers > 0 and (" [" .. #state.speakers .. " spk]") or ""
ui.text(3, 3, compact((state.now and ("~ " .. state.now.name) or "Streaming Music") .. spCount, w - 4), colors.white, colors.blue, w - 4)
ui.button(2, 5, 8, "Buscar", colors.green, colors.black)
ui.button(12, 5, 7, "Parar", colors.red)
ui.text(2, 7, compact(state.message, w - 2), state.searching and colors.gray or colors.blue, colors.white, w - 2)
local first = (state.page - 1) * math.max(1, h - 10) + 1
for index = first, math.min(#state.results, first + h - 11) do
local y, item = 9 + index - first, state.results[index]
ui.text(2, y, (index == state.selected and "> " or " ") .. compact(item.name, w - 4),
index == state.selected and colors.blue or colors.black, colors.white, w - 2)
if y + 1 < h - 1 then ui.text(4, y + 1, compact(item.artist, w - 6), colors.gray, colors.white, w - 4) end
end
end

function M.touch(ctx, x, y)
local _, h = term.getSize()
if y == 5 and x < 11 then search(ctx); return end
if y == 5 and x >= 11 and x < 20 then stopPlayback(); state.message = "Reproduccion detenida"; return end
if y >= 9 and y < h - 1 then
local index = (state.page - 1) * math.max(1, h - 10) + math.floor((y - 9) / 2) + 1
if state.results[index] then state.selected = index; playItem(ctx, state.results[index]) end
end
end

return M
]],
['/apps/media.lua'] = [[local ui = require("sys.mobile.ui")
local M = { title = "Android Media Player" }
local state = { tracks = {}, selected = 1, playing = false, stop = false,
speakers = {}, speakerNames = {}, decoders = {}, message = "DFPWM en /music o /disk" }

local function scan()
state.tracks = {}
for _, directory in ipairs({ "/music", "/disk" }) do
if fs.exists(directory) and fs.isDir(directory) then
for _, name in ipairs(fs.list(directory)) do
if not fs.isDir(fs.combine(directory, name)) and name:lower():match("%.dfpwm$") then
state.tracks[#state.tracks + 1] = fs.combine(directory, name)
end
end
end
end
if state.selected > #state.tracks then state.selected = math.max(1, #state.tracks) end
end

function M.open() scan() end

function M.draw()
local w, h = term.getSize()
ui.fill(2, 3, w - 3, 2, colors.blue)
local spCount = #state.speakers > 0 and ("  [" .. #state.speakers .. " spk]") or ""
ui.center(3, "Android Media Player" .. spCount, colors.white, colors.blue)
ui.button(2, 6, 7, "Play", colors.green, colors.black)
ui.button(10, 6, 8, "Pause", colors.lightBlue)
ui.button(20, 6, 7, "Stop", colors.red)
ui.button(2, 8, 10, "Actualizar", colors.gray)
ui.text(2, 10, state.message, colors.blue, colors.white, w - 2)
for i, track in ipairs(state.tracks) do
local y = 12 + i - 1
if y >= h - 1 then break end
ui.text(2, y, (i == state.selected and "> " or " ") .. fs.getName(track),
i == state.selected and colors.blue or colors.black, colors.white, w - 2)
end
end

local function play(ctx)
local path = state.tracks[state.selected]
if not path then state.message = "No hay pistas .dfpwm"; return end
if state.playing then state.message = "Ya hay una pista activa"; return end

local allSpeakers = { peripheral.find("speaker") }
local valid = {}
for _, sp in ipairs(allSpeakers) do
if type(sp.playAudio) == "function" then valid[#valid + 1] = sp end
end
if #valid == 0 then state.message = "Speaker no conectado"; return end

local ok, decoderModule = pcall(require, "cc.audio.dfpwm")
if not ok then state.message = "No esta disponible cc.audio.dfpwm"; return end
local input, err = fs.open(path, "rb")
if not input then state.message = tostring(err); return end

state.speakers, state.stop, state.playing = valid, false, true
state.speakerNames, state.decoders = {}, {}
for i, sp in ipairs(valid) do
local nameOk, name = pcall(peripheral.getName, sp)
state.speakerNames[i] = nameOk and name or nil
state.decoders[i] = decoderModule.make_decoder()
end

local spLabel = #valid > 1 and (" en " .. #valid .. " speakers") or ""
state.message = "Reproduciendo" .. spLabel .. ": " .. fs.getName(path)

local function playbackFailed(reason)
pcall(input.close)
state.playing = false
state.message = "Error de audio: " .. tostring(reason)
end

ctx.spawn(function()
while not state.stop do
local compressed = input.read(8192)
if not compressed then break end
for i, sp in ipairs(state.speakers) do
local audio = state.decoders[i](compressed)
while not state.stop do
local queued, accepted = pcall(sp.playAudio, audio)
if not queued then error(accepted) end
if accepted then break end
coroutine.yield("speaker_audio_empty", state.speakerNames[i])
end
end
end
input.close()
state.playing = false
state.message = "Reproduccion terminada"
end, playbackFailed)
end

function M.touch(ctx, x, y)
if y == 6 and x < 9 then play(ctx)
elseif y == 6 and x < 19 then
state.stop = true
for _, sp in ipairs(state.speakers) do
if sp.stop then pcall(sp.stop) end
end
state.message = "Pausado; Play reinicia la pista"
elseif y == 6 then
state.stop = true
for _, sp in ipairs(state.speakers) do
if sp.stop then pcall(sp.stop) end
end
state.message = "Deteniendo..."
elseif y == 8 then scan()
elseif y >= 12 then
local index = y - 11
if state.tracks[index] then state.selected = index end
end
end

return M
]],
}

for path, content in pairs(FILES) do
local handle = fs.open(path, "w")
if handle then
handle.write(content)
handle.close()
print("OK: " .. path)
else
print("ERROR: " .. path)
end
end
print("Patch multi-speaker aplicado. Reinicia con: reboot")   
