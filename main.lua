pancake =  require "pancake"
function love.load()
	math.randomseed(os.time())
	pancake.init({window = {pixelSize = love.graphics.getHeight()/64}, loadAnimation = false, 
		layerDepth = 0, physics = {defaultFriction = 0.85}}) 
	--Initiating pancake and setting pixelSize, so that the pancake display will be the height of the window! 
	--pixelSize is how many pixels every pancake pixel should take
	pancake.background = {r=0, g=0, b=0, a=1}

	scoreString = pancake.load("savefile")
	if scoreString == nil or scoreString == "" then
		scoreString = "0,59999"
	end
	highScore = scoreString:split(',')[1]
	bestTime = scoreString:split(',')[2]

	if highScore == nil or highScore == "" then highScore = 0 end
	if bestTime == nil or bestTime == "" then bestTime = 59999 end

	keys = {}
	loaded = false
	gameOver = false
	
	player = pancake.addObject({x = 29, y = 30, width = 8, height = 8, name = "climber", 
		colliding = true, offsetX = 0, offsetY = 0, layer = 2})
	camera = pancake.addObject({x = 29, y = 30, width = 0, height = 0, name = "camera", 
		colliding = false, offsetX = 0, offsetY = 0, layer = 2})
	staminaGauge = pancake.addObject({x = 29, y = 30, width = 8, height = 8, name = "stamina", 
		colliding = false, offsetX = 0, offsetY = 0, layer = 1})

	pancake.addImage("highScore","images")
	highScoreLabel = pancake.addObject({x = 20, y = 100, width = 40, height = 8, name = "highScore", 
		colliding = false, offsetX = 0, offsetY = 0, layer = 1, image = "highScore"})

	pancake.addImage("jumpTutorial","images")
	jumpTutorial = pancake.addObject({x = 12, y = 31, width = 32, height = 32, name = "jumpTutorial", 
		colliding = false, offsetX = 0, offsetY = 0, layer = 1})

	pancake.addImage("climbTutorial","images")
	climbTutorial = pancake.addObject({x = 10, y = 4, width = 32, height = 32, name = "climbTutorial", 
		colliding = false, offsetX = 0, offsetY = 0, layer = 1})

	blocks = {}
	blockPool = {}
	spikes = {}
	spikePool = {}
	victoryHeight = -1600

	levelLength = 300
	numBlocks = 0
	numSpikes = 0
	--pancake.onLoad()
end

function love.keypressed(key)
	keys[key] = true

	if loaded then
		if key == "z" then
			if pancake.facing(player).down or 
				(doubleJump and not hasDoubleJumped) or 
				((pancake.facing(player).left or pancake.facing(player).right) and wallJump) then
				local yForce = -70
				local xForce = 0
				if not pancake.facing(player).down then
					if doubleJump then
						useStamina(10)
					end
					hasDoubleJumped = true
				end
				if highJump and keys["up"] then
					useStamina(10)
					yForce = yForce - 50
				end
				if (pancake.facing(player).left or pancake.facing(player).right) and 
					not pancake.facing(player).down and wallJump then
					useStamina(5)
					yForce = yForce + 10
					if pancake.facing(player).left then
						xForce = xForce + 20
					end
					if pancake.facing(player).right then
						xForce = xForce - 20
					end
				end
				jumpSound:stop()
				jumpSound:play()
				pancake.applyForce(player, {x = xForce, y = yForce, relativeToMass = true}, 1)
				player.image = "climber_run3"
				player.animation = nil
			end
		end

		if key == "x" then
			if not pancake.facing(player).down and spawnPlatform and resolve >= 25 then
				createPlatform(player.x,player.y+8,0)
				resolve = resolve - 25
			end
			if pancake.facing(player).up and breakCeiling and resolve >= 25 then
				local ceiling = pancake.getFacingObjects(player).up
				for i=1,#ceiling do
					if ceiling[i] ~= nil and ceiling[i].image == "ground" then
						poolBlock(ceiling[i])
						ceiling[i] = nil
						resolve = resolve - 25
					end
				end
			end
		end

		if key == "d" then
			--pancake.debugMode = not pancake.debugMode
		end
	end
end

function love.keyreleased(key)
	keys[key] = false
end

function pancake.onCollision(object1, object2, axis, direction, sc) 
	--This function will be called whenever a physics object collides with a colliding object!
	--Insert your amazing code here!
	if object1 == player and object2.image == "spike" and axis == "y" and direction == 1 then
		die()
	end
	if object1 == player and object2.method ~= nil then
		object2.x = -100
		object2.method()
		pickupSound:play()
	end
