local FILES={
['startup.lua']=[[local function c(y,t,fg)
local w,h=term.getSize()
if y<1 or y>h then return end
t=tostring(t)
if #t>w then t=t:sub(1,w) end
term.setCursorPos(math.max(1,math.floor((w-#t)/2)+1),y)
term.setTextColor(fg or colors.white)
term.setBackgroundColor(colors.black)
term.write(t)
end
local w,h=term.getSize()
local top=math.max(1,math.floor((h-10)/2)+1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
c(top+2,"ANDROID MOBILE",colors.lime)
c(top+3,"Music Edition",colors.lightGray)
local bw=math.min(16,math.max(4,w-4))
local bx=math.max(1,math.floor((w-bw)/2)+1)
local iw=math.max(1,bw-2)
for f=0,15 do
term.setCursorPos(bx,top+6)
term.setTextColor(colors.gray)
term.write("["..string.rep(" ",iw).."]")
term.setCursorPos(bx+1+(f%(iw+1)),top+6)
term.setBackgroundColor(colors.lime)
term.write(string.rep(" ",math.min(2,iw)))
c(top+8,"Iniciando...",colors.lightGray)
sleep(0.1)
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
local ok,err=pcall(function() require("sys.mobile.boot").run() end)
if not ok then
term.clear()
term.setTextColor(colors.red)
print("Error: "..tostring(err))
os.pullEvent("key")
end
]],
['sys/mobile/boot.lua']=[[local ui=require("sys.mobile.ui")
local sound=require("sys.mobile.sound")
local M={}
local function closeApp(ctx)
if ctx.app and ctx.app.close then pcall(ctx.app.close,ctx) end
ctx.app,ctx.appName=nil,nil
end
local function shutdown(ctx)
closeApp(ctx)
sound.play("shutdown",true)
term.setBackgroundColor(colors.black)
term.clear()
local _,h=term.getSize()
ui.center(math.floor(h/2),"Apagando...",colors.lightGray)
sleep(0.5)
os.shutdown()
end
local function startApp(name,ctx)
local ok,app=pcall(require,"apps."..name)
if not ok then print("Error: "..tostring(app)); return end
ctx.app=app
ctx.appName=name
if app.open then pcall(app.open,ctx) end
sound.play("action",true)
end
local function render(ctx)
local parent=term.current()
local w,h=term.getSize()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
if ctx.app then
ui.status(ctx)
ui.title(ctx,ctx.app)
local ok,err=pcall(ctx.app.draw,ctx)
if not ok then
ui.text(2,4,"Error:",colors.red)
ui.text(2,5,tostring(err),colors.red,nil,w)
end
else
ui.status(ctx)
local home=require("apps.home")
home.draw(ctx)
end
term.redirect(parent)
ui.dock(ctx)
end
local function isTouch(x,y,ctx)
local w,h=term.getSize()
local slot=math.max(1,math.floor(w/4))
if y==h then
if not ctx.app then
if x<=slot then startApp("music",ctx)
elseif x<=slot*2 then startApp("media",ctx)
else shutdown(ctx) end
else
if x<=slot then closeApp(ctx)
elseif x<=slot*2 then startApp("media",ctx)
else shutdown(ctx) end
end
return true
end
if ctx.app and y==2 and x>=w-2 then closeApp(ctx); return true end
if not ctx.app then
local home=require("apps.home")
home.touch(ctx,x,y,startApp)
return true
end
if ctx.app.touch then
local ok,err=pcall(ctx.app.touch,ctx,x,y)
if not ok then print("Error: "..tostring(err)) end
end
return true
end
function M.run()
sound.play("startup",true)
local ctx={app=nil,appName=nil,notifications={},power="--"}
local tick=os.startTimer(1)
while true do
render(ctx)
local event={os.pullEvent()}
if event[1]=="timer" and event[2]==tick then
tick=os.startTimer(1)
elseif event[1]=="mouse_click" then
sound.play("click",true)
isTouch(event[2],event[3],ctx)
elseif event[1]=="mouse_drag" and ctx.app and ctx.app.drag then
pcall(ctx.app.drag,ctx,event[2],event[3],event[4])
elseif ctx.app and ctx.app.event then
local ok,err=pcall(ctx.app.event,ctx,unpack(event))
if not ok then print("Error: "..tostring(err)) end
end
end
end
return M
]],
['sys/mobile/ui.lua']=[[local M={}
function M.text(x,y,value,fg,bg,maxW)
local w,h=term.getSize()
if y<1 or y>h or x>w then return end
value=tostring(value or "")
if maxW then value=value:sub(1,maxW) end
value=value:sub(1,math.max(0,w-x+1))
term.setCursorPos(math.max(1,x),y)
if fg then term.setTextColor(fg) end
if bg then term.setBackgroundColor(bg) end
term.write(value)
end
function M.center(y,value,fg,bg)
local w=term.getSize()
value=tostring(value or "")
M.text(math.max(1,math.floor((w-#value)/2)+1),y,value,fg,bg)
end
function M.fill(x,y,wd,ht,color)
local w,h=term.getSize()
term.setBackgroundColor(color or colors.black)
for row=math.max(1,y),math.min(h,y+ht-1) do
term.setCursorPos(math.max(1,x),row)
term.write(string.rep(" ",math.max(0,math.min(wd,w-x+1))))
end
end
function M.button(x,y,wd,label,bg,fg)
local w=term.getSize()
wd=math.max(1,math.min(wd,w-x+1))
M.fill(x,y,wd,1,bg or colors.gray)
local caption=tostring(label):sub(1,wd)
local left=x+math.max(0,math.floor((wd-#caption)/2))
M.text(left,y,caption,fg or colors.white,bg or colors.gray,wd)
end
function M.status(ctx)
local w=term.getSize()
M.fill(1,1,w,1,colors.black)
M.text(1,1," A",colors.lime,colors.black,3)
local ind=os.date("%H:%M")
M.text(w-#ind,1,ind,colors.white,colors.black,#ind)
end
function M.title(ctx,app,row)
local w=term.getSize()
row=row or 2
M.fill(1,row,w,1,colors.gray)
M.text(2,row,app.title or "App",colors.white,colors.gray,w-4)
M.fill(w-1,row,1,1,colors.red)
M.text(w-1,row,"X",colors.white,colors.red,1)
end
function M.dock(ctx)
local w,h=term.getSize()
local slot=math.max(1,math.floor(w/4))
M.fill(1,h,w,1,colors.black)
if not ctx.app then
M.button(1,h,slot,"Musica",colors.green,colors.black)
M.button(slot+1,h,slot,"Media",colors.blue,colors.white)
M.button(slot*2+1,h,w-slot*2,"Apagar",colors.red,colors.white)
else
M.button(1,h,slot,"Inicio",colors.gray,colors.white)
M.button(slot+1,h,slot,"Media",colors.blue,colors.white)
M.button(slot*2+1,h,w-slot*2,"Apagar",colors.red,colors.white)
end
end
return M
]],
['sys/mobile/sound.lua']=[[local M={}
local speakers
local function getSpeakers()
if speakers then return speakers end
speakers={}
if peripheral and peripheral.find then
local ok,found=pcall(peripheral.find,"speaker")
if ok and type(found)=="table" then
for _,sp in ipairs(found) do
if type(sp.playNote)=="function" then speakers[#speakers+1]=sp end
end
end
end
return speakers
end
function M.play(kind,enabled)
if enabled==false then return false end
local devs=getSpeakers()
if #devs==0 then return false end
local notes
if kind=="action" then notes={{"chime",0.5,17},{"pling",0.4,21}}
elseif kind=="startup" then notes={{"chime",0.5,12},{"bell",0.5,16},{"pling",0.5,19},{"chime",0.5,21},{"pling",0.4,24}}
elseif kind=="shutdown" then notes={{"pling",0.5,22},{"bell",0.5,19},{"chime",0.4,16},{"bell",0.4,12},{"chime",0.3,9}}
else notes={{"hat",0.3,18}}
end
local played=false
for _,dev in ipairs(devs) do
for _,note in ipairs(notes) do
played=pcall(dev.playNote,note[1],note[2],note[3]) or played
end
end
return played
end
return M
]],
['apps/home.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Inicio"}
local items={{"Musica","music",colors.green},{"Media","media",colors.blue},{"Apagar","shutdown",colors.red}}
function M.draw(ctx)
local w,h=term.getSize()
ui.fill(1,2,w,h-3,colors.black)
local clock=os.date("%H:%M")
ui.fill(2,2,w-3,2,colors.gray)
ui.center(2,clock,colors.white,colors.gray)
ui.text(2,5,os.date("%a %d %b"),colors.lightGray,colors.black,w-2)
for i,entry in ipairs(items) do
local y=8+(i-1)*3
if y<h-2 then
ui.fill(2,y,w-4,2,colors.black)
ui.fill(2,y,w-4,1,entry[3])
local label="["..entry[1].."]"
ui.center(y,label,entry[3]==colors.white and colors.black or colors.white,entry[3])
ui.text(3,y+1,entry[1],colors.white,colors.black,w-4)
end
end
end
function M.touch(ctx,x,y,startApp)
if y<8 then return end
local idx=math.floor((y-8)/3)+1
if items[idx] then
if items[idx][2]=="shutdown" then
local boot=require("sys.mobile.boot")
os.shutdown()
else
startApp(items[idx][2],ctx)
end
end
end
return M
]],
['apps/music.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Streaming Music"}
local API="https://ipod-2to6magyna-uc.a.run.app/"
local state={query="",results={},selected=1,page=1,msg="Busca una cancion.",searching=false,playing=false,stop=false,speakers={},spNames={},decoders={},now=nil,sUrl=nil,dUrl=nil}
local function compact(v,wd)
v=tostring(v or ""):gsub("[%c]"," ")
if #v>wd then return v:sub(1,wd-1).."~" end
return v
end
local function stopAll()
state.stop=true
for _,sp in ipairs(state.speakers) do if sp.stop then pcall(sp.stop) end end
for _,n in ipairs(state.spNames) do os.queueEvent("speaker_audio_empty",n) end
state.playing=false
state.speakers,state.spNames,state.decoders={},{},{}
end
local function doSearch(ctx)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
local _,h=term.getSize()
term.setCursorPos(1,math.max(1,h-1))
term.clearLine()
write("Buscar: ")
local query=read()
if not query or not query:match("%S") then return end
state.query,state.results,state.page=query,{},1
state.searching,state.msg=true,"Buscando..."
state.sUrl=API.."?v=2.1&search="..textutils.urlEncode(query)
pcall(http.request,state.sUrl)
end
local function playItem(ctx,item)
local all={peripheral.find("speaker")}
local valid={}
for _,sp in ipairs(all) do if type(sp.playAudio)=="function" then valid[#valid+1]=sp end end
if #valid==0 then state.msg="Necesita un speaker."; return end
local ok,dec=pcall(require,"cc.audio.dfpwm")
if not ok then state.msg="Necesita CC:Tweaked 1.100+."; return end
stopAll()
state.stop,state.playing,state.speakers,state.now=false,true,valid,item
state.spNames,state.decoders={},{}
for i,sp in ipairs(valid) do
local nOk,n=pcall(peripheral.getName,sp)
state.spNames[i]=nOk and n or nil
state.decoders[i]=dec.make_decoder()
end
state.msg="Cargando ("..#valid.." spk): "..compact(item.name,18)
state.dUrl=API.."?v=2.1&id="..textutils.urlEncode(item.id)
local ok,reason=pcall(http.request,{url=state.dUrl,binary=true})
if not ok then state.playing=false; state.msg="HTTP error: "..tostring(reason) end
end
function M.event(ctx,event,url,handle)
if event=="http_success" then
if url==state.sUrl then
local raw=handle.readAll(); handle.close()
local ok,data=pcall(textutils.unserialiseJSON,raw or "[]")
if not ok or type(data)~="table" then state.searching=false; state.msg="Respuesta invalida"; return end
state.results={}
for _,item in ipairs(data) do
if type(item)=="table" and item.id then
state.results[#state.results+1]={id=tostring(item.id),name=tostring(item.name or "?"),artist=tostring(item.artist or "YT")}
end
end
state.searching=false
state.msg=#state.results>0 and ("Resultados: "..#state.results) or "Sin resultados."
elseif url==state.dUrl then
local input=handle
local thread=coroutine.create(function()
local first=input.read(4)
if not first then input.close(); return end
local fc=true
while not state.stop do
local chunk=input.read(16380)
if not chunk then break end
if fc then chunk,fc=first..chunk,false end
for i,sp in ipairs(state.speakers) do
local audio=state.decoders[i](chunk)
while not state.stop and not sp.playAudio(audio) do
coroutine.yield("speaker_audio_empty",state.spNames[i])
end
end
end
input.close()
if not state.stop then state.msg="Terminado" end
state.playing=false
end)
coroutine.resume(thread)
end
elseif event=="http_failure" then
if url==state.sUrl then state.searching=false; state.msg="No se pudo conectar."
elseif url==state.dUrl then state.playing=false; state.msg="Error de descarga." end
end
end
function M.open()
state.results,state.selected,state.page={},1,1
state.msg="Busca una cancion de YouTube."
end
function M.close() stopAll() end
function M.draw()
local w,h=term.getSize()
ui.fill(2,3,math.max(1,w-3),1,colors.blue)
local spC=#state.speakers>0 and (" ["..#state.speakers.."spk]") or ""
ui.text(3,3,compact((state.now and ("~ "..state.now.name) or "Streaming Music")..spC,w-4),colors.white,colors.blue,w-4)
ui.button(2,5,8,"Buscar",colors.green,colors.black)
ui.button(12,5,7,"Parar",colors.red)
ui.text(2,7,compact(state.msg,w-2),state.searching and colors.gray or colors.blue,colors.white,w-2)
local first=(state.page-1)*math.max(1,h-10)+1
for idx=first,math.min(#state.results,first+h-11) do
local y,item=9+idx-first,state.results[idx]
ui.text(2,y,(idx==state.selected and "> " or " ")..compact(item.name,w-4),idx==state.selected and colors.blue or colors.black,colors.white,w-2)
if y+1<h-1 then ui.text(4,y+1,compact(item.artist,w-6),colors.gray,colors.white,w-4) end
end
end
function M.touch(ctx,x,y)
local _,h=term.getSize()
if y==5 and x<11 then doSearch(ctx); return end
if y==5 and x>=11 and x<20 then stopAll(); state.msg="Detenido"; return end
if y>=9 and y<h-1 then
local idx=(state.page-1)*math.max(1,h-10)+math.floor((y-9)/2)+1
if state.results[idx] then state.selected=idx; playItem(ctx,state.results[idx]) end
end
end
return M
]],
['apps/media.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Media Player"}
local state={tracks={},sel=1,playing=false,stop=false,speakers={},spNames={},decoders={},msg="DFPWM en /music"}
local function scan()
state.tracks={}
for _,dir in ipairs({"/music","/disk"}) do
if fs.exists(dir) and fs.isDir(dir) then
for _,name in ipairs(fs.list(dir)) do
if not fs.isDir(fs.combine(dir,name)) and name:lower():match("%.dfpwm$") then
state.tracks[#state.tracks+1]=fs.combine(dir,name)
end
end
end
end
if state.sel>#state.tracks then state.sel=math.max(1,#state.tracks) end
end
function M.open() scan() end
function M.close()
state.stop=true
for _,sp in ipairs(state.speakers) do if sp.stop then pcall(sp.stop) end end
state.playing=false
state.speakers,state.spNames,state.decoders={},{},{}
end
function M.draw()
local w,h=term.getSize()
ui.fill(2,3,w-3,2,colors.blue)
local spC=#state.speakers>0 and (" ["..#state.speakers.."spk]") or ""
ui.center(3,"Media Player"..spC,colors.white,colors.blue)
ui.button(2,6,7,"Play",colors.green,colors.black)
ui.button(10,6,8,"Stop",colors.red)
ui.button(20,6,8,"Scan",colors.gray)
ui.text(2,8,state.msg,colors.blue,colors.white,w-2)
for i,track in ipairs(state.tracks) do
local y=10+i-1
if y>=h-1 then break end
ui.text(2,y,(i==state.sel and "> " or " ")..fs.getName(track),i==state.sel and colors.blue or colors.black,colors.white,w-2)
end
end
local function play(ctx)
local path=state.tracks[state.sel]
if not path then state.msg="Sin pistas .dfpwm"; return end
if state.playing then state.msg="Ya sonando"; return end
local all={peripheral.find("speaker")}
local valid={}
for _,sp in ipairs(all) do if type(sp.playAudio)=="function" then valid[#valid+1]=sp end end
if #valid==0 then state.msg="Necesita un speaker"; return end
local ok,dec=pcall(require,"cc.audio.dfpwm")
if not ok then state.msg="Necesita cc.audio.dfpwm"; return end
local input,err=fs.open(path,"rb")
if not input then state.msg=tostring(err); return end
state.speakers,state.stop,state.playing=valid,false,true
state.spNames,state.decoders={},{}
for i,sp in ipairs(valid) do
local nOk,n=pcall(peripheral.getName,sp)
state.spNames[i]=nOk and n or nil
state.decoders[i]=dec.make_decoder()
end
state.msg="Sonando ("..#valid.." spk): "..fs.getName(path)
local thread=coroutine.create(function()
while not state.stop do
local comp=input.read(8192)
if not comp then break end
for i,sp in ipairs(state.speakers) do
local audio=state.decoders[i](comp)
while not state.stop do
local q,a=pcall(sp.playAudio,audio)
if not q then error(a) end
if a then break end
coroutine.yield("speaker_audio_empty",state.spNames[i])
end
end
end
input.close()
state.playing=false
state.msg="Terminado"
end)
coroutine.resume(thread)
end
function M.touch(ctx,x,y)
if y==6 and x<9 then play(ctx)
elseif y==6 and x<19 then
state.stop=true
for _,sp in ipairs(state.speakers) do if sp.stop then pcall(sp.stop) end end
state.playing=false
state.msg="Detenido"
elseif y==6 then scan()
elseif y>=10 then
local idx=y-9
if state.tracks[idx] then state.sel=idx end
end
end
return M
]],
}
for path,content in pairs(FILES) do
local dir=fs.getDir(path)
if dir~="" and dir~="/" and not fs.exists(dir) then
local p=dir
while p~="" and p~="/" and not fs.exists(p) do
fs.makeDir(p)
p=fs.getDir(p)
end
if not fs.exists(dir) then fs.makeDir(dir) end
end
local f=fs.open(path,"w")
if f then f.write(content); f.close(); print("OK: "..path)
else print("ERR: "..path) end
end
print("Instalado. Reinicia con: reboot")   
