maxW, maxH = love.graphics.getDimensions()

function love.load()

	fValues = {}
	
	fValues.AspectRatio = maxH/maxW
	fValues.Near = 0.1
	fValues.Far = 1
	fValues.Fov = 100
	fValues.FovRad = 1 / math.tan(fValues.Fov * 0.5 / 180 * 3.14159)
	
	matProj = mat4x4()
	
	loadFValues()
	
	fTheta = 0.1
	
	fValues.RotSpeed = 0.05
	
	matRotZ = mat4x4()
	matRotX = mat4x4()
	
	meshCube = mesh(0, 0, 8)
	
	camera = vec3d()
	
	drawTris = {}
	
	love.graphics.setLineWidth(1)
	
	line = false
	
	fileData = nil
	
	-- UI
	
	uiDots = love.graphics.newImage("ui.png")
	
	uiShow = false
	
	uiBounds = {200, 170, 600, 430}
	
	uiLabels = {}
	
	newLabel("Near", "Near")
	newLabel("Far", "Far")
	newLabel("Field of View", "Fov")
	newLabel("Rotation Speed", "RotSpeed")
	
	uiEditingLabel = 0
	
	uiNewValue = ""
	
	uiTitle = love.graphics.newFont(25)
	
	uiText = love.graphics.setNewFont(15)
end

function loadFValues()
	fValues.FovRad = 1 / math.tan(fValues.Fov * 0.5 / 180 * 3.14159)
	matProj[1][1] = fValues.AspectRatio * fValues.FovRad
	matProj[2][2] = fValues.FovRad
	matProj[3][3] = fValues.Far / (fValues.Far - fValues.Near)
	matProj[4][3] = (-fValues.Far * fValues.Near) / (fValues.Far - fValues.Near)
	matProj[3][4] = 1
	matProj[4][4] = 0
end

function love.draw()
	for i, v in ipairs(drawTris) do		
		love.graphics.setColor(v.light, v.light, v.light)
		
		love.graphics.polygon("fill",
					 v.p[1].x, v.p[1].y,
					 v.p[2].x, v.p[2].y,
					 v.p[3].x, v.p[3].y)
					 
		if line then
		love.graphics.setColor(0, 0, 0)
		
		drawTriangle(v.p[1].x, v.p[1].y,
					 v.p[2].x, v.p[2].y,
					 v.p[3].x, v.p[3].y)
		end
	end
	love.graphics.setColor(1, 1, 1)
	if #meshCube.tris == 0 then
		love.graphics.printf("Drag & drop a .obj file my dude.", 0, 270, 800, "center")
	end
	love.graphics.draw(uiDots, 760, 5, 0, 0.25)
	if uiShow then
		uiDraw()
	end
end

function uiDraw()
	local x, y, w, h = uiBounds[1], uiBounds[2], uiBounds[3]-uiBounds[1], uiBounds[4]-uiBounds[2]
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x, y, w, h, 5)
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("line", x, y, w, h, 5)
	-- text
	love.graphics.setColor(0, 0, 0)
	love.graphics.setFont(uiTitle)
	love.graphics.printf("SETTINGS", x, y, w, "center")
	love.graphics.setFont(uiText)
	for i, v in ipairs(uiLabels) do
		local x1, y1 = (maxW/2)-(uiText:getWidth(v.label..": "..v.value)/2)+uiText:getWidth(v.label..": ")-2, y+20+(30*i)-2
		local w1, h1 = uiText:getWidth(v.value) + 8, 20
		if v.editing then
			love.graphics.setColor(0.85, 0.85, 0.85)
		else
			love.graphics.setColor(0.95, 0.95, 0.95)
		end
		love.graphics.rectangle("fill", x1, y1, w1, h1, 2)
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf(v.label..": "..v.value, x, y+20+(30*i), w, "center")
		
		if v.editing and v.cursor then
			love.graphics.line(x1+w1-4, y1+3, x1+w1-4, y1+h1-4)
		end
		
		if v.editing then
			love.graphics.setColor(0.4, 0.4, 0.4)
		else
			love.graphics.setColor(0.7, 0.7, 0.7)
		end
		
		love.graphics.rectangle("line", x1, y1, w1, h1, 2)
	end
	love.graphics.setColor(0, 0, 0)
	love.graphics.printf("Press tab to toggle triangle lines.", x, y+h-65, w, "center")
	love.graphics.printf("Drop another .obj file to view it.", x, y+h-45, w, "center")
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.printf("Made by Joelrodiel, 2019.", x, y+h-25, w, "center")
end