end

function pancake.onLoad() -- This function will be called when pancake start up is done (after the animation)
	--Insert your amazing code here!
	--cleanup powerups
	for i=1,#pancake.objects do
		if pancake.objects[i].method ~= nil then
			pancake.trash(pancake.objects, pancake.objects[i].image, "image")
		end
	end

	started = true
	player.x = 29
	player.y = 30
	camera.x = 29
	camera.y = 30
	highScoreLabel.y = -highScore
	if highScore == 0 then highScoreLabel.x = -100 else highScoreLabel.x = 20 end

	pancake.addAnimation("climber", "idle", "images/animations", 500)
	pancake.addAnimation("climber", "run", "images/animations", 150)
	pancake.addAnimation("staminaGauge", "dial", "images/animations", 150)
	pancake.addImage("ground","images")
	pancake.addImage("spike","images")
	pancake.addImage("star","images")
	pancake.changeAnimation(player, "idle")

	--tutorial
	createPlatform(-3, 64, 3)
	createPlatform(29, 64, 3)
	createPlatform(-4, 48, 3)
	createPlatform(42, 8, 3)
	createWall(42, 8, 3)

	--walls
	createWall(-8, 32, 3)
	createWall(58, 32, 3)
	createWall(-8, 0, 3)
	createWall(58, 0, 3)
	createWall(-8, -32, 3)
	createWall(58, -32, 3)
	pancake.applyPhysics(player)
	pancake.cameraFollow = camera
	frameCount = 0
	maxStamina = 100
	stamina = maxStamina
	resolve = 500
	highest = 0
	deathFloor = 68
	score = 0
	lastSafeLocation = {0, 0}
	gameOver = false
	loaded = true
	labels = {}
	music = love.audio.newSource('sounds/side_b.mp3', 'stream')
	gameOverMusic = love.audio.newSource('sounds/side_a.mp3', 'stream')
	victoryMusic = love.audio.newSource('sounds/victory.mp3', 'stream')
	climbSound = love.audio.newSource('sounds/climb.wav', 'static')
	jumpSound = love.audio.newSource('sounds/jump.wav', 'static')
	deathSound = love.audio.newSource('sounds/death.wav', 'static')
	pickupSound = love.audio.newSource('sounds/pickup.wav', 'static')
	music:setLooping(true)
	music:setVolume(0.3)
	music:play()
	hasDoubleJumped = false
	hasDashed = false
	climbSpeed = 1000--1250
	airControl = 75--125
	lastLevel = 1
	jumpTutorial.image = "jumpTutorial"
	climbTutorial.image = "climbTutorial"
	hasGeneratedVictory = false
	victory = false
	victoryTime = ""
	startTime = os.time()
	endTime = 0

	--abilities
	breakCeiling = false 		--x
	doubleJump = false			--x
	highJump = false 			--x
	wallJump = false			--x
	airDash = false				--
	spawnPlatform = false		--x
	--improvedAirControl		--x
	cornerClimb = false			--
	--fastClimb					--x
	--healResolve				--x
	--maxStamina				--x

	pancake.addImage("breakCeiling","images")
	pancake.addImage("doubleJump","images")
	pancake.addImage("highJump","images")
	pancake.addImage("wallJump","images")
	pancake.addImage("spawnPlatform","images")
	pancake.addImage("airControl","images")
	pancake.addImage("fastClimb","images")
	pancake.addImage("healResolve","images")
	pancake.addImage("maxStamina","images")

	powerups = {
		{image = "breakCeiling", label = "X: attack upward!", method = function() breakCeiling = true end, unique = true},
		{image = "doubleJump", label = "Jump twice!", method = function() doubleJump = true end, unique = true},
		{image = "highJump", label = "up and Z!", method = function() highJump = true end, unique = true},
		{image = "wallJump", label = "jump off walls!", method = function() wallJump = true end, unique = true},
		{image = "spawnPlatform", label = "X makes a block!", method = function() spawnPlatform = true end, unique = true},
		{image = "airControl", label = "Better Air Control!", method = function() airControl = 125 end, unique = true},
		{image = "fastClimb", label = "Better climb!", method = function() climbSpeed = 1250 end, unique = true},
		{image = "healResolve", label = "Full resolve!", method = function() resolve = 500 end, unique = false},
		{image = "maxStamina", label = "More stamina!", method = function() maxStamina = 120 end, unique = false},
	}
end

function pancake.onOverlap(object1, object2, dt) 
	--This function will be called every time object "collides" with a non colliding object! 
	--Parameters: object1, object2 - objects of collision, dt - time of collision
	--Insert your amazing code here!
