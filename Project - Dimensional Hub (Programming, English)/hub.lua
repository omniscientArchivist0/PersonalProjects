-----------------------------------------------

 -- GLOBAL --

-----------------------------------------------

-- Defined Tables --

def = {
  ERROR_NO_FILENAME = "[ERROR] You must give some filename to show. Like: show myfile.3dx",
  ERROR_WRONG_FILE_FORMAT = "[ERROR] Wrong file format. Viewer can show *.3dx or *.3d files only.",
  ERROR_INVALID_FORMAT_STRUCTURE = "[ERROR] Invalid file structure.",
  ERROR_UNABLE_TO_OPEN = "[ERROR] Cannot open: ",
  ERROR_FILE_NOT_FOUND = "[ERROR] File not found: ",
  ERROR_WRONG_SCALE = "[ERROR] Scale parameter must be a number between 0.33 and 4.00",
  ERROR_NO_PROJECTOR = "[ERROR] Projector is not found.",
  ERROR_NO_TELEPORT = "[ERROR] Teleport failed.",
  ERROR_INVALID_SELECTION = "[ERROR] This is not a valid option. Please, try again.",
  ERROR_UNREADABLE_SELECTION = "[ERROR] The selection wasn't able to be read. Something went REALLY wrong.",
  HOLOGRAM_DONE = "The hologram was successfully rendered.",
  TELEPORT_DONE = "The teleporter was successfully activated.",
  DASHES = string.rep('-', 80),
  DOUBLES = string.rep('=', 80)
}

dimensionalTable = {
    terra = 1,
    nether = 2,
    theend = 3,
    telos = 4,
    aether = 5,
    erebus = 6,
    deep_dark = 7,
    emptiness = 8,
    twilight_forest = 9,
    iceika = 10,
    arcana = 11,
    betweenlands = 12,
    abyssal_wasteland = 13
}

dimensionalTree = {
  Magical = {
    Aer = {
      AETHER = "aether"
    },
    Aqua = {
      ICEIKA = "iceika"
    },
    Ignis = {
      
    },
    Lux = {
      ARCANA = "arcana"
    },
    Terra = {
      BETWEENLANDS = "betweenlands",
      EREBUS = "erebus",
      TWILIGHT = "twilight_forest"
    },
    Umbra = {
      ABYSSAL = "abyssal_wasteland",
      DEEP_DARK = "deep_dark",
      EMPTINESS = "emptiness"
    },
    Vanilla = {
      END = "theend",
      NETHER = "nether",
      TERRA = "terra"
    }
  },
  Spatial = {
    Anomalous = {
      TELOS = "telos"
    }
  }
}

-- Imports --

fs = require('filesystem')
os = require('os')
shell = require('shell')
com = require('component')
bit32 = require('bit32')
sides = require("sides")
args = { ... }
trans = com.proxy(com.get("e9af2"))
term = require('term')


-- General Functions --

function trytofind(name)
  if com.isAvailable(name) then
    return com.getPrimary(name)
  else
    return nil
  end
end


-- Configuration Variables --

HOLOH = 32
HOLOW = 48
proj_scale = 1.0


-------------------------------------------------

 -- ASCII Menu by RiciLake                    --
 -- Link: http://lua-users.org/wiki/AsciiMenu --

-------------------------------------------------

