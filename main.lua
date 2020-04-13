-- CAMERA PARAMETERS
local WIDTH = 960;
local HEIGHT = 720;
local FOV = math.rad(65);

-- STATE
local t = 0;
local angle = 0;
local pos = {0, 0, 15};
local dir = {0, 0, -1};
local mix = 255;
local materialStage = 0;

-- BUFFER & SHADER OBJECTS
local canvas, buffer, shader;

-- KEYBOARD INPUT STATE
local lightRadiusToggle = false;
local clear = false;
local rotating = false;

function love.load()
	love.window.setMode(WIDTH, HEIGHT, {resizable = false});
	canvas = love.graphics.newCanvas(WIDTH, HEIGHT);
	buffer = love.graphics.newCanvas(WIDTH, HEIGHT);
	shader = love.graphics.newShader("shader.glsl");

	shader:send("width", WIDTH);
	shader:send("height", HEIGHT);
	shader:send("fov", FOV);
	shader:send("lightRadiusMultiplier", 1.0);
end

function love.draw()
	love.graphics.draw(canvas, 0, 0);

	love.graphics.print(love.timer.getFPS() .. " FPS", 10, 10);
	love.graphics.print("R : Rotate Camera", 10, 25);
	love.graphics.print("M : Change Material", 10, 40);
	love.graphics.print("S : Toggle Big/Small Lights", 10, 55);
end

function love.keypressed(key)
	if key == 's' then --switch lights
		lightRadiusToggle = not lightRadiusToggle;
		clear = true;
	elseif key == 'r' then --rotate camera
		rotating = true;
	elseif key == 'm' then -- switch between materials: default, reflective, glossy, matte;
		materialStage = (materialStage + 1) % 4;
		clear = true;
	end
end

function love.keyreleased(key)
	if key == 'r' then
		rotating = false;
	end
end

-- MAIN LOGIC
function love.update(dt)
	if rotating then
		angle = angle + dt * 90;
		clear = true;
	end

	-- DETERMINE CAMERA POS + DIR
	t = t + dt;
	pos = {-25*math.sin(math.rad(angle)), 6, 25*math.cos(math.rad(angle))};
	dir = {-pos[1], -pos[2], -pos[3]};

	if clear then
		-- IF CAMERA OR STATE HAS MOVED, CLEAR BUFFERS
		mix = 255
		clear = false
		love.graphics.setCanvas(buffer);
			love.graphics.clear(0, 0, 0);
		love.graphics.setCanvas(canvas);
			love.graphics.clear(0, 0, 0);
	else
		mix = mix * 0.95;
	end

	-- MIX CONTROLS HOW NEW FRAMES AND OLD FRAMES ARE MIXED
	-- ONLY CALCULATE A NEW FRAME IF MIX IS HIGH ENOUGH
	if mix > 1 then
		shader:send("dir", dir);
		shader:send("pos", pos);
		shader:send("time", t);
		shader:send("materialStage", materialStage);
		shader:send("mixRatio", mix / 255);
		shader:send("lightRadiusMultiplier", lightRadiusToggle and 7 or 3);

		love.graphics.setColor(255, 255, 255);
		love.graphics.setCanvas(buffer);
			love.graphics.setShader(shader);
				love.graphics.draw(canvas, 0, 0);
			love.graphics.setShader();
		love.graphics.setCanvas(canvas);
			love.graphics.draw(buffer, 0, 0);
		love.graphics.setCanvas();
	end
end