end

function love.draw()
	if gameOver == false then
		pancake.draw() 
		--Sets the canvas right! If pancake.autoDraw is set to true (which is its default state) 
		--the canvas will be automatically drawn on the window x and y
		if loaded then
			if started then
				love.graphics.setColor(1, 0, 0, 1)
				pancake.print(math.ceil(resolve/5), 2*pancake.window.pixelSize, 
					2*pancake.window.pixelSize, pancake.window.pixelSize)
				love.graphics.setColor(1, 1, 0, 1)
				pancake.print(score, 32*pancake.window.pixelSize, 
					2*pancake.window.pixelSize, pancake.window.pixelSize)
				love.graphics.setColor(1, 0, 1, 1)
				for i=1,#labels do
					pancake.print(labels[i].label, 32, pancake.windowToDisplay(0,labels[i].y, true).y, pancake.window.pixelSize)
				end
			end
		end
	else
		if victory == true then
			love.graphics.setColor(0, 0, 1, 1)
			pancake.print("YOU WIN!", 8*pancake.window.pixelSize, 
				12*pancake.window.pixelSize, pancake.window.pixelSize)
			pancake.print("time: "..os.date("%M:%S", victoryTime), 8*pancake.window.pixelSize, 
				20*pancake.window.pixelSize, pancake.window.pixelSize)
			love.graphics.setColor(1, 1, 0, 1)
			pancake.print("BEST TIME:", 8*pancake.window.pixelSize, 
				28*pancake.window.pixelSize, pancake.window.pixelSize)
			pancake.print(os.date("%M:%S", bestTime), 8*pancake.window.pixelSize, 
				36*pancake.window.pixelSize, pancake.window.pixelSize)
		else
			love.graphics.setColor(0, 0, 1, 1)
			pancake.print("GAME OVER", 8*pancake.window.pixelSize, 
				12*pancake.window.pixelSize, pancake.window.pixelSize)
			pancake.print("score: "..score, 8*pancake.window.pixelSize, 
				20*pancake.window.pixelSize, pancake.window.pixelSize)
			love.graphics.setColor(1, 1, 0, 1)
			pancake.print("HIGH SCORE", 8*pancake.window.pixelSize, 
				28*pancake.window.pixelSize, pancake.window.pixelSize)
			pancake.print(highScore, 8*pancake.window.pixelSize, 
				36*pancake.window.pixelSize, pancake.window.pixelSize)
		end
		love.graphics.setColor(1, 0, 0, 1)
		pancake.print("X: restart", 8*pancake.window.pixelSize, 
				44*pancake.window.pixelSize, pancake.window.pixelSize)
	end
end