do
local curriedMethod, method, meta = {}, {}, {}

  -- __index either executes a method from method or curries a method from
  -- curriedMethod with its self argument. This allows all calls to be with
  -- "." rather than ":" and also allows you to write obj.foo instead of
  -- obj.foo() for methods which don't require arguments. It might
  -- not be great design, but it is interesting. :)
  
  function meta:__index(key)
    local func = method[key]
    if func then
      return func(self)
     else
      func = curriedMethod[key]
      if func then
        local rv = function(a, b) return func(self, a, b) end
        self[key] = rv
        return rv
      end
    end
  end

  local function drawmenu(self)
    term.clear()
    local maxsize = string.len(self.name) + 2
    local item = 0
    for i = 1, self.n do
      local sz = 6 + string.len(self[1][i])
      if maxsize < sz then maxsize = sz end
    end
    if maxsize > 75 then maxsize = 75 end
    local sepformat = "  +%-"..maxsize.."."..maxsize.."s+\n"
    local nameformat = "  | %-"..(maxsize - 2).."."..(maxsize-2).."s |\n"
    local itemformat = "  | %2i. %-"..(maxsize - 6).."."..(maxsize-6).."s |\n"
    local sepline = string.format(sepformat, def.DASHES)
    io.write("\n", string.format(sepformat, def.DOUBLES))
    io.write(string.format(nameformat, self.name))
    io.write(string.format(sepformat, def.DOUBLES))
    for i = 1, self.n do
      if self[2][i] then
        item = item + 1
        io.write(string.format(itemformat, item, self[1][i]))
      else
        io.write(sepline)
      end
    end
    io.write(sepline)
  end

  -- Equally quick and dirty menu execution. Tail calls the function
  -- associated with the selected menu item.
  local function domenu(self)
    drawmenu(self)
    io.write("\n\nSelect a menu item: ")
    while true do
      local choice = io.read("*l")
      if choice == nil then return false end
      local _, _, item = string.find(choice, "^%s*(%d+)%s*$")
      if item then

        item = item + 0 -- force numeric conversion
        for i = 1, self.n do
          if self[2][i] then
            if item == 1 then return self[2][i]() end
            item = item - 1
          end
        end
      end
      io.write(def.ERROR_INVALID_SELECTION)
    end
  end

  -- Create a new menu with given name and back reference.
  local function newmenu(name, back)
    return setmetatable({
      {}, {},  -- [1] is the menu label, [2] is the associated function
      name = name,
      back = back,
      n = 0
    },
    meta)
  end

  -- insert a label and a function at the end of a menu
  local function put(self, name, action)
    local n = self.n + 1
    self.n = n
    self[1][n] = name
    self[2][n] = action
    return self
  end

  -- Now the actual menu methods.
  -- add(label, id)
  function curriedMethod:add(name, id)
    return put(self, name, function() return id end)
  end
  
  -- I personally would use functions instead of ids
  curriedMethod.addf = put

  -- create and open a submenu with the given name
  function curriedMethod:sub(name)
    local submenu = newmenu(self.name .. " / " .. name, self)
    put(self, name.." -->", function() return domenu(submenu) end)
    return submenu
  end

  -- create a new, unrelated menu. You cannot use super afterwards
  function curriedMethod:new(name)
    return newmenu(name)
  end
  
  -- go back to the previous level, after introducing the automatic Back label
  -- unless this is a top-level menu
  function method:super()
    local mom = self.back
    if mom then
      put(self, "-")
      put(self, "<-- Back", function() return domenu(self.back) end)
      return self.back
     else return self
    end
  end

  -- insert a separator line
  function method:sep()
    return put(self, "-")
  end

  -- and a function to actually execute the thing
  curriedMethod.run = domenu

  -- Finally, we define the Menu "object"
  -- This is a bit of a kludge, because all menus respond to "new"
  -- in the same way. So you could actually just use Menu as your
  -- top-level menu.
  Menu = newmenu("")
end

-------------------------------------------------------------

--  Hologram Viewer v0.7.2 by Totoro (aka MoonlightOwl)
--  Link: https://github.com/MoonlightOwl/holo

-------------------------------------------------------------

holo = {}
colortable = {{},{},{}}
hexcolortable = {}

function set(x, y, z, value)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = value
end
function get(x, y, z)
  if holo[x] ~= nil and holo[x][y] ~= nil and holo[x][y][z] ~= nil then
    return holo[x][y][z]
  else
    return 0
  end
end
function rgb2hex(r,g,b)
  return r*65536+g*256+b
end


local reader = {}
function reader:init(file)
  self.buffer = {}
  self.file = file
