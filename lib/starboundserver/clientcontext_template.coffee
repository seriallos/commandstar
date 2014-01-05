starClientContext =
  vlqu: () ->
    type = 'uint8'
    array = []
    val = @parse(type)
    array.push val
    while val > 127
      val = @parse(type)
      array.push val
    array.reduce (t, s) -> t + s

  entityTeamDamage:
    val: 'uint8',
    unknown: 'uint8',
    team: ->
      switch @.current.val
        when 0 then "null"
        when 1 then "friendly"
        when 2 then "enemy"
        when 3 then "pvp"
        when 4 then "passive"
        when 5 then "ghostly"
        when 6 then "emitter"
        when 7 then "indiscriminate"
        else "INVALID"

  utf8str:
    len: 'uint8',
    str: ['string', -> @.current.len]

  sectorStatus:
    name: 'utf8str'
    unlocked: 'uint8'

  vec3i:
    x: 'int32'
    y: 'int32'
    z: 'int32'

  systemCoordinate:
    sector_raw: 'utf8str',
    sector: -> @.current.sector_raw["str"],
    location: 'vec3i'

  worldCoordinate:
    system: 'systemCoordinate',
    planetaryBodyNumber: 'int32',
    satelliteBodyNumber: 'int32'

  celestialLog: 
    dataStreamSize: 'vlqu',
    numRecentlyVisited: 'vlqu'
    numSectors: 'vlqu',
    sectors: ['array', 'sectorStatus', 5]
    numVisted: 'uint8',
    visitedSystems: ['array', 'systemCoordinate', -> @.current.numVisted]
    currentSystem: 'worldCoordinate',
    homeWorld: 'worldCoordinate'

  context: 
    header: ['string', 6],
    version: ['uint32', true],
    dataStreamLength: 'vlqu',
    isAdmin: 'uint8',
    entityTeamDamage: 'entityTeamDamage',
    celestialLog: 'celestialLog'

exports.starClientContext = starClientContext