function love.update(dt)
	if loaded then
		if gameOver == false then
			frameCount = frameCount + 1
			if keys["right"] then
				local force = airControl
				if pancake.facing(player).down then
					force = 200
				end
			  	pancake.applyForce(player, {x = force, y = 0, relativeToMass = true})
			  	pancake.changeAnimation(player, "run")
			  	player.flippedX = false
			end
			if keys["left"] then
				local force = airControl
				if pancake.facing(player).down then
					force = 200
				end
			  	pancake.applyForce(player, {x = -force, y = 0, relativeToMass = true})
			  	pancake.changeAnimation(player, "run")
			  	player.flippedX = true
			end
			if not keys["right"] and not keys["left"] then
				if pancake.facing(player).down then
					if player.velocityX == 0 then
						pancake.changeAnimation(player, "idle")
					else
						player.image = "climber_idle1"
						player.animation = nil  
					end
				else
					player.image = "climber_run3"
					player.animation = nil
				end
			end
			if keys["z"] then
				if (pancake.facing(player).left or pancake.facing(player).right) and (resolve > 0 or stamina > 0) then
					local climb = 1
					if not pancake.facing(player).down then
						useStamina(1)
					end
					if keys["up"] and frameCount%8 == 0 then
						climbSound:setPitch(math.random()/6+1.8)
						climbSound:play()
						climb = climb + climbSpeed
						useStamina(1)
					end
					if keys["down"] then
						climb = climb - 20
					end
					if player.velocityY >= 0 then
						climb = climb + pancake.physics.gravityY
					end
					pancake.applyForce(player, {x = 0, y = -(climb+1), relativeToMass = true})
				end
			end

			--set camera to follow player
			camera.y = math.min(player.y + 8, deathFloor - 24)

			--recharge stamina when safe
			if pancake.facing(player).down then
				hasDashed = false
				hasDoubleJumped = false
				stamina = math.min(maxStamina, stamina + 2)
				lastSafeLocation = {player.x, player.y}
				deathFloor = math.min(deathFloor, camera.y + 32)
				score = math.abs(math.floor(math.max(score, -player.y)))
			end

			--stamina gauge
			if stamina < 100 then
				staminaGauge.image = "staminaGauge_dial"..math.min(25, math.max(1, math.floor(((100-stamina)/4)+1)))
			else
				staminaGauge.image = "staminaGauge_dial25"
			end

			staminaGauge.y = player.y - 8
			staminaGauge.x = player.x

			--level gen
			if camera.y - 128 < highest then
				--generate a new level chunk
				highest = highest - 64
				if highest < victoryHeight and not hasGeneratedVictory then
					spawnVictoryChunk(highest + 16)
					hasGeneratedVictory = true
				else
					local level = math.floor(score/levelLength)+1
					if level == lastLevel then
						spawnPlatforms(highest, highest+64, level)
					else
						spawnPowerupChunk(highest+24)
					end
					lastLevel = level
					for i=1,#blocks do
						if blocks[i].y > deathFloor + 128 then
							poolBlock(blocks[i])
							blocks[i] = nil
						end
					end
					for i=1,#spikes do
						if spikes[i].y > deathFloor + 128 then
							poolSpike(spikes[i])
							spikes[i] = nil
						end
					end
					spikes = defrag(spikes, numSpikes)
					blocks = defrag(blocks, numBlocks)
					spikePool = defrag(spikePool, numSpikes)
					blockPool = defrag(blockPool, numBlocks)
				end
			end

			--respawn player
			if player.y > camera.y + 32 then
				die()
			end
		else
			if keys["x"] then
				gameOverMusic:stop()
				victoryMusic:stop()
				pancake.onLoad()
			end
		end
	end
	if gameOver == false then
		pancake.update(dt) --Passing time between frames to pancake!
	end
end

function die()
	pancake.shakeScreen()
	--respawn the player
	deathSound:play()
	player.x = lastSafeLocation[1]
	player.y = lastSafeLocation[2]
	player.velocityX = 0
	player.velocityY = 0
	if player.y > camera.y + 32 then
		camera.y = math.min(player.y + 8, deathFloor-32)
	end
	resolve = resolve - 50
	if resolve < 0 then
		gameOver = true
		for i=1,#blocks do
			poolBlock(blocks[i])
			blocks[i] = nil
		end
		for i=1,#spikes do
			poolSpike(spikes[i])
			spikes[i] = nil
		end
		highScore = math.max(score, highScore)
		pancake.save(highScore..","..bestTime, "savefile")
		music:stop()
		gameOverMusic:play()
	end
end