end
function reader:read()
  if #self.buffer == 0 then
    if not self:fetch() then return nil end
  end
  local sym = self.buffer[#self.buffer]
  self.buffer[#self.buffer] = nil
  return sym
end
function reader:fetch()
  self.buffer = {}
  local char = file:read(1)
  if char == nil then return false
  else
    local byte = string.byte(char)
    for i=0, 3 do
      local a = byte % 4
      byte = math.floor(byte / 4)
      self.buffer[4-i] = a
    end
    return true
  end
end

local function loadHologram(filename)
  if filename == nil then
    error(def.ERROR_NO_FILENAME)
  end

  local path = shell.resolve(filename, "3dx")
  if path == nil then path = shell.resolve(filename, "3d") end

  if path ~= nil then
    local compressed
    if string.sub(path, -4) == '.3dx' then
      compressed = true
    elseif string.sub(path, -3) == '.3d' then
      compressed = false
    else
      error(def.ERROR_WRONG_FILE_FORMAT)
    end
    file = io.open(path, 'rb')
    if file ~= nil then
      for i=1, 3 do
        for c=1, 3 do
          colortable[i][c] = string.byte(file:read(1))
        end
        hexcolortable[i] = rgb2hex(colortable[i][1], colortable[i][2], colortable[i][3])
      end
      holo = {}
      reader:init(file)
      if compressed then
        local x, y, z = 1, 1, 1
        while true do
          local a = reader:read()
          if a == nil then file:close(); return true end
          local len = 1
          while true do
            local b = reader:read()
            if b == nil then
              file:close()
              if a == 0 then return true
              else error(def.ERROR_INVALID_FORMAT_STRUCTURE) end
            end
            local fin = (b > 1)
            if fin then b = b - 2 end
            len = bit32.lshift(len, 1)
            len = len + b
            if fin then break end
          end
          len = len - 1
          for i = 1, len do
            if a ~= 0 then set(x,y,z, a) end
            z = z + 1
            if z > HOLOW then
              y = y + 1
              if y > HOLOH then
                x = x + 1
                if x > HOLOW then file:close(); return true end
                y = 1
              end
              z = 1
            end
          end
        end
      else
        for x = 1, HOLOW do
          for y = 1, HOLOH do
            for z = 1, HOLOW do
              local a = reader:read()
              if a ~= 0 and a ~= nil then
                set(x, y, z, a)
              end
            end
          end
        end
      end
      file:close()
      return true
    else
      error(def.ERROR_UNABLE_TO_OPEN .. filename)
    end
  else
    error(def.ERROR_FILE_NOT_FOUND .. filename)
  end
end

function clearHologram()
  h1 = com.proxy("39164591-87de-4e61-98ba-dcfe8b7f74a4")
  h2 = com.proxy("afca12db-3bc3-4008-acd8-12cd5390a30d")
  h1.clear()
  h2.clear()
end

function drawHologram()

  -- Written by me, omniscientArchivist
  
  -- Loading Projectors --
  h1 = com.proxy("39164591-87de-4e61-98ba-dcfe8b7f74a4")
  h2 = com.proxy("afca12db-3bc3-4008-acd8-12cd5390a30d")

  if h1 ~= nil and h2 ~= nil then

    local depth = h1.maxDepth() -- This assumes your two projectors are the same.

    -- Configuring Projectors
    h1.clear()
    h1.setScale(proj_scale)
    h2.clear()
    h2.setScale(proj_scale)

    -- send palette
    if depth == 2 then
      for i = 1, 3 do
        h1.setPaletteColor(i, hexcolortable[i])
        h2.setPaletteColor(i, hexcolortable[i])
      end
    else
      h1.setPaletteColor(1, hexcolortable[1])
      h2.setPaletteColor(1, hexcolortable[1])
    end
    -- send voxel array
    for x = 1, HOLOW do
      for y = 1, HOLOH do
        for z = 1, HOLOW do
          n = get(x,y,z)
          if n ~= 0 then
            if depth == 2 then
              h1.set(x, y, z, n)
              h2.set(x, y, z, n)
            else
              h1.set(x, y, z, 1)
              h2.set(x, y, z, 1)
            end
          end
        end
      end
    end
    print(def.HOLOGRAM_DONE)
  else
    error(def.ERROR_NO_PROJECTOR)
  end
end

--------------------------------------

   -- Portal and Operation --

-------------------------------------

function loadPortal(selection)

local function toPositionTable(pos)
    return {
        x = pos.x * 1.0,
        y = pos.y * 1.0,
        z = pos.z * 1.0
    }
end

local function inventorySelection(selection)
  local trans = com.proxy(com.get("e9af2"))
  local sides = require("sides")

  dim = 0

  for key,value in pairs(dimensionalTable) do
    if key == selection then
      dim = value
    end
  end

  if (dim == 0) then
    io.write(def.ERROR_UNREADABLE_SELECTION)
  else 
    trans.transferItem(sides.north, sides.south, dim, 1, 1)
    lockScreen(selection)
  end
end

local function interruptExistingConnections(h)
  trans = h.getTransmitters()
  h.interrupt(toPositionTable(trans[1].position))
  h.interrupt(toPositionTable(trans[2].position))
  h.interrupt(toPositionTable(trans[3].position))
  h.interrupt(toPositionTable(trans[4].position))
end

h = trytofind('rftools_dialing_device')
if h ~= nil then
  interruptExistingConnections(h)
  trans = h.getTransmitters()
  recs = h.getReceivers()
  ndim = #recs
  idx = 1

  for i=1,ndim do
    if recs[i].name == selection then
      idx = i
    end
  end

  local ok1, err1 = h.dial(
      toPositionTable(trans[1].position),
      toPositionTable(recs[idx].position),
      recs[idx].dimension,
    false
  )
  local ok2, err2 = h.dial(
      toPositionTable(trans[2].position),
      toPositionTable(recs[idx].position),
      recs[idx].dimension,
    false
  )
  local ok3, err3 = h.dial(
      toPositionTable(trans[3].position),
      toPositionTable(recs[idx].position),
      recs[idx].dimension,
    false
  )
  local ok4, err4 = h.dial(
      toPositionTable(trans[4].position),
      toPositionTable(recs[idx].position),
      recs[idx].dimension,
   false
  )

  inventorySelection(selection)

else
  io.write("Oh no :(")
end

end

function lockScreen(selection)
  term.clear()
  io.write("---------------------------\n ")
  io.write("Dimension <" .. selection .. "> is loaded. This screen will be unlocked in 120 seconds.")
  io.write(" \n---------------------------")
  os.sleep(120)
end

--------------------------------------

  -- Actual Execution --

--------------------------------------

mainMenu = Menu.new "Main"

for klayer, vlayer in pairs(dimensionalTree) do
  mainMenu = mainMenu.sub(klayer)
  for ksublayer, vsublayer in pairs(vlayer) do
    mainMenu = mainMenu.sub(ksublayer)
    for kelement, velement in pairs(vsublayer) do
      mainMenu = mainMenu.add(kelement, velement)
    end
    mainMenu = mainMenu
    .super
  end
  mainMenu = mainMenu
  .super
  .sep
end

while true do
  clearHologram()
  local selection = mainMenu.run()
  if not selection then break end
  loadHologram(selection)
  drawHologram()
  loadPortal(selection)
end