function love.update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
	
	fTheta = fTheta + fValues.RotSpeed
	
	matRotZ[1][1] = math.cos(fTheta)
	matRotZ[1][2] = math.sin(fTheta)
	matRotZ[2][1] = -math.sin(fTheta)
	matRotZ[2][2] = math.cos(fTheta)
	matRotZ[3][3] = 1
	matRotZ[4][4] = 1
	
	matRotX[1][1] = 1
	matRotX[2][2] = math.cos(fTheta * 0.5)
	matRotX[2][3] = math.sin(fTheta * 0.5)
	matRotX[3][2] = -math.sin(fTheta * 0.5)
	matRotX[3][3] = math.cos(fTheta * 0.5)
	matRotX[4][4] = 1
	
	drawTris = {}

	for i, v in ipairs(meshCube.tris) do
		local triProjected, triModified = triangle(), triangle(v.bareP)
		
		triModified.rotate(matRotZ)
		triModified.rotate(matRotX)
		triModified.translate(meshCube.coors.x, meshCube.coors.y, meshCube.coors.z)
		
		if dotProductTri(triModified) < 0 then
		
			lightDirection = vec3d(0, 0, -1)
			normalizeVec(lightDirection)
			
			local normal = normalTri(triModified)
			local lightDot = dotProductVec(normal, lightDirection)
			
			triProjected.light = lightDot
		
			-- Translating points from world space (3D) to screen space (2D)
			triProjected.p[1] = multiplyMatrixVector(triModified.p[1], matProj)
			triProjected.p[2] = multiplyMatrixVector(triModified.p[2], matProj)
			triProjected.p[3] = multiplyMatrixVector(triModified.p[3], matProj)
			
			-- Offsetting so center origin (0, 0, 0) is in center of screen
			triProjected.p[1].x, triProjected.p[1].y = triProjected.p[1].x + 1, triProjected.p[1].y + 1
			triProjected.p[2].x, triProjected.p[2].y = triProjected.p[2].x + 1, triProjected.p[2].y + 1
			triProjected.p[3].x, triProjected.p[3].y = triProjected.p[3].x + 1, triProjected.p[3].y + 1
			
			triProjected.p[1].x, triProjected.p[1].y = triProjected.p[1].x * (0.5 * maxW), triProjected.p[1].y * (0.5 * maxH)
			triProjected.p[2].x, triProjected.p[2].y = triProjected.p[2].x * (0.5 * maxW), triProjected.p[2].y * (0.5 * maxH)
			triProjected.p[3].x, triProjected.p[3].y = triProjected.p[3].x * (0.5 * maxW), triProjected.p[3].y * (0.5 * maxH)
			
			table.insert(drawTris, triProjected)
		end
	end
	
	table.sort(drawTris, zSort)
	
	uiUpdate()
end

function uiUpdate()
	local x, y, w, h = uiBounds[1], uiBounds[2], uiBounds[3]-uiBounds[1], uiBounds[4]-uiBounds[2]
	for i, v in ipairs(uiLabels) do
		if uiEditingLabel == 0 then
			v.value = tostring(fValues[v.ref])
		elseif uiEditingLabel == i then
			v.value = uiNewValue
		end
		
		if v.editing then
			if v.cursorTimr > 0 then
				v.cursorTimr = v.cursorTimr - 1
			else
				v.cursorTimr = 20
				v.cursor = not v.cursor
			end
		end
	end