function poolBlock(block)
	block.x = -100
	blockPool[#blockPool+1] = block
end

function getBlock(x, y)
	if #blockPool > 0 then
		local ret = blockPool[#blockPool]
		blockPool[#blockPool] = nil
		ret.x = x
		ret.y = y
		return ret
	else
		numBlocks = numBlocks + 1
		return pancake.addObject({x = x, y = y, image = "ground", 
		colliding = true, width = 8, height = 8, layer = 2})
	end
end

function poolSpike(spike)
	spike.x = -100
	spikePool[#spikePool+1] = spike
end

function getSpike(x, y)
	if #spikePool > 0 then
		local ret = spikePool[#spikePool]
		spikePool[#spikePool] = nil
		ret.x = x
		ret.y = y
		return ret
	else
		numSpikes = numSpikes + 1
		return pancake.addObject({x = x, y = y, image = "spike", 
    	colliding = true, width = 8, height = 8, layer = 2})
	end
end

function love.mousepressed(x,y,button)
	pancake.mousepressed(x,y,button) -- Passing your presses to pancake!
end

--Create a function to create a platform!
function createPlatform(x,y,l)
	for i = 0, l do
		blocks[#blocks+1] = getBlock(x + i*8, y)
	end
end

function createSpikePlatform(x,y,l)
	for i = 0, l do
		blocks[#blocks+1] = getBlock(x + i*8, y)
		spikes[#spikes+1] = getSpike(x + i*8, y-8)
	end
end

function createWall(x,y,l)
	for i = 0, l do
		blocks[#blocks+1] = getBlock(x, y + i*8)
	end
end

function threeLittlePlatforms(x, y)
	for i=0,1 do
		createPlatform(x+(i*20), y, 0)
	end
end

function useStamina(amount)
	local overflow = -math.min(0, stamina - amount)
	stamina = math.max(0, stamina - amount)
	resolve = math.max(0, resolve - overflow)
end

function spawnPlatforms(start, finish, level)
	local chunkHeight = 20+level*2
	local iterations = math.ceil((finish - start)/chunkHeight)
	createWall(-10+math.random(4), start, math.ceil(chunkHeight/16))
	createWall(60-math.random(4), start, math.ceil(chunkHeight/16))
	for i=1,iterations do
		createWall(-10+math.random(4), start+i*chunkHeight, math.ceil(chunkHeight/16))
		createWall(60-math.random(4), start+i*chunkHeight, math.ceil(chunkHeight/16))
		--spawn some level chunk type thing for the next 16 pixelSize
		if level == 1 then
			spawnChunk1(finish - i*chunkHeight)
		elseif level == 2 then
			spawnChunk2(finish - i*chunkHeight)
		elseif level == 3 then
			spawnChunk3(finish - i*chunkHeight)
		else
			spawnChunk4(finish - i*chunkHeight)
		end
	end
end

function spawnChunk1(y)
	local rand = math.random(4)
	if rand == 1 then
		threeLittlePlatforms(8 + math.random(16), y)
	elseif rand == 2 then
		createWall(math.random(56)+4, y, 1)
	elseif rand == 3 then
		local x = math.random(56)+4
		createPlatform(x, y, 2)
		createPlatform(x-24, y+8, 0)
		createPlatform(x+40, y+8, 0)
	else
		createPlatform(math.random(8)+24, y, 0)
	end
end

function spawnChunk2(y)
	local rand = math.random(4)
	if rand == 1 then
		createPlatform(math.random(8)+8, y, 0)
	elseif rand == 2 then
		createPlatform(math.random(8)+16, y+8, 0)
	elseif rand == 3 then
		createPlatform(math.random(8)+32, y-8, 0)
	else
		createPlatform(math.random(8)+48, y, 0)
	end
end

function spawnChunk3(y)
	local rand = math.random(4)
	if rand == 1 then
		createPlatform(24 + math.random(16), y-8, 1)
	elseif rand == 2 then
		createWall(math.random(50)+8, y, 2)
	elseif rand == 3 then
		createSpikePlatform(math.random(46)+10, y, 2)
	else
		createSpikePlatform(math.random(8)+24, y, 0)
	end
end

function spawnChunk4(y)
	local x = math.random(50)+8
	createWall(x, y, 0)
	createSpikePlatform(x, y-8, 0)
end

function spawnPowerupChunk(y)
	createWall(-10+math.random(4), y, 4)
	createWall(60-math.random(4), y, 4)
	shuffle(powerups)
	local powerup = powerups[#powerups]
	if powerup.unique then
		powerups[#powerups] = nil
	end
	if powerup.image == "healResolve" and resolve >= 450 then
		powerup = powerups[#powerups]
		if powerup.unique then
			powerups[#powerups] = nil
		end
	end
	createPlatform(12, y+16, 3)
	createPlatform(12, y-16, 3)

	pancake.addObject({x = 20, y = y, image = powerup.image, 
    colliding = true, width = 16, height = 16, layer = 2, method = powerup.method})
    labels[#labels+1] = {y = y, label = powerup.label}
end

function spawnVictoryChunk(y)
	createWall(-10, y-200, 30)
	createWall(60, y-200, 30)
	createPlatform(12, y+24, 3)

	pancake.addObject({x = 20, y = y+8, image = "star", 
    colliding = true, width = 16, height = 16, layer = 2, method = win})
    labels[#labels+1] = {y = y, label = "Congratulations!"}
end

function win()
	endTime = os.time()
	victoryTime = endTime - startTime
	bestTime = math.min(victoryTime, bestTime)
	highScore = math.max(score, highScore)
	pancake.save(highScore..","..bestTime, "savefile")
	victory = true
	gameOver = true
	for i=1,#blocks do
		poolBlock(blocks[i])
		blocks[i] = nil
	end
	for i=1,#spikes do
		poolSpike(spikes[i])
		spikes[i] = nil
	end
	music:stop()
	victoryMusic:play()
end

function shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

function defrag(list, length)
	local ret = {}
	for i=1,length do
		if list[i] ~= nil then
			ret[#ret+1] = list[i]
		end
	end
	return ret
end

function string:split(pattern)
  local ret = {}
  local start = 1
  local index = string.find(self, pattern, start)
  while index do
    ret[#ret+1] = string.sub(self, start, index - 1)
    start = index + 1
    index = string.find(self, pattern, start)
  end
  ret[#ret+1] = string.sub(self, start, #self)
  return ret
end
