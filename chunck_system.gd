extends Node2D

var chunkDictionary : Dictionary = {}
var chunkLoadedDictionnary : Dictionary = {}
var production : Array = []
var chunkSize : int = 3200
@export var nbChunkLayer : int = 1
var offset = -32
@export var unloadChunk : bool

@onready var camera = $"../TopDownCamera"

var buildArray : Array = []
var lastPlayerChunk = Vector2(-99999999, -99999999)
var chunkIndex : Dictionary = {}

const BUILDING_SIZES : Dictionary = {
	"Mine": Vector2(128, 140),
	"Foundry": Vector2(128, 280),
	"Crafter": Vector2(256, 282),
	"SuperCrafter": Vector2(384, 280.5),
	"MegaCrafter": Vector2(512, 410.5),
	"Balancer": Vector2(384, 150.5),
}


func _process(_delta: float) -> void:
	var coord = Vector2(
		floori((camera.global_position.x + offset) / chunkSize),
		floori((camera.global_position.y + offset) / chunkSize)
	)
	
	if coord == lastPlayerChunk:
		return
	
	lastPlayerChunk = coord
	checkPlayerChunkPosition()

func getChunkKey(chunk: Vector2) -> String:
	return "%d:%d" % [chunk.x, chunk.y]

func createChunk():
	var buildArray : Array = $"../SaveSystem".buildingArray
	buildArray = addLineOf(buildArray)
	
	if buildArray == []:
		push_error("Chunk System : buildArray empty")
	
	# Creation of the chunk with no Line
	for build in buildArray:
		if build["buildName"] == "Line":
			if build.has("inLineInOf"):
				if build["inLineInOf"] == null:
					build["inLineInOf"] = "999"
			else:
				build["inLineInOf"] = "999"
			continue
		
		if build["buildName"] == "Balancer":
			if !build.has("inventory"):
				build["inventory"] = []
		
		var bPos = str_to_var("Vector2" + build["global_position"])
		var chunkPosx = floor((bPos.x + offset) / chunkSize)
		var chunkPosy = floor((bPos.y + offset) / chunkSize)
		var buildChunkPos = Vector2(chunkPosx, chunkPosy)
		var chunkKey = getChunkKey(buildChunkPos)
		
		var betweenTwoChunk = isBetweenTwoChunk(bPos, chunkKey, build["buildName"], build)
		
		if !chunkDictionary.has(chunkKey):
			chunkDictionary[chunkKey] = []
		
		chunkDictionary[chunkKey].append(build)
		chunkLoadedDictionnary[chunkKey] = false
		
		if betweenTwoChunk.size() > 0:
			for chunk in betweenTwoChunk:
				chunkKey = getChunkKey(chunk)
				if !chunkDictionary.has(chunkKey):
					chunkDictionary[chunkKey] = []
				
				chunkDictionary[chunkKey].append(build)
				chunkLoadedDictionnary[chunkKey] = false
	
	# Add Line, has the same chunk has there lineOutOf building (To always be instantiate even between two chunk)
	for build in buildArray:
		if build["buildName"] != "Line":
			continue
		
		if build["buildName"] == "Line":
			var chunkToPut : Array = []
			for b in buildArray:
				var parentFound := false
				
				if build.has("inLineInOf") and b["buildId"] == str(build["inLineInOf"]):
					parentFound = true
				
				if build.has("inLineOutOf") and b["buildId"] == str(build["inLineOutOf"]):
					parentFound = true
				
				if parentFound:
					var chunkPosx = floor((str_to_var("Vector2" + b["global_position"]).x + offset) / chunkSize)
					var chunkPosy = floor((str_to_var("Vector2" + b["global_position"]).y + offset) / chunkSize)
					var buildChunkPos = Vector2(chunkPosx, chunkPosy)
					var chunkKey = getChunkKey(buildChunkPos)
					
					var bPos = str_to_var("Vector2" + build["global_position"])
					var betweenTwoChunk = isBetweenTwoChunk(bPos, chunkKey, build["buildName"], b)
					
					if !chunkDictionary.has(chunkKey):
						chunkDictionary[chunkKey] = []
					
					chunkDictionary[chunkKey].append(build)
					chunkToPut.append(chunkKey)
					chunkLoadedDictionnary[chunkKey] = false
					
					if betweenTwoChunk.size() > 0:
						for chunk in betweenTwoChunk:
							chunkKey = getChunkKey(chunk)
							if !chunkDictionary.has(chunkKey):
								chunkDictionary[chunkKey] = []
							
							chunkDictionary[chunkKey].append(build)
							if !chunkToPut.has(chunkKey):
								chunkToPut.append(chunkKey)
							chunkLoadedDictionnary[chunkKey] = false
			
			if !build.has("chunk"):
				build["chunk"] = []
			
			build["chunk"] = chunkToPut
	
	$"../SimulationManager".createBuildingArray()


