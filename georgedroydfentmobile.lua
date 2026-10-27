local FILES={
['startup.lua']=[[local function drawCentered(y,text,fg)
local w,h=term.getSize()
if y<1 or y>h then return end
text=tostring(text)
if #text>w then text=text:sub(1,w) end
term.setCursorPos(math.max(1,math.floor((w-#text)/2)+1),y)
if type(term.isColor)~="function" or not term.isColor() then fg=colors.white end
term.setTextColor(fg or colors.white)
term.setBackgroundColor(colors.black)
term.write(text)
end
local function anim()
local w,h=term.getSize()
local top=math.max(1,math.floor((h-12)/2)+1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
drawCentered(top+3,"ANDROID",colors.lime)
drawCentered(top+4,"MOBILE",colors.white)
drawCentered(top+5,"Classic 2.x launcher",colors.lightGray)
local bw=math.min(20,math.max(4,w-4))
local bx=math.max(1,math.floor((w-bw)/2)+1)
local by=top+9
local iw=math.max(1,bw-2)
for f=0,17 do
if by>=1 and by<=h and bx+bw-1<=w then
term.setCursorPos(bx,by)
term.setTextColor(colors.gray)
term.setBackgroundColor(colors.black)
term.write("["..string.rep(" ",iw).."]")
local bwd=math.min(3,iw)
local tr=math.max(0,iw-bwd)
term.setCursorPos(bx+1+(f%(tr+1)),by)
term.setBackgroundColor(type(term.isColor)=="function" and term.isColor() and colors.lime or colors.white)
term.write(string.rep(" ",bwd))
end
drawCentered(top+11,"Iniciando...",colors.lightGray)
sleep(0.1)
end
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
local ok,err=pcall(function()
anim()
require("sys.mobile.boot").run()
end)
if not ok then
term.setBackgroundColor(colors.black)
term.setTextColor(type(term.isColor)=="function" and term.isColor() and colors.red or colors.white)
term.clear()
term.setCursorPos(1,1)
print("Android Mobile: error de inicio")
print(tostring(err))
print("")
print("Comprueba que /sys/mobile y /apps")
print("estén instalados. Pulsa una tecla.")
os.pullEvent("key")
end
]],
['sys/mobile/boot.lua']=[[local ui=require("sys.mobile.ui")
local sensors=require("sys.mobile.sensors")
local sound=require("sys.mobile.sound")
local unpackValues=table.unpack or unpack
local M={}
local SETTINGS="/sys/mobile/settings"
local function loadSettings()
local defaults={playerRange=32,createPeripheral="",createOutputs={clutch="back",gearbox="left",sequencer="right"},createOutputMode="redstone",clickSounds=true,bookmarks={{ "Wikipedia","https://en.wikipedia.org" },{ "DuckDuckGo","https://lite.duckduckgo.com/lite/" },{ "BBC News","https://feeds.bbci.co.uk/news/rss.xml" }}}
if fs.exists(SETTINGS) then
local file=fs.open(SETTINGS,"r")
local raw=file and file.readAll()
if file then file.close() end
local ok,loaded=pcall(textutils.unserialize,raw or "")
if ok and type(loaded)=="table" then
for k,v in pairs(loaded) do defaults[k]=v end
end
end
return defaults
end
local function saveSettings(s)
local file,err=fs.open(SETTINGS,"w")
if not file then return nil,err end
file.write(textutils.serialize(s))
file.close()
return true
end
local function startApp(name,ctx)
local ok,app=pcall(require,"apps."..name)
if not ok then ctx.notify("No se pudo abrir "..name..": "..tostring(app)); return end
ctx.app=app
ctx.appName=name
if app.open then
local good,err=pcall(app.open,ctx)
if not good then ctx.notify(tostring(err)) end
end
if ctx.playSound then ctx.playSound("action") end
end
local function toggleSplit(ctx)
if ctx.split then
if ctx.splitApp and ctx.splitApp.close then pcall(ctx.splitApp.close,ctx) end
ctx.split,ctx.splitApp=false,nil
if ctx.playSound then ctx.playSound("action") end
return
end
if not ctx.app then ctx.notify("Abre una aplicacion antes de activar Split."); return end
local _,height=term.getSize()
if not window or height<18 then ctx.notify("Split requiere API window y al menos 18 filas."); return end
local moduleName=ctx.appName=="radar" and "home" or "radar"
local ok,app=pcall(require,"apps."..moduleName)
if not ok then ctx.notify("No se pudo abrir panel dividido: "..tostring(app)); return end
ctx.splitApp,ctx.split=app,true
if app.open then
local opened,err=pcall(app.open,ctx)
if not opened then ctx.notify("Split: "..tostring(err)) end
end
if ctx.playSound then ctx.playSound("action") end
end
local function closeApp(ctx)
if ctx.app and ctx.app.close then pcall(ctx.app.close,ctx) end
if ctx.splitApp and ctx.splitApp.close then pcall(ctx.splitApp.close,ctx) end
ctx.app,ctx.appName,ctx.split,ctx.splitApp=nil,nil,false,nil
end
local function drawShutdownAnimation()
local w,h=term.getSize()
local cy=math.max(1,math.floor(h/2))
local bw=math.min(20,math.max(1,w-4))
local bx=math.max(1,math.floor((w-bw)/2)+1)
local by=math.min(h,cy+2)
local iw=math.max(1,bw-2)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
for f=0,11 do
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
ui.center(math.max(1,cy-2),"Android Mobile",colors.white,colors.black)
ui.center(cy,"Apagando...",colors.lightGray,colors.black)
if bw>=3 and bx+bw-1<=w then
term.setCursorPos(bx,by)
term.setTextColor(ui.isBasicMode() and colors.white or colors.gray)
term.write("["..string.rep(" ",iw).."]")
local rem=math.max(0,iw-math.floor(f*iw/11))
if rem>0 then
term.setCursorPos(bx+1,by)
term.setBackgroundColor(ui.isBasicMode() and colors.white or colors.blue)
term.write(string.rep(" ",rem))
end
end
sleep(0.08)
end
term.setBackgroundColor(colors.black)
term.setTextColor(ui.isBasicMode() and colors.white or colors.lightGray)
term.clear()
ui.center(cy,"Ya puedes apagar el equipo.",colors.lightGray,colors.black)
sleep(0.35)
term.setBackgroundColor(colors.black)
term.clear()
end
local function shutdown(ctx)
closeApp(ctx)
sound.play("shutdown",ctx.settings.clickSounds)
drawShutdownAnimation()
os.shutdown()
end
local function resumeJobs(ctx,event)
for i=#ctx.jobs,1,-1 do
local job=ctx.jobs[i]
local matches=job.waitFor==nil or event[1]=="timer" or (event[1]==job.waitFor and (job.target==nil or event[2]==job.target))
if matches then
local ok,waitFor,target=coroutine.resume(job.thread)
if not ok then
table.remove(ctx.jobs,i)
if job.onError then pcall(job.onError,waitFor) end
ctx.notify("Tarea en segundo plano: "..tostring(waitFor))
elseif coroutine.status(job.thread)=="dead" then
table.remove(ctx.jobs,i)
else
job.waitFor,job.target=waitFor,target
end
end
end
end
local function drawHome(ctx)
local home=require("apps.home")
home.draw(ctx)
end
local function render(ctx)
local parent=term.current()
local w,h=term.getSize()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
local canSplit=ctx.split and ctx.splitApp and window and h>=18
if canSplit then
local ph=math.floor((h-2)/2)
local topOk,top=pcall(window.create,parent,1,1,w,ph+1,true)
local botOk,bot=pcall(window.create,parent,1,ph+1,w,h-ph,true)
if topOk and botOk then
term.redirect(top)
ui.title(ctx,ctx.app,2)
local f1,e1=pcall(ctx.app.draw,ctx)
if not f1 then ctx.notify("Split: "..tostring(e1)) end
term.redirect(bot)
ui.title(ctx,ctx.splitApp,2)
local f2,e2=pcall(ctx.splitApp.draw,ctx)
if not f2 then ctx.notify("Split: "..tostring(e2)) end
term.redirect(parent)
else
term.redirect(parent)
ctx.notify("No se pudieron crear las ventanas divididas.")
end
elseif ctx.app then
ui.status(ctx)
ui.title(ctx,ctx.app)
local ok,err=pcall(ctx.app.draw,ctx)
if not ok then
ui.text(2,4,"Error de aplicación:",colors.red,colors.black)
ui.text(2,5,tostring(err),colors.red,colors.black,term.getSize())
end
else
ui.status(ctx)
drawHome(ctx)
end
if ctx.menu then
local w,h=term.getSize()
if ui.isBasicMode() then
local items={"Archivos","Calculadora","Notas","Reloj","Mapa","Apagar"}
local x,y=1,math.max(2,h-8)
local pw=math.min(w,20)
ui.fill(x,y,pw,math.min(8,h-y),colors.black)
ui.fill(x,y,pw,1,colors.white)
ui.text(x+1,y,"BASIC MENU",colors.black,colors.white,pw-2)
for r,label in ipairs(items) do
local ry=y+r
if ry<h then
local fg=r%2==0 and colors.black or colors.white
local bg=r%2==0 and colors.white or colors.black
ui.fill(x,ry,pw,1,bg)
ui.text(x+1,ry,r..". "..label,fg,bg,pw-2)
end
end
else
local x,y=1,math.max(2,h-8)
local pw=math.min(w,28)
local cw=math.max(1,math.floor(pw/2))
ui.fill(x,y,pw,8,colors.lightGray)
ui.fill(x,y,pw,1,colors.blue)
ui.text(x+1,y,"Programas",colors.white,colors.blue,pw-2)
if x+pw<=w then ui.fill(x+pw,y+1,1,7,colors.gray) end
if y+8<h then ui.fill(x+1,y+8,pw,1,colors.gray) end
local pages={{ {"IE Mobile","Radar","Messenger","Create","GPS" },{ "Archivos","Ajustes","Pocket CMD","Geo Scanner","Split","Mapa" } },{ {"Calculadora","Notas","Reloj","Redstone","Inventario" },{ "Media","Inicio","Apagar","YouTube","Música" } }}
local entries=pages[ctx.menuPage or 1]
for r=1,6 do
local ry=y+r
for c=1,2 do
local label=entries[c][r]
if label and label~="" then
local cx=x+(c-1)*cw
local color=r%2==0 and colors.white or colors.lightGray
ui.fill(cx,ry,math.min(cw,pw-(c-1)*cw),1,color)
ui.text(cx+1,ry,label,colors.blue,color,math.max(1,cw-2))
end
end
end
local fy=y+7
ui.text(x+1,fy,ctx.menuPage==2 and "< Apps 2/2" or "Apps 1/2 >",colors.blue,colors.lightGray,pw-2)
end
end
term.redirect(parent)
ui.status(ctx)
ui.dock(ctx)
end
local function isTouch(ev,x,y,ctx)
local w,h=term.getSize()
local slot=math.max(1,math.floor(w/4))
if ctx.menu and ui.isBasicMode() then
if y==h then ctx.menu=false; return true end
local mt=math.max(2,h-8)
local row=y-mt
local actions={"explorer","calculator","notes","clock","map","shutdown"}
if x<=math.min(w,20) and row>=1 and row<=#actions and y<h then
ctx.menu=false
if actions[row]=="shutdown" then shutdown(ctx) else startApp(actions[row],ctx) end
else ctx.menu=false end
return true
end
if ctx.menu then
if y==h then ctx.menu=false; return true end
local mt=math.max(2,h-8)
if x>=1 and x<=math.min(w,28) and y==mt+7 then
ctx.menuPage=ctx.menuPage==2 and 1 or 2
return true
end
if x>=1 and x<=math.min(w,28) and y>mt and y<=mt+6 then
local cw=math.max(1,math.floor(math.min(w,28)/2))
local col=x>cw and 2 or 1
local row=y-mt
local pages={{ {"ie","radar","messenger","create","gps" },{ "explorer","settings","cmd","ores","split","map" } },{ {"calculator","notes","clock","redstone","inventory" },{ "media","home","shutdown","youtube","music" } }}
local action=pages[ctx.menuPage or 1][col][row]
ctx.menu=false
if action=="split" then toggleSplit(ctx)
elseif action and action~="" and action~="home" and action~="shutdown" then startApp(action,ctx)
elseif action=="home" then closeApp(ctx)
elseif action=="shutdown" then shutdown(ctx) end
return true
end
ctx.menu=false
end
if y==h then
if not ctx.app then
if ui.isBasicMode() then
if x<=slot then startApp("explorer",ctx)
elseif x<=slot*2 then ctx.menu=not ctx.menu
elseif x<=slot*3 then startApp("notes",ctx)
else startApp("clock",ctx) end
elseif x<=slot then startApp("gps",ctx)
elseif x<=slot*2 then ctx.menu=not ctx.menu
elseif x<=slot*3 then startApp("messenger",ctx)
else startApp("ie",ctx) end
return true
elseif x<=slot then
ctx.menu=not ctx.menu
return true
end
if ctx.app then
if x<=slot*2 then
if ctx.app.back then pcall(ctx.app.back,ctx) else closeApp(ctx) end
return true
end
if x<=slot*3 then ctx.menu=not ctx.menu; return true end
closeApp(ctx)
return true
end
end
if ctx.app and y==2 and x>=term.getSize()-3 then closeApp(ctx); return true end
if ctx.split and ctx.splitApp and y==math.floor((h-2)/2)+2 and x>=term.getSize()-3 then toggleSplit(ctx); return true end
if not ctx.app then
local home=require("apps.home")
home.touch(ctx,x,y,startApp)
return true
end
local app,localY=ctx.app,y
if ctx.split and ctx.splitApp and h>=18 then
local ph=math.floor((h-2)/2)
if y>=ph+2 then app,localY=ctx.splitApp,y-ph
elseif y<2 or y>ph+1 then return true end
end
if app.touch then
local ok,err
if app==ctx.splitApp and app.title=="Inicio" then
ok,err=pcall(app.touch,ctx,x,localY,startApp)
else
ok,err=pcall(app.touch,ctx,x,localY)
end
if not ok then ctx.notify("Error: "..tostring(err)) end
end
return true
end
function M.run()
local hasColor=type(term.isColor)=="function" and term.isColor()
ui.setBasicMode(not hasColor)
local settings=loadSettings()
sound.play("startup",settings.clickSounds)
local ctx
ctx={settings=settings,app=nil,appName=nil,menu=false,notifications={},jobs={},world=hasColor and sensors.world() or {},power=hasColor and sensors.power() or "--",
spawn=function(fn,onError)
local thread=coroutine.create(fn)
local job={thread=thread,onError=onError}
ctx.jobs[#ctx.jobs+1]=job
local ok,waitFor,target=coroutine.resume(thread)
if not ok then
table.remove(ctx.jobs)
if onError then pcall(onError,waitFor) end
ctx.notify("Tarea en segundo plano: "..tostring(waitFor))
elseif coroutine.status(thread)=="dead" then
table.remove(ctx.jobs)
else
job.waitFor,job.target=waitFor,target
end
end,
notify=function(msg)
msg=tostring(msg)
ctx.notifications[#ctx.notifications+1]=msg
while #ctx.notifications>8 do table.remove(ctx.notifications,1) end
if msg:lower():find("overstress",1,true) then
local sp=require("sys.mobile.peripherals").find("speaker")
if sp and sp.playNote then pcall(sp.playNote,"pling",1,12) end
end
end,
saveSettings=function()
local ok,err=saveSettings(settings)
if not ok then error("No se guardo la configuracion: "..tostring(err)) end
end,
playSound=function(kind)
return sound.play(kind,settings.clickSounds)
end,
}
local tick=os.startTimer(1)
local lastAlert=false
local monitor
if peripheral and peripheral.getNames and peripheral.wrap then
for _,name in ipairs(peripheral.getNames()) do
local tOk,tName=pcall(peripheral.getType,name)
if tOk and tName=="monitor" then
local ok,cand=pcall(peripheral.wrap,name)
if ok and cand then
local sOk,wd,ht=pcall(cand.getSize)
if sOk and wd<=ht then monitor=cand; break end
end
end
end
end
if monitor then
pcall(monitor.setTextScale,0.5)
term.redirect(monitor)
end
while true do
render(ctx)
local event={os.pullEvent()}
if event[1]=="monitor_touch" then event={"mouse_click",1,event[3],event[4]} end
if event[1]=="timer" and event[2]==tick then
if hasColor then
ctx.world=sensors.world()
ctx.power=sensors.power()
end
if ctx.appName=="radar" and ctx.app.refresh then pcall(ctx.app.refresh,ctx)
elseif ctx.appName=="create" and ctx.app.refresh then pcall(ctx.app.refresh,ctx) end
if ctx.app and ctx.app.tick then
local t,tE=pcall(ctx.app.tick,ctx)
if not t then ctx.notify("Error de app: "..tostring(tE)) end
end
if hasColor then
local tel=sensors.createTelemetry(settings)
if tel and tel.overstressed and not lastAlert then ctx.notify("Create Overstress: red detenida") end
lastAlert=tel and tel.overstressed or false
end
tick=os.startTimer(1)
elseif event[1]=="mouse_click" then
ctx.playSound("click")
isTouch(event[2],event[3],event[4],ctx)
elseif event[1]=="mouse_drag" and ctx.app and ctx.app.drag then
pcall(ctx.app.drag,ctx,event[2],event[3],event[4])
elseif event[1]=="chat" or event[1]=="chat_message" then
local user,message=event[2],event[3]
ctx.notify(tostring(user or "Servidor")..": "..tostring(message or ""))
if ctx.app and ctx.app.event then
local ok,err=pcall(ctx.app.event,ctx,event[1],user,message)
if not ok then ctx.notify("Error: "..tostring(err)) end
end
elseif ctx.app and ctx.app.event then
local ok,err=pcall(ctx.app.event,ctx,unpackValues(event))
if not ok then ctx.notify("Error: "..tostring(err)) end
end
resumeJobs(ctx,event)
end
end
return M
]],
['sys/mobile/ui.lua']=[[local M={}
local C=colors
local basicMode=false
M.colors={blue=C.lightBlue,title=C.gray,navy=C.black,light=C.white,panel=C.gray,text=C.white,green=C.lime,gray=C.gray,red=C.red}
M.theme={sky=C.gray,deepBlue=C.black,paleBlue=C.lightGray,grass=C.lime,leaf=C.green,panel=C.black,tile=C.gray,ink=C.white,muted=C.lightGray,highlight=C.white}
local function backgroundColor(color)
if color==C.white then return C.black end
if color==C.lightGray or color==C.lightBlue then return C.gray end
if color==C.cyan then return C.blue end
if color==C.green then return C.lime end
return color
end
local function basicColor(color)
if color==C.white or color==C.lightGray or color==C.lightBlue or color==C.cyan or color==C.lime or color==C.yellow or color==C.orange or color==C.pink then
return C.white
end
return C.black
end
function M.setBasicMode(enabled) basicMode=enabled==true end
function M.isBasicMode() return basicMode end
function M.size() return term.getSize() end
function M.fill(x,y,wd,ht,color,char)
local w,h=term.getSize()
local line=string.rep(char or " ",math.max(0,math.min(wd,w)))
term.setBackgroundColor(basicMode and basicColor(color or C.black) or backgroundColor(color or C.black))
for row=math.max(1,y),math.min(h,y+ht-1) do
term.setCursorPos(math.max(1,x),row)
term.write(line:sub(1,math.max(0,w-x+1)))
end
end
function M.text(x,y,value,fg,bg,maxW)
local w,h=term.getSize()
if y<1 or y>h or x>w then return end
value=tostring(value or "")
if maxW then value=value:sub(1,maxW) end
value=value:sub(1,math.max(0,w-x+1))
term.setCursorPos(math.max(1,x),y)
if fg then
local surface=bg and (basicMode and basicColor(bg) or backgroundColor(bg))
if basicMode then
if bg then fg=surface==C.white and C.black or C.white
else fg=basicColor(fg) end
elseif not bg then
if fg==C.black or fg==C.blue then fg=C.white
elseif fg==C.gray then fg=C.lightGray end
elseif surface==C.black or surface==C.gray then
if fg==C.black or fg==C.blue then fg=C.white
elseif fg==C.gray then fg=C.lightGray end
elseif surface==C.blue and (fg==C.black or fg==C.blue) then
fg=C.white
elseif fg==C.white and (surface==C.lime or surface==C.yellow or surface==C.orange) then
fg=C.black
end
term.setTextColor(fg)
end
if bg then
term.setBackgroundColor(basicMode and basicColor(bg) or backgroundColor(bg))
end
term.write(value)
end
function M.center(y,value,fg,bg)
local w=term.getSize()
value=tostring(value or "")
M.text(math.max(1,math.floor((w-#value)/2)+1),y,value,fg,bg)
end
function M.button(x,y,wd,label,bg,fg)
local w=term.getSize()
wd=math.max(0,math.min(wd,w-x+1))
if wd==0 then return {x=x,y=y,width=0,height=1} end
label=tostring(label)
bg=bg or C.gray
M.fill(x,y,wd,1,bg)
local caption=label:sub(1,wd)
local left=x+math.max(0,math.floor((wd-#caption)/2))
M.text(left,y,caption,fg or C.white,bg,wd)
return {x=x,y=y,width=wd,height=1}
end
function M.hit(rect,x,y)
return rect and x>=rect.x and x<rect.x+rect.width and y>=rect.y and y<rect.y+rect.height
end
function M.wrap(value,wd)
local lines={}
wd=math.max(1,wd)
for para in (tostring(value or "").."\n"):gmatch("(.-)\n") do
para=para:gsub("%s+"," ")
if para=="" then lines[#lines+1]=""
else
while #para>wd do
local cut=para:sub(1,wd):match("^.*()%s")
if not cut or cut<2 then cut=wd end
lines[#lines+1]=para:sub(1,cut):gsub("%s+$","")
para=para:sub(cut+1):gsub("^%s+","")
end
lines[#lines+1]=para
end
end
return lines
end
function M.status(ctx)
local w=term.getSize()
M.fill(1,1,w,1,M.theme.deepBlue)
if basicMode then
local notice=#ctx.notifications>0 and "!" or ""
M.text(1,1," BASIC",C.white,C.black,math.min(7,w))
local ind=notice.." "..os.date("%H:%M")
M.text(math.max(1,w-#ind+1),1,ind,C.white,C.black,#ind)
return
end
local signal=http and http.get and "W" or "X"
local power=ctx.power or "--"
local time=os.date("%H:%M")
local notice=#ctx.notifications>0 and "!" or " "
M.text(1,1," A",C.lime,M.theme.deepBlue,math.min(3,w))
local ind=signal.." "..power.." "..notice.." "..time
M.text(math.max(1,w-#ind+1),1,ind,C.white,M.theme.deepBlue,#ind)
end
function M.title(ctx,app,row)
local w=term.getSize()
row=row or 2
M.fill(1,row,w,1,M.theme.sky)
M.text(2,row,app.title or app.name or "Aplicacion",C.white,M.theme.sky,math.max(1,w-6))
M.fill(math.max(1,w-2),row,math.min(3,w),1,C.red)
M.text(w-1,row,"X",C.white,C.red,1)
end
function M.dock(ctx)
local w,h=term.getSize()
local slot=math.max(1,math.floor(w/4))
M.fill(1,h,w,1,M.theme.deepBlue)
if not ctx.app then
if basicMode then
M.button(1,h,slot,w<20 and "File" or "Files",C.gray,C.white)
M.button(slot+1,h,slot,"Apps",C.lightGray,C.black)
M.button(slot*2+1,h,slot,w<20 and "Note" or "Notes",C.gray,C.white)
M.button(slot*3+1,h,w-slot*3,w<20 and "Time" or "Clock",C.gray,C.white)
else
M.button(1,h,slot,"GPS",C.gray,C.white)
M.button(slot+1,h,slot,"Apps",C.lightGray,C.black)
M.button(slot*2+1,h,slot,"Chat",C.gray,C.white)
M.button(slot*3+1,h,w-slot*3,"Web",C.gray,C.white)
end
else
M.button(1,h,slot,"Menu",C.gray,C.white)
local backLabel=w<32 and "<" or "Atras"
M.button(slot+1,h,slot,backLabel,M.theme.sky,C.white)
M.button(slot*2+1,h,slot,"Menu",M.theme.sky,C.white)
M.button(slot*3+1,h,w-slot*3,w<32 and "X" or "Cerrar",M.theme.sky,C.white)
end
end
return M
]],
['sys/mobile/lib.lua']=[[local ui=require("sys.mobile.ui")
local M={ui=ui}
function M.label(ctx,x,y,text,wd) ui.text(x,y,text,colors.black,colors.white,wd) end
function M.heading(ctx,y,title)
local w=term.getSize()
ui.fill(1,y,w,1,colors.lightBlue)
ui.text(2,y,title,colors.white,colors.lightBlue,w-2)
end
function M.notification(ctx,msg) ctx.notify(msg) end
function M.prompt(ctx,caption,initial)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
local _,height=term.getSize()
term.setCursorPos(1,math.max(1,height-1))
term.clearLine()
write(caption.." ")
return read(nil,nil,nil,initial or "")
end
function M.readFile(path,limit)
if not fs.exists(path) or fs.isDir(path) then return nil,"No se puede leer el archivo" end
local handle,err=fs.open(path,"r")
if not handle then return nil,err end
local data=handle.read(limit or 32768)
handle.close()
return data or ""
end
function M.writeFile(path,data)
local parent=fs.getDir(path)
if parent~="" and not fs.exists(parent) then fs.makeDir(parent) end
local handle,err=fs.open(path,"w")
if not handle then return nil,err end
handle.write(data)
handle.close()
return true
end
return M
]],
['sys/mobile/peripherals.lua']=[[local M={}
local function invoke(device,method,...)
if not device or type(device[method])~="function" then return nil end
local ok,value=pcall(device[method],...)
if ok then return value end
return nil
end
function M.find(typeName)
if not peripheral or not peripheral.find then return nil end
local ok,device=pcall(peripheral.find,typeName)
if ok then return device end
return nil
end
function M.method(device,names,...)
for _,name in ipairs(names) do
local value=invoke(device,name,...)
if value~=nil then return value,name end
end
return nil
end
function M.describe(device)
local result={}
if not device then return result end
local ok,methods=pcall(peripheral.getMethods,peripheral.getName(device))
if ok and type(methods)=="table" then
for _,name in ipairs(methods) do result[name]=true end
end
return result
end
function M.names()
if not peripheral or not peripheral.getNames then return {} end
local ok,names=pcall(peripheral.getNames)
if ok and type(names)=="table" then return names end
return {}
end
return M
]],
['sys/mobile/sensors.lua']=[[local devices=require("sys.mobile.peripherals")
local M={}
local function text(value)
if value==nil then return nil end
if type(value)=="table" then return text(value.name or value.biome or value.weather or value.value) end
return tostring(value)
end
function M.world()
local environment=devices.find("environmentDetector")
local weather=devices.find("weatherDetector")
local info={
biome=devices.method(environment,{"getBiome"}),
dimension=devices.method(environment,{"getDimension"}),
moon=devices.method(environment,{"getMoonId","getMoonPhase"}),
worldTime=devices.method(environment,{"getTime","getWorldTime","getDay"}),
weather=devices.method(weather,{"getWeather"}),
}
for k,v in pairs(info) do info[k]=text(v) or "--" end
return info
end
function M.players(range)
local detector=devices.find("playerDetector")
if not detector then return nil,"Player Detector no conectado" end
local names=devices.method(detector,{"getPlayersInRange","getPlayers"},range or 32)
if type(names)~="table" then return nil,"El detector no devolvió jugadores" end
local result={}
for _,entry in ipairs(names) do
local name=type(entry)=="table" and (entry.name or entry.username) or entry
if type(name)=="string" then
local position=devices.method(detector,{"getPlayerPos","getPlayerPosition"},name)
if type(position)~="table" and type(entry)=="table" then position=entry end
if type(position)~="table" then position={} end
result[#result+1]={name=name,x=position.x or "?",y=position.y or "?",z=position.z or "?",distance=position.distance or "?"}
end
end
return result
end
function M.createTelemetry(config)
local configured=config.createPeripheral
local device
if configured and configured~="" and peripheral then
local ok,value=pcall(peripheral.wrap,configured)
if ok then device=value end
end
if not device then
for _,name in ipairs(devices.names()) do
local ok,cand=pcall(peripheral.wrap,name)
if ok and cand then
local methods=devices.describe(cand)
if methods.getSpeed or methods.getStress or methods.getStressCapacity then device=cand; break end
end
end
end
if not device then return nil,"No se detectó un puente/periférico de Create" end
local rpm=devices.method(device,{"getSpeed","getRPM","getRotationSpeed"})
local stress=devices.method(device,{"getStress","getStressImpact"})
local capacity=devices.method(device,{"getStressCapacity","getCapacity"})
local stalled=devices.method(device,{"isStalled","getStalled"})
local overstressed=devices.method(device,{"isOverstressed","getOverstressed"})
return {rpm=rpm or 0,stress=stress or 0,capacity=capacity,stalled=stalled==true,overstressed=overstressed==true}
end
function M.power()
local storage=devices.find("energyStorage")
if storage then
local energy=devices.method(storage,{"getEnergy","getEnergyStored"})
local capacity=devices.method(storage,{"getEnergyCapacity","getMaxEnergy"})
if type(energy)=="number" and type(capacity)=="number" and capacity>0 then
return math.floor(energy*100/capacity).."%"
end
end
if redstone and redstone.getInput then
for _,side in ipairs({"left","right","top","bottom","front","back"}) do
if redstone.getInput(side) then return "R+" end
end
return "R-"
end
return "--"
end
return M
]],
['sys/mobile/sound.lua']=[[local M={}
local speakers
local function getSpeakers()
if speakers then return speakers end
speakers={}
if not peripheral or type(peripheral.find)~="function" then return speakers end
local ok,found=pcall(peripheral.find,"speaker")
if ok and type(found)=="table" then
for _,sp in ipairs(found) do
if type(sp.playNote)=="function" then speakers[#speakers+1]=sp end
end
end
return speakers
end
function M.play(kind,enabled)
if enabled==false then return false end
local devs=getSpeakers()
if #devs==0 then return false end
local notes
if kind=="action" then
notes={{"chime",0.65,17},{"pling",0.45,21}}
elseif kind=="startup" then
notes={{"chime",0.65,12},{"bell",0.65,16},{"pling",0.6,19},{"chime",0.55,21},{"pling",0.45,24}}
elseif kind=="shutdown" then
notes={{"pling",0.55,22},{"bell",0.6,19},{"chime",0.55,16},{"bell",0.45,12},{"chime",0.35,9}}
else
notes={{"hat",0.35,18}}
end
local played=false
for _,dev in ipairs(devs) do
for _,note in ipairs(notes) do
local ok=pcall(dev.playNote,note[1],note[2],note[3])
played=played or ok
end
end
return played
end
return M
]],
['drivers/create.lua']=[[local peripherals=require("sys.mobile.peripherals")
local M={}
local KEYS={"clutch","gearbox","sequencer"}
function M.readOutputs(settings)
local result={}
local integrator
if settings.createOutputMode=="integrator" then
integrator=peripherals.find("redstoneIntegrator")
end
for _,key in ipairs(KEYS) do
local side=settings.createOutputs and settings.createOutputs[key]
local value
if side and integrator and type(integrator.getOutput)=="function" then
local ok,output=pcall(integrator.getOutput,side)
if ok then value=output end
elseif side and redstone and redstone.getOutput then
local ok,output=pcall(redstone.getOutput,side)
if ok then value=output end
end
result[key]=value==true
end
return result
end
function M.setOutput(settings,key,value)
local side=settings.createOutputs and settings.createOutputs[key]
if not side or side=="" then error("Configura una salida para "..key) end
if settings.createOutputMode=="integrator" then
local device=peripherals.find("redstoneIntegrator")
if not device or type(device.setOutput)~="function" then error("Redstone Integrator no conectado") end
device.setOutput(side,value)
else
if not redstone or not redstone.setOutput then error("API de redstone no disponible") end
redstone.setOutput(side,value)
end
end
return M
]],
['apps/home.lua']=[[local ui=require("sys.mobile.ui")
local M={title="Inicio"}
local apps={{"Mi PC","explorer","PC"},{"Internet","ie","IE"},{"Create","create","CR"},{"Sensores","radar","AP"},{"Media","media","WMP"},{"Ajustes","settings","SYS"},{"Messenger","messenger","MSN"},{"Pocket CMD","cmd",">"},{"GPS","gps","GPS"},{"Ores","ores","ORE"},{"Calculadora","calculator","CALC"},{"Notas","notes","TXT"},{"Reloj","clock","TIME"},{"Redstone","redstone","RS"},{"Inventario","inventory","INV"},{"YouTube","youtube","YT"},{"Música","music","MUS"},{"Mapa","map","MAP"}}
local iconColors={colors.cyan,colors.blue,colors.orange,colors.cyan,colors.purple,colors.green,colors.red,colors.gray,colors.cyan,colors.orange,colors.purple,colors.gray,colors.blue,colors.red,colors.orange,colors.red,colors.green}
local page=1
local basicApps={{"Files","explorer","FILE"},{"Calc","calculator","123"},{"Notes","notes","TXT"},{"Clock","clock","TIME"},{"Map","map","MAP"}}
local function visibleApps() return ui.isBasicMode() and basicApps or apps end
local function compact(text,wd)
text=tostring(text or "")
if #text>wd then return text:sub(1,math.max(1,wd-1)).."~" end
return text
end
local function centered(x,y,wd,value,fg,bg)
value=compact(value,wd)
local left=x+math.max(0,math.floor((wd-#value)/2))
ui.text(left,y,value,fg,bg,wd)
end
local function dimensionName(world)
local dim=tostring(world.dimension or "--")
local names={["minecraft:overworld"]="Overworld",["minecraft:the_nether"]="Nether",["minecraft:the_end"]="The End"}
return names[dim] or dim
end
local function weatherLine(world,wd)
local place=tostring(world.biome or "--")
local weather=tostring(world.weather or "--")
return compact(place.." / "..weather.." / "..dimensionName(world),wd)
end
local digitGlyphs={["0"]={" _ ","| |","|_|"},["1"]={" "," |"," |"},["2"]={" _ "," _|","|_ "},["3"]={" _ "," _|"," _|"},["4"]={" ","|_|"," |"},["5"]={" _ ","|_ "," _|"},["6"]={" _ ","|_ ","|_|"},["7"]={" _ "," |"," |"},["8"]={" _ ","|_|","|_|"},["9"]={" _ ","|_|"," _|"},[":"]={" ",".","."}}
local function drawClock(w)
local clock=os.date("%H:%M")
local width=#clock*4-1
if w<width+2 then
centered(2,3,w-2,clock,colors.white,colors.gray)
return
end
local x=math.floor((w-width)/2)+1
for i=1,#clock do
local glyph=digitGlyphs[clock:sub(i,i)]
local offset=x+(i-1)*4
for r=1,3 do
ui.text(offset,r+1,glyph[r],colors.white,colors.gray,3)
end
end
end
function M.draw(ctx)
local w,h=term.getSize()
local world=ctx.world or {}
local visible=visibleApps()
ui.fill(1,2,w,math.max(1,h-2),colors.black)
for y=2,h-2 do
for x=1,w do
if (x*7+y*11)%29==0 then
ui.text(x,y,".",colors.gray,colors.black,1)
end
end
end
ui.fill(2,2,math.max(1,w-2),3,colors.gray)
drawClock(w)
local subtitle=ui.isBasicMode() and "Basic mode / offline" or
os.date("%a, %d %b").." "..weatherLine(world,w-2)
ui.text(2,5,compact(subtitle,w-2),colors.white,colors.black,w-2)
local cols
if ui.isBasicMode() then cols=w<22 and 2 or 3
else cols=w>=34 and 4 or (w<22 and 2 or 3) end
local rows=math.max(1,math.min(4,math.floor((h-7)/3)))
local cell=math.max(1,math.floor((w-2)/cols))
local perPage=cols*rows
local pages=math.max(1,math.ceil(#visible/perPage))
page=math.min(page,pages)
local first=(page-1)*perPage+1
local last=math.min(#visible,first+perPage-1)
for i=first,last do
local entry=visible[i]
local li=i-first
local col=li%cols
local row=math.floor(li/cols)
local x=2+col*cell
local y=6+row*3
if y<h-2 then
local tw=math.max(1,math.min(cell-1,w-x+1))
ui.fill(x,y,tw,2,colors.black)
local ic=ui.isBasicMode() and (i%2==0 and colors.white or colors.black) or iconColors[i]
ui.fill(x,y,tw,1,ic)
centered(x,y,tw,"["..entry[3].."]",ic==colors.white and colors.black or colors.white,ic)
centered(x,y+1,tw,entry[1],colors.white,colors.black)
end
end
if pages>1 and h>=12 then
ui.fill(1,h-2,w,1,colors.black)
ui.text(2,h-2,"<",colors.white,colors.gray,1)
ui.text(math.max(1,math.floor((w-5)/2)),h-2,"o "..page.."/"..pages.." o",colors.white,colors.black,12)
ui.text(w,h-2,">",colors.white,colors.gray,1)
elseif #ctx.notifications>0 and h>=12 then
ui.fill(2,h-2,math.max(1,w-2),1,colors.gray)
ui.text(3,h-2,"!"..compact(ctx.notifications[#ctx.notifications],w-4),colors.white,colors.gray,w-4)
end
end
function M.touch(ctx,x,y,startApp)
local w=term.getSize()
local _,h=term.getSize()
local visible=visibleApps()
local cols
if ui.isBasicMode() then cols=w<22 and 2 or 3
else cols=w>=34 and 4 or (w<22 and 2 or 3) end
local rows=math.max(1,math.min(4,math.floor((h-7)/3)))
local perPage=cols*rows
local pages=math.max(1,math.ceil(#visible/perPage))
if pages>1 and y==h-2 then
if x<=3 then page=page>1 and page-1 or pages
elseif x>=w-2 then page=page<pages and page+1 or 1 end
return
end
if y<6 then return end
local cell=math.max(1,math.floor((w-2)/cols))
local col=math.floor((x-2)/cell)
local row=math.floor((y-6)/3)
if col<0 or col>=cols or row<0 or x>w-1 then return end
local index=(page-1)*perPage+row*cols+col+1
if visible[index] and y<=h-3 then
startApp(visible[index][2],ctx)
end
end
return M
]],
['apps/music.lua']=[[local ui=require("sys.mobile.ui")
local lib=require("sys.mobile.lib")
local M={title="Streaming Music"}
local API="https://ipod-2to6magyna-uc.a.run.app/"
local VERSION="2.1"
local state={query="",results={},selected=1,page=1,message="Busca una cancion o pega un enlace de YouTube.",searching=false,playing=false,stop=false,speakers={},speakerNames={},now=nil,searchUrl=nil,downloadUrl=nil,decoders={}}
local function compact(value,wd)
value=tostring(value or ""):gsub("[%c]"," ")
if #value>wd then return value:sub(1,math.max(1,wd-1)).."~" end
return value
end
local function stopPlayback()
state.stop=true
for _,sp in ipairs(state.speakers) do
if sp.stop then pcall(sp.stop) end
end
for _,name in ipairs(state.speakerNames) do
os.queueEvent("speaker_audio_empty",name)
end
state.playing=false
state.speakers,state.speakerNames,state.decoders={},{},{}
end
local function search(ctx)
local query=lib.prompt(ctx,"Buscar musica:",state.query)
if not query or not query:match("%S") then return end
state.query,state.results,state.page=query,{},1
state.searching,state.message=true,"Buscando..."
local url=API.."?v="..VERSION.."&search="..textutils.urlEncode(query)
state.searchUrl=url
local ok,reason=pcall(http.request,url)
if not ok then state.searching=false; state.message="HTTP no disponible: "..tostring(reason) end
end
local function playItem(ctx,item)
local allSpeakers={peripheral.find("speaker")}
local valid={}
for _,sp in ipairs(allSpeakers) do
if type(sp.playAudio)=="function" then valid[#valid+1]=sp end
end
if #valid==0 then state.message="Conecta un speaker para reproducir."; return end
local ok,decoderModule=pcall(require,"cc.audio.dfpwm")
if not ok then state.message="Requiere CC:Tweaked 1.100+ (cc.audio.dfpwm)."; return end
stopPlayback()
state.stop,state.playing,state.speakers,state.now=false,true,valid,item
state.speakerNames,state.decoders={},{}
for i,sp in ipairs(valid) do
local nOk,name=pcall(peripheral.getName,sp)
state.speakerNames[i]=nOk and name or nil
state.decoders[i]=decoderModule.make_decoder()
end
state.message="Cargando ("..#valid.." spk): "..compact(item.name,20)
state.downloadUrl=API.."?v="..VERSION.."&id="..textutils.urlEncode(item.id)
local ok,reason=pcall(http.request,{url=state.downloadUrl,binary=true})
if not ok then state.playing=false; state.message="HTTP no disponible: "..tostring(reason) end
end
function M.event(ctx,event,url,handle)
if event=="http_success" then
if url==state.searchUrl then
local raw=handle.readAll(); handle.close()
local ok,data=pcall(textutils.unserialiseJSON,raw or "[]")
if not ok or type(data)~="table" then
state.searching,state.message=false,"Respuesta invalida"; return
end
state.results={}
for _,item in ipairs(data) do
if type(item)=="table" and item.id then
state.results[#state.results+1]={id=tostring(item.id),name=tostring(item.name or "Sin titulo"),artist=tostring(item.artist or "YouTube")}
end
end
state.searching=false
state.message=#state.results>0 and ("Resultados: "..#state.results) or "No se encontraron resultados."
elseif url==state.downloadUrl then
local input=handle
ctx.spawn(function()
local first=input.read(4)
if not first then input.close(); error("Audio vacio") end
local firstChunk=true
while not state.stop do
local chunk=input.read(16380)
if not chunk then break end
if firstChunk then chunk,firstChunk=first..chunk,false end
for i,sp in ipairs(state.speakers) do
local audio=state.decoders[i](chunk)
while not state.stop and not sp.playAudio(audio) do
coroutine.yield("speaker_audio_empty",state.speakerNames[i])
end
end
end
input.close()
if not state.stop then state.message="Reproduccion terminada" end
state.playing=false
end,function(err)
state.playing=false; state.message="Error de audio: "..tostring(err)
end)
end
elseif event=="http_failure" then
if url==state.searchUrl then
state.searching,state.message=false,"No se pudo conectar al servicio."
elseif url==state.downloadUrl then
state.playing,state.message=false,"No se pudo descargar el audio."
end
end
end
function M.open()
state.results,state.selected,state.page={},1,1
state.message="Busca una cancion o pega un enlace de YouTube."
end
function M.close() stopPlayback() end
function M.draw()
local w,h=term.getSize()
ui.fill(2,3,math.max(1,w-3),1,colors.blue)
local spCount=#state.speakers>0 and (" ["..#state.speakers.." spk]") or ""
ui.text(3,3,compact((state.now and ("~ "..state.now.name) or "Streaming Music")..spCount,w-4),colors.white,colors.blue,w-4)
ui.button(2,5,8,"Buscar",colors.green,colors.black)
ui.button(12,5,7,"Parar",colors.red)
ui.text(2,7,compact(state.message,w-2),state.searching and colors.gray or colors.blue,colors.white,w-2)
local first=(state.page-1)*math.max(1,h-10)+1
for index=first,math.min(#state.results,first+h-11) do
local y,item=9+index-first,state.results[index]
ui.text(2,y,(index==state.selected and "> " or " ")..compact(item.name,w-4),index==state.selected and colors.blue or colors.black,colors.white,w-2)
if y+1<h-1 then ui.text(4,y+1,compact(item.artist,w-6),colors.gray,colors.white,w-4) end
end
end
function M.touch(ctx,x,y)
local _,h=term.getSize()
if y==5 and x<11 then search(ctx); return end
if y==5 and x>=11 and x<20 then stopPlayback(); state.message="Reproduccion detenida"; return end
if y>=9 and y<h-1 then
local index=(state.page-1)*math.max(1,h-10)+math.floor((y-9)/2)+1
if state.results[index] then state.selected=index; playItem(ctx,state.results[index]) end
end
end
return M
]],
['apps/ie.lua']=[[local ui=require("sys.mobile.ui")
local lib=require("sys.mobile.lib")
local M={title="Internet Explorer Mobile"}
local MAX_BYTES=24000
local state={url="",lines={},scroll=1,message="Elige un marcador o escribe una direccion."}
local function cleanHtml(html)
html=html:gsub("<[Ss][Cc][Rr][Ii][Pp][Tt][^>]*>.-</[Ss][Cc][Rr][Ii][Pp][Tt]%s*>"," ")
html=html:gsub("<[Ss][Tt][Yy][Ll][Ee][^>]*>.-</[Ss][Tt][Yy][Ll][Ee]%s*>"," ")
html=html:gsub("<[Hh][Rr][^>]*>","\n----------------\n")
html=html:gsub("<[Bb][Rr][^>]*>","\n")
html=html:gsub("</[Pp]%s*>","\n\n")
html=html:gsub("</[Dd][Ii][Vv]%s*>","\n")
html=html:gsub("<[Ll][Ii][^>]*>","\n * ")
html=html:gsub("<[^>]->"," ")
html=html:gsub("&nbsp;"," "):gsub("&amp;","&"):gsub("&lt;","<")
html=html:gsub("&gt;",">"):gsub("&quot;",'"'):gsub("&#39;","'")
html=html:gsub("&#(%d+);",function(n) return string.char(tonumber(n)%128) end)
html=html:gsub("[%z\1-\8\11\12\14-\31\127]"," ")
html=html:gsub("[ \t\r]+"," ")
html=html:gsub(" *\n *","\n")
html=html:gsub("\n\n\n+","\n\n")
return html
end
local function showText(text,wd)
local result={}
for para in (text.."\n"):gmatch("(.-)\n") do
local wrapped=ui.wrap(para,wd)
for _,line in ipairs(wrapped) do
if line~="" or #result==0 or result[#result]~="" then
result[#result+1]=line
end
end
end
return result
end
local function browse(url)
if not http or not http.get then
state.message="HTTP API desactivada en la configuracion de CraftOS."
state.lines={state.message}
return
end
if type(url)~="string" or not url:match("^https?://[%w%.%-]+") or url:find("%s") then
state.message="Direccion no valida. Usa http:// o https://"
state.lines={state.message}
return
end
state.url,state.scroll=url,1
local ok,response,reason=pcall(http.get,url,{["User-Agent"]="Android-Mobile/1.0"})
if not ok or not response then
state.message="No se pudo abrir la pagina: "..tostring(ok and reason or response)
state.lines={state.message}
return
end
local chunks,size={},0
local readOk,readError=pcall(function()
while size<MAX_BYTES do
local piece=response.read(math.min(2048,MAX_BYTES-size))
if not piece or piece=="" then break end
chunks[#chunks+1]=piece
size=size+#piece
end
end)
pcall(response.close)
if not readOk then
state.message="Error leyendo la pagina: "..tostring(readError)
state.lines={state.message}
return
end
local body=cleanHtml(table.concat(chunks))
if body=="" then body="(La pagina no contiene texto legible.)" end
state.lines=showText(body,math.max(12,term.getSize()-4))
state.message="Descargado ("..size.." bytes; vista de texto)"
end
local function openAddress(ctx)
local url=lib.prompt(ctx,"URL:",state.url)
if url and url~="" then browse(url) end
end
function M.open()
state.url,state.scroll="",1
state.lines,state.message={},{}
state.message="Elige un marcador o escribe una direccion."
end
function M.draw(ctx)
local w,h=term.getSize()
ui.button(2,3,math.min(w-2,14),"Direccion",colors.blue)
ui.text(2,4,state.url~="" and state.url or "Toca [Direccion]",colors.black,colors.white,w-2)
local bookmarks=ctx.settings.bookmarks or {}
ui.text(2,5,"Favoritos:",colors.blue,colors.white)
for i=1,math.min(3,#bookmarks) do
ui.button(2+(i-1)*math.floor(math.max(1,w-2)/3),6,math.floor(math.max(1,w-2)/3),bookmarks[i][1],colors.lightBlue)
end
ui.fill(1,7,w,1,colors.gray)
ui.text(2,7,state.message,colors.white,colors.gray,w-2)
for row=9,h-2 do
local line=state.lines[state.scroll+row-9]
if line then ui.text(2,row,line,colors.black,colors.white,w-2) end
end
ui.button(2,h-1,8,"Arriba",colors.blue)
ui.button(11,h-1,8,"Abajo",colors.blue)
end
function M.touch(ctx,x,y)
local w,h=term.getSize()
if y==3 or (y==4 and x<=w) then
openAddress(ctx)
elseif y==6 then
local bookmarks=ctx.settings.bookmarks or {}
local slot=math.floor((x-2)/math.max(1,math.floor((w-2)/3)))+1
if bookmarks[slot] then browse(bookmarks[slot][2]) end
elseif y==h-1 then
if x<11 then state.scroll=math.max(1,state.scroll-5)
else state.scroll=math.min(math.max(1,#state.lines-(h-10)),state.scroll+5) end
else
state.scroll=math.max(1,math.min(#state.lines,state.scroll+(y>h/2 and 2 or -2)))
end
end
function M.drag(ctx,_,_,y)
local _,h=term.getSize()
state.scroll=math.max(1,math.min(#state.lines,state.scroll+(y>h/2 and 2 or -2)))
end
return M
]],
['apps/radar.lua']=[[local ui=require("sys.mobile.ui")
local sensors=require("sys.mobile.sensors")
local M={title="Sensor Hub / Radar"}
local state={players={},error=nil,page="players"}
local function refresh(ctx)
local players,err=sensors.players(ctx.settings.playerRange)
state.players,state.error=players or {},err
end
function M.open(ctx) refresh(ctx) end
function M.refresh(ctx) refresh(ctx) end
function M.draw(ctx)
local w,h=term.getSize()
ui.button(2,3,12,"Actualizar",colors.blue)
ui.button(16,3,10,"Ambiente",colors.lightBlue)
if state.page=="world" then
local world=ctx.world or {}
ui.text(2,5,"Bioma: "..tostring(world.biome or "--"),colors.black,colors.white,w-2)
ui.text(2,6,"Dimension: "..tostring(world.dimension or "--"),colors.black,colors.white,w-2)
ui.text(2,7,"Luna: "..tostring(world.moon or "--").." Hora: "..tostring(world.worldTime or "--"),colors.black,colors.white,w-2)
ui.text(2,8,"Clima: "..tostring(world.weather   