end

function love.filedropped(file)
	file:open("r")
	fileData = file:read()
	meshCube.loadFromFile(fileData)
end

function love.mousepressed(mx, my)
	if not uiShow then
		if mx > 770 and mx < 800
			and my > 0 and my < 60 then
			uiShow = true
		end
	else
		if mx > uiBounds[1] and mx < uiBounds[3]
			and my > uiBounds[2] and my < uiBounds[4] then
			local x, y, w, h = uiBounds[1], uiBounds[2], uiBounds[3]-uiBounds[1], uiBounds[4]-uiBounds[2]
			for i, v in ipairs(uiLabels) do
				local x1, y1 = (maxW/2)-(uiText:getWidth(v.label..": "..v.value)/2)+uiText:getWidth(v.label..": ")-2, y+20+(30*i)-2
				local w1, h1 = uiText:getWidth(v.value) + 5, 20

				if mx > x1 and mx < x1 + w1 and my > y1 and my < y1 + h1 then
					if uiEditingLabel == 0 then
						uiEditingLabel = i
						uiNewValue = tostring(v.value)
						v.editing = true
						v.cursor = true
					end
				else
					if uiEditingLabel == i then
						uiEditingLabel = 0
						uiNewValue = ""
						v.editing = false
					end
				end
			end
		else
			uiShow = false
			if uiEditingLabel > 0 then
				uiLabels[uiEditingLabel].editing = false
			end
			uiEditingLabel = 0
			uiNewValue = ""
		end
	end
end

function love.textinput(t)
	if uiEditingLabel > 0 then
		uiNewValue = uiNewValue .. t
	end
end

function love.keypressed(key)
	if key == "tab" and not uiShow then
		line = not line
	end
	if uiEditingLabel > 0 then
		if key == "backspace" then
			if string.len(uiNewValue) >= 1 then
				uiNewValue = string.sub(uiNewValue, 1, string.len(uiNewValue)-1)
			end
		end
		if key == "return" then
			if uiNewValue == "" then
				uiNewValue = "0"
			end
			if tonumber(uiNewValue) ~= nil then
				fValues[uiLabels[uiEditingLabel].ref] = tonumber(uiNewValue)
			end
			
			if uiLabels[uiEditingLabel].ref ~= "RotSpeed" and fileData ~= nil then
				loadFValues()
				meshCube.loadFromFile(fileData)
			end
			
			uiLabels[uiEditingLabel].editing = false
			uiEditingLabel = 0
			uiNewValue = ""
		end
	end
end

function zSort(a, b)
	local z1 = (a.p[1].z + a.p[2].z + a.p[3].z) / 3
	local z2 = (b.p[1].z + b.p[2].z + b.p[3].z) / 3
	return z1 > z2
end

function vec3d(x, y, z)
	local t = {x or 0, y or 0, z or 0, x=x or 0, y=y or 0, z=z or 0}
	
	function t.updatePoints(x, y, z)
		t[1], t[2], t[3] = x, y, z
		t.x, t.y, t.z = x, y, z
	end
	
	return t
end

function triangle(points)
	local t = {p={}, bareP={}, light=1}
	
	points = points or {}
	
	for i=1, #points, 3 do
		table.insert(t.p, vec3d(points[i], points[i+1], points[i+2]))
		t.bareP[i], t.bareP[i+1], t.bareP[i+2] = points[i], points[i+1], points[i+2]
	end
	
	function t.updateBarePoints()
		for k=1, #t.p do
			t.bareP[1+(3 * (k-1))], t.bareP[2+(3 * (k-1))], t.bareP[3+(3 * (k-1))] = t.p[k].x, t.p[k].y, t.p[k].z
		end
	end
	
	function t.translate(x, y, z)
		for i, v in ipairs(t.p) do
			v.updatePoints(v.x + x, v.y + y, v.z + z)
		end
		t.updateBarePoints()
	end
	
	function t.rotate(mat)
		for i=1, #t.p do
			t.p[i] = multiplyMatrixVector(t.p[i], mat)
		end
		t.updateBarePoints()
	end
	
	return t
