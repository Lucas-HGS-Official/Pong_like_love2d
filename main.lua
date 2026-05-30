local push = require "push"
Class = require "class"

require "Paddle"
require "Ball"

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 854
VIRTUAL_HEIGHT = 480

PADDLE_SPEED = 250

local function display_FPS()
    love.graphics.setFont(small_font)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

local function display_score()
    -- draw score on the left and right center of the screen
    -- need to switch font to draw before actually printing
    love.graphics.setFont(score_font)
    love.graphics.print(tostring(player_1_score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player_2_score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "enter" or key == "return" then
        if game_state == "start" then
            game_state = "serve"
        elseif game_state == "serve" then
            game_state = "play"
        elseif game_state == "done" then
            game_state = "serve"
            ball:reset()
            player_1_score = 0
            player_2_score = 0
            if winning_player == 1 then
                serving_player = 2
            else
                serving_player = 1
            end
        end
    end
end

function love.load()
    math.randomseed(os.time())

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Pong-like")

    score_font = love.graphics.newFont("font.ttf", 64)
    large_font = love.graphics.newFont("font.ttf", 32)
    small_font = love.graphics.newFont("font.ttf", 16)
    love.graphics.setFont(small_font)

    sounds = {
        ["paddle_hit"] = love.audio.newSource("sounds/paddle_hit.wav", "static"),
        ["score"] = love.audio.newSource("sounds/score.wav", "static"),
        ["wall_hit"] = love.audio.newSource("sounds/wall_hit.wav", "static")
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = -1,
        fullscreen = false,
        resizable = true
    })

    player_1_score = 0
    player_2_score = 0

    player_1 = Paddle(10, 50, 10, 40)
    player_2 = Paddle(VIRTUAL_WIDTH - 20, VIRTUAL_HEIGHT - 50, 10, 40)

    ball = Ball(VIRTUAL_WIDTH / 2 - 4, VIRTUAL_HEIGHT / 2 - 4, 8, 8)

    serving_player = 1

    game_state = "start"
end

function love.update(dt)
    if game_state == "serve" then
        ball.dy = math.random(-50, 50)
        if serving_player == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif game_state == "play" then
        if ball:collides(player_1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player_1.x + 10

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds["paddle_hit"]:play()
        end
        if ball:collides(player_2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player_2.x - 8

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds["paddle_hit"]:play()
        end

        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds["wall_hit"]:play()
        end
        if ball.y >= VIRTUAL_HEIGHT - 8 then
            ball.y = VIRTUAL_HEIGHT - 8
            ball.dy = -ball.dy
            sounds["wall_hit"]:play()
        end

        if ball.x < -8 then
            serving_player = 1
            player_2_score = player_2_score + 1
            sounds["score"]:play()
            if player_2_score == 2 then
                winning_player = 2
                game_state = "done"
            else
                game_state = "serve"
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            serving_player = 2
            player_1_score = player_1_score + 1
            sounds["score"]:play()
            if player_1_score == 2 then
                winning_player = 1
                game_state = "done"
            else
                game_state = "serve"
                ball:reset()
            end
        end
    end

    -- Player 1 controls
    if love.keyboard.isDown("w") then
        player_1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown("s") then
        player_1.dy = PADDLE_SPEED
    else
        player_1.dy = 0
    end

    -- Player 2 controls
    if love.keyboard.isDown("up") then
        player_2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown("down") then
        player_2.dy = PADDLE_SPEED
    else
        player_2.dy = 0
    end

    if game_state == "play" then
        ball:update(dt)
    end

    player_1:update(dt)
    player_2:update(dt)
end

function love.draw()
    push:start()

    love.graphics.clear(40 / 255, 60 / 255, 60 / 255, 1)

    if game_state == "start" then
        love.graphics.setFont(small_font)
        love.graphics.printf("Welcome to Pong!", 0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press Enter to begin!", 0, 20, VIRTUAL_WIDTH, "center")
    elseif game_state == "serve" then
        love.graphics.setFont(small_font)
        love.graphics.printf("Player " .. tostring(serving_player) .. "'s serve!",
            0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press Enter to serve!", 0, 20, VIRTUAL_WIDTH, "center")
    elseif game_state == "play" then

    elseif game_state == "done" then
        love.graphics.setFont(large_font)
        love.graphics.printf("Player " .. tostring(winning_player) .. " wins!", 0, 10, VIRTUAL_WIDTH, "center")
    end

    display_score()

    player_1:render()
    player_2:render()

    ball:render()
    display_FPS()

    push:finish()
end
