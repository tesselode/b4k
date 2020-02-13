return {
  version = "1.2",
  luaversion = "5.1",
  tiledversion = "1.3.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 8,
  height = 8,
  tilewidth = 1,
  tileheight = 1,
  nextlayerid = 2,
  nextobjectid = 1,
  properties = {
    ["moves"] = 3
  },
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      filename = "tiles.tsx",
      tilewidth = 1,
      tileheight = 1,
      spacing = 0,
      margin = 0,
      columns = 4,
      image = "tiles.png",
      imagewidth = 4,
      imageheight = 1,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 1,
        height = 1
      },
      properties = {},
      terrains = {},
      tilecount = 4,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      id = 1,
      name = "tiles",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 0, 0, 0,
        0, 0, 4, 0, 3, 4, 0, 0,
        0, 0, 1, 2, 2, 2, 0, 0,
        0, 4, 1, 1, 1, 2, 4, 0,
        0, 4, 4, 3, 3, 4, 4, 0
      }
    }
  }
}
