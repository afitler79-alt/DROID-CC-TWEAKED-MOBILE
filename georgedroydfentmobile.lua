local F={
['startup.lua']=[[term.setBackgroundColor(colors.black);term.setTextColor(colors.white);term.clear()
local w,h=term.getSize()
local t=math.floor((h-8)/2)+1
term.setTextColor(colors.lime)
term.setCursorPos(math.max(1,math.floor((w-14)/2)+1),t+2);term.write("ANDROID MOBILE")
term.setTextColor(colors.lightGray)
term.setCursorPos(math.max(1,math.floor((w-10)/2)+1),t+3);term.write("Music Edition")
local bw=math.min(14,math.max(4,w-4));local bx=math.max(1,math.floor((w-bw)/2)+1);local iw=bw-2
for f=0,12 do
term.setCursorPos(bx,t+6);term.setTextColor(colors.gray);term.write("["..string.rep(" ",iw).."]")
term.setCursorPos(bx+1+(f%(iw+1)),t+6);term.setBackgroundColor(colors.lime);term.write("  ")
sleep(0.1)
end
term.setBackgroundColor(colors.black)
local ok,e=pcall(function()require("sys.mobile.boot").run()end)
if not ok then term.setTextColor(colors.red);print("Error: "..tostring(e));os.pullEvent("key") end
]],
['sys/mobile/boot.lua']=[[local ui=require("sys.mobile.ui");local snd=require("sys.mobile.sound");local M={}
local function startApp(n,ctx)
local ok,app=pcall(require,"apps."..n)
if not ok then print("Err: "..tostring(app));return end
ctx.app=app;ctx.appName=n
if app.open then pcall(app.open,ctx) end
snd.play("action",true)
end
local function closeApp(ctx)
if ctx.app and ctx.app.close then pcall(ctx.app.close,ctx) end
ctx.app,ctx.appName=nil,nil
end
local function shutdown(ctx)
closeApp(ctx);snd.play("shutdown",true)
term.setBackgroundColor(colors.black);term.clear()
ui.center(math.floor(term.getSize()/2),"Apagando...",colors.lightGray)
sleep(0.4);os.shutdown()
end
local function render(ctx)
local p=term.current();local w,h=term.getSize()
term.setBackgroundColor(colors.black);term.setTextColor(colors.white);term.clear()
if ctx.app then
ui.status(ctx);ui.title(ctx,ctx.app)
local ok,e=pcall(ctx.app.draw,ctx)
if not ok then ui.text(2,4,"Error:",colors.red);ui.text(2,5,tostring(e),colors.red) end
else
ui.status(ctx);require("apps.home").draw(ctx)
end
term.redirect(p);ui.dock(ctx)
end
local function touch(x,y,ctx)
local w,h=term.getSize();local s=math.max(1,math.floor(w/4))
if y==h then
if not ctx.app then
if x<=s then startApp("music",ctx)
elseif x<=s*2 then startApp("media",ctx)
else shutdown(ctx) end
else
if x<=s then closeApp(ctx)
elseif x<=s*2 then startApp("media",ctx)
else shutdown(ctx) end
end
return true
end
if ctx.app and y==2 and x>=w-2 then closeApp(ctx);return true end
if not ctx.app then
require("apps.home").touch(ctx,x,y,startApp)
return true
end
if ctx.app.touch then pcall(ctx.app.touch,ctx,x,y) end
return true
end
local function handleKey(key,ctx)
if not ctx.app then
local ok,handled=require("apps.home").key(ctx,key)
if handled then return true end
return false
end
if ctx.app.key then
local ok,handled=pcall(ctx.app.key,ctx,key)
if ok and handled then return true end
end
if key==keys.escape then closeApp(ctx);return true end
return false
end
function M.run()
snd.play("startup",true)
local ctx={app=nil,appName=nil}
local tick=os.startTimer(1)
while true do
render(ctx)
local ev={os.pullEvent()}
if ev[1]=="timer" and ev[2]==tick then tick=os.startTimer(1)
elseif ev[1]=="mouse_click" then snd.play("click",true);touch(ev[2],ev[3],ctx)
elseif ev[1]=="key" then handleKey(ev[2],ctx)
elseif ctx.app and ctx.app.event then pcall(ctx.app.event,ctx,unpack(ev))
end
end
end
return M
]],
['sys/mobile/ui.lua']=[[local M={}
function M.text(x,y,v,fg,bg,mw)
local w,h=term.getSize()
if y<1 or y>h or x>w then return end
v=tostring(v or "")
if mw then v=v:sub(1,mw) end
v=v:sub(1,math.max(0,w-x+1))
term.setCursorPos(math.max(1,x),y)
if fg then term.setTextColor(fg) end
if bg then term.setBackgroundColor(bg) end
term.write(v)
end
function M.center(y,v,fg,bg)
local w=term.getSize();v=tostring(v or "")
M.text(math.max(1,math.floor((w-#v)/2)+1),y,v,fg,bg)
end
function M.fill(x,y,wd,ht,c)
local w,h=term.getSize()
term.setBackgroundColor(c or colors.black)
for r=math.max(1,y),math.min(h,y+ht-1) do
term.setCursorPos(math.max(1,x),r)
term.write(string.rep(" ",math.max(0,math.min(wd,w-x+1))))
end
end
function M.btn(x,y,wd,l,bg,fg)
local w=term.getSize();wd=math.max(1,math.min(wd,w-x+1))
M.fill(x,y,wd,1,bg or colors.gray)
local c=tostring(l):sub(1,wd)
M.text(x+math.max(0,math.floor((wd-#c)/2)),y,c,fg or colors.white,bg or colors.gray,wd)
end
function M.status(ctx)
local w=term.getSize()
M.fill(1,1,w,1,colors.black)
M.text(1,1,"A",colors.lime,colors.black,1)
local t=os.date("%H:%M")
M.text(w-#t,1,t,colors.white,colors.black,#t)
end
function M.title(ctx,app,row)
local w=term.getSize();row=row or 2
M.fill(1,row,w,1,colors.gray)
M.text(2,row,app.title or "App",colors.white,colors.gray,w-3)
M.fill(w-1,row,1,1,colors.red)
M.text(w-1,row,"X",colors.white,colors.red,1)
end
function M.dock(ctx)
local w,h=term.getSize();local s=math.max(1,math.floor(w/4))
M.fill(1,h,w,1,colors.black)
if not ctx.app then
M.btn(1,h,s,"Musica",colors.green,colors.black)
M.btn(s+1,h,s,"Media",colors.blue,colors.white)
M.btn(s*2+1,h,w-s*2,"Apagar",colors.red,colors.white)
else
M.btn(1,h,s,"Inicio",colors.gray,colors.white)
M.btn(s+1,h,s,"Media",colors.blue,colors.white)
M.btn(s*2+1,h,w-s*2,"Apagar",colors.red,colors.white)
end
end
return M
]],
['sys/mobile/sound.lua']=[[local M={}
local sp
local function get()
if sp then return sp end
sp={}
if peripheral and peripheral.find then
local ok,f=pcall(peripheral.find,"speaker")
if ok and type(f)=="table" then
for _,s in ipairs(f) do if type(s.playNote)=="function" then sp[#sp+1]=s end end
end
end
return sp
end
function M.play(k,en)
if en==false then return false end
local d=get()
if #d==0 then return false end
local n
if k=="action" then n={{"chime",.5,17},{"pling",.4,21}}
elseif k=="startup" then n={{"chime",.5,12},{"bell",.5,16},{"pling",.5,19},{"chime",.5,21},{"pling",.4,24}}
elseif k=="shutdown" then n={{"pling",.5,22},{"bell",.5,19},{"chime",.4,16},{"bell",.4,12},{"chime",.3,9}}
else n={{"hat",.3,18}}
end
local p=false
for _,dev in ipairs(d) do for _,nt in ipairs(n) do p=pcall(dev.playNote,nt[1],nt[2],nt[3])or p end end
return p
end
return M
]],
['apps/home.lua']=[[local ui=require("sys.mobile.ui");local M={title="Inicio"}
local items={{"Musica","music",colors.green},{"Media","media",colors.blue},{"Apagar","shutdown",colors.red}}
local cursor=1
local ICON_X=2;local ICON_W=20;local ICON_Y0=8;local ICON_H=3
function M.draw(ctx)
local w,h=term.getSize()
ui.fill(1,2,w,h-3,colors.black)
ui.fill(2,2,w-3,2,colors.gray)
ui.center(2,os.date("%H:%M"),colors.white,colors.gray)
ui.text(2,5,os.date("%a %d %b"),colors.lightGray,colors.black,w-2)
for i,e in ipairs(items) do
local y=ICON_Y0+(i-1)*ICON_H
if y+1<h-2 then
local sel=i==cursor
local bg=sel and colors.white or colors.black
local fg=sel and colors.black or e[3]
ui.fill(ICON_X,y,ICON_W,ICON_H,bg)
ui.fill(ICON_X,y,ICON_W,1,sel and e[3] or e[3])
ui.text(ICON_X+1,y,"["..e[1].."]",sel and colors.white or e[3],e[3],ICON_W-2)
ui.text(ICON_X+1,y+1,e[1],fg,bg,ICON_W-2)
if sel then
ui.text(ICON_X+1,y+2,"> ENTER para abrir",colors.gray,bg,ICON_W-2)
end
end
end
ui.text(2,h-2,"Flechas: mover | Enter: seleccionar | Esc: volver",colors.gray,colors.black,w-2)
end
function M.touch(ctx,x,y,startApp)
for i,e in ipairs(items) do
local iy=ICON_Y0+(i-1)*ICON_H
if x>=ICON_X and x<ICON_X+ICON_W and y>=iy and y<iy+ICON_H then
cursor=i
if e[2]=="shutdown" then os.shutdown()
else startApp(e[2],ctx) end
return
end
end
end
function M.key(ctx,key)
if key==keys.up then
cursor=cursor>1 and cursor-1 or #items
return true
elseif key==keys.down then
cursor=cursor<#items and cursor+1 or 1
return true
elseif key==keys.enter then
local e=items[cursor]
if e[2]=="shutdown" then os.shutdown()
else
local startApp=function(n,ctx)
local ok,app=pcall(require,"apps."..n)
if not ok then return end
ctx.app=app;ctx.appName=n
if app.open then pcall(app.open,ctx) end
end
startApp(e[2],ctx)
end
return true
end
return false
end
return M
]],
['apps/music.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Streaming Music"}
local API="https://ipod-2to6magyna-uc.a.run.app/"
local S={q="",r={},sel=1,pg=1,msg="Busca una cancion.",srch=false,play=false,stop=false,sp={},sn={},dc={},now=nil,sU=nil,dU=nil}
local function ct(v,w)
v=tostring(v or ""):gsub("[%c]"," ")
if #v>w then return v:sub(1,w-1).."~" end
return v
end
local function stop()
S.stop=true
for _,s in ipairs(S.sp) do if s.stop then pcall(s.stop) end end
for _,n in ipairs(S.sn) do os.queueEvent("speaker_audio_empty",n) end
S.play=false;S.sp,S.sn,S.dc={},{},{}
end
local function srch(ctx)
term.setBackgroundColor(colors.black);term.setTextColor(colors.white)
local _,h=term.getSize()
term.setCursorPos(1,math.max(1,h-1));term.clearLine()
write("Buscar: ")
local q=read()
if not q or not q:match("%S") then return end
S.q,S.r,S.pg=q,{},1
S.srch,S.msg=true,"Buscando..."
S.sU=API.."?v=2.1&search="..textutils.urlEncode(q)
pcall(http.request,S.sU)
end
local function play(ctx,item)
local all={peripheral.find("speaker")}
local v={}
for _,s in ipairs(all) do if type(s.playAudio)=="function" then v[#v+1]=s end end
if #v==0 then S.msg="Necesita speaker.";return end
local ok,dc=pcall(require,"cc.audio.dfpwm")
if not ok then S.msg="Necesita CC:Tweaked 1.100+.";return end
stop()
S.stop,S.play,S.sp,S.now=false,true,v,item
S.sn,S.dc={},{}
for i,s in ipairs(v) do
local o,n=pcall(peripheral.getName,s)
S.sn[i]=o and n or nil
S.dc[i]=dc.make_decoder()
end
S.msg="Cargando ("..#v.."spk): "..ct(item.name,18)
S.dU=API.."?v=2.1&id="..textutils.urlEncode(item.id)
local ok,r=pcall(http.request,{url=S.dU,binary=true})
if not ok then S.play=false;S.msg="HTTP: "..tostring(r) end
end
function M.event(ctx,ev,url,h)
if ev=="http_success" then
if url==S.sU then
local raw=h.readAll();h.close()
local ok,d=pcall(textutils.unserialiseJSON,raw or "[]")
if not ok or type(d)~="table" then S.srch=false;S.msg="Respuesta invalida";return end
S.r={}
for _,it in ipairs(d) do
if type(it)=="table" and it.id then
S.r[#S.r+1]={id=tostring(it.id),name=tostring(it.name or "?"),artist=tostring(it.artist or "YT")}
end
end
S.srch=false
S.msg=#S.r>0 and ("Resultados: "..#S.r) or "Sin resultados."
elseif url==S.dU then
local inp=h
local th=coroutine.create(function()
local f=inp.read(4)
if not f then inp.close();return end
local fc=true
while not S.stop do
local c=inp.read(16380)
if not c then break end
if fc then c,fc=f..c,false end
for i,s in ipairs(S.sp) do
local a=S.dc[i](c)
while not S.stop and not s.playAudio(a) do
coroutine.yield("speaker_audio_empty",S.sn[i])
end
end
end
inp.close()
if not S.stop then S.msg="Terminado" end
S.play=false
end)
coroutine.resume(th)
end
elseif ev=="http_failure" then
if url==S.sU then S.srch=false;S.msg="No se pudo conectar."
elseif url==S.dU then S.play=false;S.msg="Error descarga." end
end
end
function M.open() S.r,S.sel,S.pg={},1,1;S.msg="Busca una cancion de YouTube." end
function M.close() stop() end
function M.draw()
local w,h=term.getSize()
ui.fill(2,3,math.max(1,w-3),1,colors.blue)
local sc=#S.sp>0 and (" ["..#S.sp.."spk]") or ""
ui.text(3,3,ct((S.now and ("~ "..S.now.name) or "Streaming Music")..sc,w-4),colors.white,colors.blue,w-4)
ui.btn(2,5,8,"Buscar",colors.green,colors.black)
ui.btn(12,5,7,"Parar",colors.red)
ui.text(2,7,ct(S.msg,w-2),S.srch and colors.gray or colors.blue,colors.white,w-2)
local f=(S.pg-1)*math.max(1,h-10)+1
for i=f,math.min(#S.r,f+h-11) do
local y,it=9+i-f,S.r[i]
local sel=i==S.sel
ui.text(2,y,(sel and "> " or " ")..ct(it.name,w-4),sel and colors.yellow or colors.black,colors.white,w-2)
if y+1<h-1 then ui.text(4,y+1,ct(it.artist,w-6),colors.gray,colors.white,w-4) end
end
ui.text(2,h-2,"Flechas: navegar | Enter: reproducir | Esc: volver",colors.gray,colors.black,w-2)
end
function M.touch(ctx,x,y)
local _,h=term.getSize()
if y==5 and x<11 then srch(ctx);return end
if y==5 and x>=11 and x<20 then stop();S.msg="Detenido";return end
if y>=9 and y<h-2 then
local i=(S.pg-1)*math.max(1,h-10)+math.floor((y-9)/2)+1
if S.r[i] then S.sel=i;play(ctx,S.r[i]) end
end
end
function M.key(ctx,key)
if key==keys.up then
S.sel=S.sel>1 and S.sel-1 or 1
if S.sel<(S.pg-1)*math.max(1,term.getSize()/2)+1 then S.pg=1 end
return true
elseif key==keys.down then
S.sel=S.sel<#S.r and S.sel+1 or #S.r
local perPg=math.max(1,term.getSize()/2)
if S.sel>S.pg*perPg then S.pg=math.ceil(S.sel/perPg) end
return true
elseif key==keys.enter then
if #S.r==0 then srch(ctx); return true end
local item=S.r[S.sel]
if item then play(ctx,item) end
return true
end
return false
end
return M
]],
['apps/media.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Media Player"}
local S={t={},sel=1,play=false,stop=false,sp={},sn={},dc={},msg="DFPWM en /music"}
local function scan()
S.t={}
for _,d in ipairs({"/music","/disk"}) do
if fs.exists(d) and fs.isDir(d) then
for _,n in ipairs(fs.list(d)) do
if not fs.isDir(fs.combine(d,n)) and n:lower():match("%.dfpwm$") then
S.t[#S.t+1]=fs.combine(d,n)
end
end
end
end
if S.sel>#S.t then S.sel=math.max(1,#S.t) end
end
function M.open() scan() end
function M.close()
S.stop=true
for _,s in ipairs(S.sp) do if s.stop then pcall(s.stop) end end
S.play=false;S.sp,S.sn,S.dc={},{},{}
end
function M.draw()
local w,h=term.getSize()
ui.fill(2,3,w-3,2,colors.blue)
local sc=#S.sp>0 and (" ["..#S.sp.."spk]") or ""
ui.center(3,"Media Player"..sc,colors.white,colors.blue)
ui.btn(2,6,7,"Play",colors.green,colors.black)
ui.btn(10,6,8,"Stop",colors.red)
ui.btn(20,6,8,"Scan",colors.gray)
ui.text(2,8,S.msg,colors.blue,colors.white,w-2)
for i,tr in ipairs(S.t) do
local y=10+i-1
if y>=h-2 then break end
local sel=i==S.sel
ui.text(2,y,(sel and "> " or " ")..fs.getName(tr),sel and colors.yellow or colors.black,colors.white,w-2)
end
ui.text(2,h-2,"Flechas: navegar | Enter: reproducir | Esc: volver",colors.gray,colors.black,w-2)
end
local function play(ctx)
local p=S.t[S.sel]
if not p then S.msg="Sin pistas .dfpwm";return end
if S.play then S.msg="Ya sonando";return end
local all={peripheral.find("speaker")}
local v={}
for _,s in ipairs(all) do if type(s.playAudio)=="function" then v[#v+1]=s end end
if #v==0 then S.msg="Necesita speaker";return end
local ok,dc=pcall(require,"cc.audio.dfpwm")
if not ok then S.msg="Necesita cc.audio.dfpwm";return end
local inp,e=fs.open(p,"rb")
if not inp then S.msg=tostring(e);return end
S.sp,S.stop,S.play=v,false,true
S.sn,S.dc={},{}
for i,s in ipairs(v) do
local o,n=pcall(peripheral.getName,s)
S.sn[i]=o and n or nil
S.dc[i]=dc.make_decoder()
end
S.msg="Sonando ("..#v.."spk): "..fs.getName(p)
local th=coroutine.create(function()
while not S.stop do
local c=inp.read(8192)
if not c then break end
for i,s in ipairs(S.sp) do
local a=S.dc[i](c)
while not S.stop do
local q,ac=pcall(s.playAudio,a)
if not q then error(ac) end
if ac then break end
coroutine.yield("speaker_audio_empty",S.sn[i])
end
end
end
inp.close()
S.play=false;S.msg="Terminado"
end)
coroutine.resume(th)
end
function M.touch(ctx,x,y)
if y==6 and x<9 then play(ctx)
elseif y==6 and x<19 then
S.stop=true
for _,s in ipairs(S.sp) do if s.stop then pcall(s.stop) end end
S.play=false;S.msg="Detenido"
elseif y==6 then scan()
elseif y>=10 and y<h-2 then
local i=y-9
if S.t[i] then S.sel=i end
end
end
function M.key(ctx,key)
if key==keys.up then
S.sel=S.sel>1 and S.sel-1 or 1
return true
elseif key==keys.down then
S.sel=S.sel<#S.t and S.sel+1 or #S.t
return true
elseif key==keys.enter then
play(ctx)
return true
end
return false
end
return M
]],
}
for p,c in pairs(F) do
local d=fs.getDir(p)
if d~="" and d~="/" and not fs.exists(d) then
local t=d
while t~="" and t~="/" and not fs.exists(t) do
fs.makeDir(t);t=fs.getDir(t)
end
if not fs.exists(d) then fs.makeDir(d) end
end
local f=fs.open(p,"w")
if f then f.write(c);f.close();print("OK: "..p)
else print("ERR: "..p) end
end
print("Listo. Reinicia con: reboot")   