end

function mesh(x, y, z)
	local t = {tris={}, coors = {x=x or 0, y=y or 0, z=z or 0}}
	
	function t.loadFromFile(fileData)
		-- local fileData = love.filesystem.read(filePath)
		
		local verts, faces = {}, {}
		t.tris = {}
		
		for s in fileData:gmatch("[^\r\n]+") do
			if string.sub(s, 1, 1) == "v" then
				local numbers = {}
				local input = ""
				for i=1, string.len(s) do
					if string.sub(s, i, i) == " " then
						table.insert(numbers, tonumber(input))
						input = ""
					else
						input = input .. string.sub(s, i, i)
					end
				end
				
				table.insert(numbers, tonumber(input))
				
				if #numbers == 3 then
					table.insert(verts, numbers)
				end
			else
				local a, b, c = string.match(s, "f (%d+) (%d+) (%d+)")
				if a then
					table.insert(faces, {tonumber(a), tonumber(b), tonumber(c)})
				end
			end
		end
		
		for i, v in ipairs(faces) do
			local points = {}
			for k=1, 3 do
				table.insert(points, verts[v[k]][1])
				table.insert(points, verts[v[k]][2])
				table.insert(points, verts[v[k]][3])
			end
			local tri = triangle(points)
			table.insert(t.tris, tri)
		end
	end
	
	return t
end

function mat4x4()
	local t = {}
	
	for i=1, 4 do
		t[i] = {}
		
		for k=1, 4 do
			t[i][k] = 0
		end
	end
	
	return t
end

function multiplyMatrixVector(v, m)
	local out = vec3d()
	
	out.x = v.x * m[1][1] + v.y * m[2][1] + v.z * m[3][1] + m[4][1]
	out.y = v.x * m[1][2] + v.y * m[2][2] + v.z * m[3][2] + m[4][2]
	out.z = v.x * m[1][3] + v.y * m[2][3] + v.z * m[3][3] + m[4][3]
	
	local w = v.x * m[1][4] + v.y * m[2][4] + v.z * m[3][4] + m[4][4]
	
	if w ~= 0 then
		out.x = out.x / w
		out.y = out.y / w
		out.z = out.z / w
	end
	
	return out
end

function normalizeVec(v)
	local normLen = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
	v.updatePoints(v.x / normLen, v.y / normLen, v.z / normLen)
	return v
end

function normalTri(tri)
	local normal, line1, line2 = vec3d(), vec3d(), vec3d()
	line1.updatePoints(tri.p[2].x - tri.p[1].x,
					   tri.p[2].y - tri.p[1].y,
					   tri.p[2].z - tri.p[1].z)
	line2.updatePoints(tri.p[3].x - tri.p[1].x,
					   tri.p[3].y - tri.p[1].y,
					   tri.p[3].z - tri.p[1].z)
	normal.updatePoints(line1.y * line2.z - line1.z * line2.y,
						line1.z * line2.x - line1.x * line2.z,
						line1.x * line2.y - line1.y * line2.x)
	
	normalizeVec(normal)
	
	return normal
end

function dotProductTri(tri)
	local normal = normalTri(tri)
	
	return (normal.x * (tri.p[1].x - camera.x) +
			normal.y * (tri.p[1].y - camera.y) +
			normal.z * (tri.p[1].z - camera.z))
end

function dotProductVec(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

function drawTriangle(x1, y1, x2, y2, x3, y3)
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.line(x2, y2, x3, y3)
	love.graphics.line(x3, y3, x1, y1)
end

function newLabel(label, ref)
	local t = {}
	t.label = label
	t.value = fValues[ref]
	t.ref = ref
	t.editing = false
	t.cursor = false
	t.cursorTimr = 20
	table.insert(uiLabels, t)
end