func isBetweenTwoChunk(buildingPos, chunkPos, buildingName, building):
	var xCoordinate = float(chunkPos.get_slice(":", 0))
	var yCoordinate = float(chunkPos.get_slice(":", 1))
	var current = Vector2(xCoordinate, yCoordinate)
	var intersectPointArray : Array = []
	
	if buildingName == "Line":
		if typeof(building) != TYPE_DICTIONARY:
			var line = get_building_from_chunk(chunkPos, building.buildid)
			var vector2Array : Array = []
			if line != null and line.has("chunk"):
				for chunk in line["chunk"]:
					var chunkX = float(chunk.get_slice(":", 0))
					var chunkY = float(chunk.get_slice(":", 1))
					vector2Array.append(Vector2(chunkX, chunkY))
				return vector2Array
		return intersectPointArray
	
	var size : Vector2 = BUILDING_SIZES.get(buildingName, Vector2.ZERO)
	var rect = Rect2(buildingPos - size * 0.5, size)
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 && y == 0:
				continue
			
			var neighbor = current + Vector2(x, y)
			
			var xChunkCoord = neighbor.x * chunkSize - offset
			var yChunkCoord = neighbor.y * chunkSize - offset
			
			var selection = Rect2(Vector2(xChunkCoord, yChunkCoord), Vector2(chunkSize, chunkSize))
			
			if selection.intersects(rect):
				intersectPointArray.append(neighbor)
	
	return intersectPointArray


func checkPlayerChunkPosition():
	$"..".isWorldLoaded = true
	var xPos = floor(($"../TopDownCamera".global_position.x + offset) / chunkSize)
	var yPos = floor(($"../TopDownCamera".global_position.y + offset) / chunkSize)
	var current = Vector2(xPos, yPos)
	
	queue_redraw()
	
	var chunksToLoad : Array[String] = []
	
	for x in range(-nbChunkLayer, nbChunkLayer + 1):
		for y in range(-nbChunkLayer, nbChunkLayer + 1):
			
			var chunkPos = current + Vector2(x, y)
			
			var key = getChunkKey(chunkPos)
			
			chunksToLoad.append(key)
			
			if !chunkLoadedDictionnary.has(key):
				buildArray = createNewBuildArray()
				saveChunk(key)
				chunkLoadedDictionnary[key] = false
			
			if !chunkLoadedDictionnary[key]:
				var possibleNewChunkData = $"../SimulationManager".unloadBuildingArray(chunkDictionary[key])
				chunkDictionary[key] = possibleNewChunkData if possibleNewChunkData != [] else chunkDictionary[key]
				$"../SaveSystem".loadBuildingChunk(
					chunkDictionary[key],
					false
				)
				chunkLoadedDictionnary[key] = true
	
	
	if unloadChunk:
		buildArray = createNewBuildArray()
		unloadChunks(chunksToLoad)
		$"../SimulationManager".createBuildingArray()


func unloadChunks(chunksToKeep : Array):
	if unloadChunk:
		for chunk in chunkLoadedDictionnary.keys():
			if chunksToKeep.has(chunk):
				continue
			
			if !chunkLoadedDictionnary[chunk]:
				continue
			saveChunk(chunk)
			
			checkBuildingPosition(chunk, chunksToKeep)
			chunkLoadedDictionnary[chunk] = false


func checkBuildingPosition(chunk, actualChunk):
	if !chunkIndex.has(chunk):
		return
	
	for b in chunkIndex[chunk]:
		if !b.has("node") or !is_instance_valid(b["node"]):
			continue
		
		if !b.has("chunk"):
			continue
		
		var shouldStayLoaded = false
		for c in actualChunk:
			if b["chunk"].has(c):
				shouldStayLoaded = true
				break
		
		if !shouldStayLoaded:
			b["node"].queue_free()


func createNewBuildArray():
	var build : Array = []
	var coord = Vector2.ZERO
	
	chunkIndex.clear()
	
	for container in $"../BuildingContainer".get_children():
		for building in container.get_children():
			var buildAlone = $"../SaveSystem".saveBuilding(building, false)
			
			var mainBuildDict = null
			for b in buildAlone:
				if b["buildName"] == building.buildName:
					mainBuildDict = b
					break
			
			if mainBuildDict == null:
				push_error("createNewBuildArray : could not find main build dict for " + building.name)
				build.append_array(buildAlone)
				continue
			
			mainBuildDict["node"] = building
			
			if mainBuildDict["buildName"] != "Line":
				coord = Vector2(
					floori((building.global_position.x + offset) / chunkSize),
					floori((building.global_position.y + offset) / chunkSize)
				)
				var key : String = getChunkKey(coord)
				
				var otherChunk = isBetweenTwoChunk(building.global_position, key, building.buildName, mainBuildDict)
				
				var chunkKeys : Array[String] = [key]
				if otherChunk.size() > 0:
					for chunk in otherChunk:
						var newKey = getChunkKey(chunk)
						if !chunkKeys.has(newKey):
							chunkKeys.append(newKey)
				
				mainBuildDict["chunk"] = chunkKeys
			
			build.append_array(buildAlone)
	
	var buildById : Dictionary = {}
	for b in build:
		buildById[b["buildId"]] = b
	
	for b in build:
		if b["buildName"] != "Line":
			continue
		
		var chunkToPut : Array[String] = []
		
		if b.has("inLineInOf") and buildById.has(b["inLineInOf"]):
			var parent = buildById[b["inLineInOf"]]
			if parent.has("chunk"):
				for c in parent["chunk"]:
					if !chunkToPut.has(c):
						chunkToPut.append(c)
		
		if b.has("inLineOutOf") and buildById.has(b["inLineOutOf"]):
			var parent = buildById[b["inLineOutOf"]]
			if parent.has("chunk"):
				for c in parent["chunk"]:
					if !chunkToPut.has(c):
						chunkToPut.append(c)
		
		b["chunk"] = chunkToPut
	
	for b in build:
		if !b.has("chunk"):
			continue
		for c in b["chunk"]:
			if !chunkIndex.has(c):
				chunkIndex[c] = []
			chunkIndex[c].append(b)
	
	return build


func saveChunk(chunk):
	if !chunkDictionary.has(chunk):
		chunkDictionary[chunk] = []
	
	chunkDictionary[chunk] = chunkIndex[chunk] if chunkIndex.has(chunk) else []



func saveLastChunk():
	var xPos = floor(($"../TopDownCamera".global_position.x + offset) / chunkSize)
	var yPos = floor(($"../TopDownCamera".global_position.y + offset) / chunkSize)
	var current = Vector2(xPos, yPos)
	
	createNewBuildArray()
	
	for x in range(-nbChunkLayer, nbChunkLayer + 1):
		for y in range(-nbChunkLayer, nbChunkLayer + 1):
			var chunkPos = current + Vector2(x, y)
			
			var key = getChunkKey(chunkPos)
			
			saveChunk(key)


func get_building_from_chunk(chunk: String, id: String):
	for building in chunkDictionary[chunk]:
		if building["buildId"] == id:
			return building
	
	return null


func _draw() -> void:
	if !$"..".isDevModeActivated:
		return
	
	for chunk in chunkLoadedDictionnary:
		var xCoordinate = float(chunk.get_slice(":", 0)) * chunkSize - offset
		var yCoordinate = float(chunk.get_slice(":", 1)) * chunkSize - offset
		
		var rect = Rect2(Vector2(xCoordinate, yCoordinate),Vector2(chunkSize, chunkSize))
		
		draw_rect(rect, Color.GREEN, false)


func addLineOf(buildList):
	var newBuildArray : Array = buildList.duplicate(true)
	
	var buildByTreeName : Dictionary = {}
	var buildById : Dictionary = {}
	
	for build in newBuildArray:
		buildByTreeName[build["treeBuildName"]] = build
		buildById[build["buildId"]] = build
	
	
	for build in newBuildArray:
		if build["buildName"] == "Line":
			continue
		
		for i in range(build["lineOutName"].size()):
			var lineOut = build["lineOutName"][i]
			
			if !lineOut.contains("Node2D"):
				continue
			
			var outBuild = buildByTreeName[lineOut]
			var idOfLineOut = outBuild["buildId"]
			build["lineOutName"][i] = idOfLineOut
			
			
			outBuild["inLineOutOf"] = build["buildId"]
		
		if build.has("lineInName"):
			for i in range(build["lineInName"].size()):
				var lineIn = build["lineInName"][i]
				var inBuild = -1
				
				if buildById.has(lineIn):
					inBuild = buildById[lineIn]
					inBuild["inLineInOf"] = build["buildId"]
		
	
	return newBuildArray


func createBuildArray(chunkToLook):
	var buildingArray = []
	var savedIds := {}
	
	for chunk in chunkDictionary:
		if chunkToLook != null:
			if chunk != chunkToLook:
				continue
		for building in chunkDictionary[chunk]:
			if savedIds.has(building["buildId"]):
				continue
			
			savedIds[building["buildId"]] = true
			buildingArray.append(building)
	
	return buildingArray
