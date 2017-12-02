require 'gosu'

class TrainGame < Gosu::Window

    TRAIN_INI_SPEED = 2
    GAME_CAPTION = "麦可的森林小火车"
    EOM_APPEAR_MAX_SEC = 3 # 恶魔变换大小的最长间隔秒数
    EMO_MAX_SPEED_SEED = 30 # 恶魔每次移动的最大距离(像素)
    EMO_SPEED_FIX = 0.1 # 恶魔速度修正值
    EMO_VISIBLE_PARAM = 40 # 控制恶魔出现的参数
    GUN_HIT_DISTANCE = 50 # 枪打中目标的距离

    def initialize( width, height, fullscreen )
        super width, height, fullscreen
        set_initinal_params width, height
        load_all_assets
        start_game
    end

    def update
        if not @already_crash
            check_x_speed
            check_x_direction
            make_train_vibration
            train_speed_up if press_up
            train_speed_down if press_down
            train_go_right if press_right
            train_go_left if press_left
            reset_emo_scale_and_speed if delta_sec > @emo_appear_sec
            move_emo
            set_emo_visible
        end
        start_game if @already_crash and press_start
    end

    def delta_sec
        (Gosu::milliseconds - @start_time)/1000
    end

    def draw
        @background.draw(0, 0, 0)
        @gun.draw(mouse_x-@gun_width*@gun_scale/2, mouse_y-@gun_height*@gun_scale/2, 3, @gun_scale, @gun_scale)
        if not @already_crash
            @train.draw(@x,@y,1,@scale_x,@scale)
            @emo.draw(@emo_x-@emo_width*@emo_scale/2,@emo_y-@emo_height*@emo_scale/2,2,@emo_scale_x,@emo_scale) if @emo_visible > 0
            @fire.draw(@x+88,@y-39,2,0.15,0.2) if press_up and @x_direction == 1
            @fire.draw(@x-105,@y-39,2,0.15,0.2) if press_up and @x_direction == -1
            @stop.draw(@x+40,@y+20,2,0.17,0.12) if press_down and @x_direction == 1
            @stop.draw(@x-90,@y+20,2,0.17,0.12) if press_down and @x_direction == -1
            @speed_title.draw("时速：#{@hour_speed} 公里/小时 经过：#{Gosu::milliseconds/1000}秒，发出：#{@gun_fire_count} 发 打中：#{@hit_emo_count} 支 命中率：#{get_fire_rate} %", @screen_width/2 - 300, 40, 3, 1.0, 1.0, 0xff_000000)
        end
        if @already_crash
            @game_over.draw("GAME OVER", @screen_width/2 - 200, 180, 3, 1.0, 1.0, 0xff_990000)
        end
        show_hit_result    
    end

    def show_hit_result
        if @hit_emo == 0
            c = Gosu::Color::NONE
        elsif @hit_emo == 1
            c = Gosu::Color::GREEN
        elsif @hit_emo == -1
            c = Gosu::Color::RED
        end
        draw_quad(0,0,c,1366,0,c,1366,768,c,0,768,c)
        @hit_emo = 0                
    end

    def button_down( button )
        case button
            when Gosu::KbEscape,Gosu::GP_BUTTON_7
                close
            when Gosu::MS_LEFT
                check_if_hit_emo
        end
    end

    def fire_gun
        @gun_fire.play 0.8
        @gun_fire_count += 1
    end

    def check_if_hit_emo
        fire_gun
        if Gosu.distance(mouse_x, mouse_y, @emo_x, @emo_y) < @emo_width*@emo_scale and @emo_visible >= 0
            @hit_emo = 1
            @hit_emo_count += 1
            set_emo_position
        else
            @hit_emo = -1
        end
    end

    def get_fire_rate 
        if @gun_fire_count > 0
            gun_fire_count = @gun_fire_count # fix editor color bug
            ((@hit_emo_count/gun_fire_count.to_f)*100).to_i
        else
            0
        end
    end

    def set_initinal_params( width, height )
        self.caption = GAME_CAPTION
        @screen_width = width
        @screen_height = width
        set_timestamp
        set_train_params
        set_font_params
        set_initinal_emo_params
        set_initinal_gun_params
    end

    def set_initinal_emo_params
        @emo_width = 250
        @emo_height = 205
        @emo_scale_x = @emo_scale = 0.2
        @emo_visible = 0
        set_emo_rand_speed_seed
        set_emo_velocity
        set_emo_appear_sec
    end

    def set_initinal_gun_params
        @gun_width = 250
        @gun_height = 261
        @gun_scale = 0.2
        @hit_emo = 0
        @gun_fire_count = 0
        @hit_emo_count = 0

    end

    def set_emo_visible
        @emo_visible -= 1
        @emo_visible = EMO_VISIBLE_PARAM if @emo_visible < -10 and rand < 0.01
    end

    def rand_emo_xy_pos
        @emo_x = rand(800)
        @emo_y = rand(300)+30
    end

    def set_emo_appear_sec
        @emo_appear_sec = rand(EOM_APPEAR_MAX_SEC)+1
    end

    def set_timestamp
        @start_time = Gosu::milliseconds
    end

    def set_train_params
        @ini_x_speed = TRAIN_INI_SPEED # 火车的初始速度
        @x_direction = 1 # 火车的初始方向
        @x_friction = 0.001 # 火车的摩擦力
        @acc_increase = 0.02 # 火车每次踩油门或刹车速度的变化值
        @scale  = @scale_x = 0.25 # 火车的图像大小
        @hour_speed_max =200 # 火车超过此时速则爆炸
        @x = 1 # 火车的初始位置
        @in_p = 1 # 火车全部进去的比率
    end

    def set_font_params
        @speed_title = Gosu::Font.new(20)
        @game_over = Gosu::Font.new(80)
    end                  

    def load_all_assets
        @background = Gosu::Image.new( "./Assets/Images/background.jpg")
        @train = Gosu::Image.new( "./Assets/Images/train.png")
        @fire = Gosu::Image.new( "./Assets/Images/fire.png")
        @stop = Gosu::Image.new( "./Assets/Images/stop.png")
        @emo = Gosu::Image.new( "./Assets/Images/emo.png")
        @gun = Gosu::Image.new( "./Assets/Images/aim.png")
        @bgsong = Gosu::Song.new("./Assets/Sounds/background.mp3")
        @go = Gosu::Sample.new("./Assets/Sounds/go.wav")
        @brake = Gosu::Sample.new("./Assets/Sounds/brake.wav")
        @crash = Gosu::Sample.new("./Assets/Sounds/explosion.wav")
        @gun_fire = Gosu::Sample.new("./Assets/Sounds/gun_fire.wav")
    end

    def start_game
        @already_crash = false
        @bgsong.play true
        @x_speed = @ini_x_speed
        set_emo_position
    end

    def press_up
        Gosu::button_down? Gosu::KbUp or Gosu::button_down? Gosu::GP_UP or Gosu::button_down? Gosu::GP_BUTTON_0
    end

    def press_down
        Gosu::button_down? Gosu::KbDown or Gosu::button_down? Gosu::GP_DOWN or Gosu::button_down? Gosu::GP_BUTTON_2
    end

    def press_left
        Gosu::button_down? Gosu::KbLeft or Gosu::button_down? Gosu::GP_LEFT
    end

    def press_right
        Gosu::button_down? Gosu::KbRight or Gosu::button_down? Gosu::GP_RIGHT
    end

    def press_start
        Gosu::button_down? Gosu::KbSpace or Gosu::button_down? Gosu::GP_BUTTON_9
    end

    def make_train_vibration
        @y = Math.sin(@x*@x_speed*factor(@x_speed)) + 435
    end

    def train_speed_up
        @x_speed += @acc_increase
        @go.play 0.02
    end        

    def train_speed_down
        @x_speed -= @acc_increase
        @brake.play 0.05
    end        

    def train_go_right
        @x_direction = 1
        @scale_x = @scale * 1
    end

    def train_go_left
        @x_direction = -1 
        @scale_x = @scale * -1
    end

    # Calculate vibration factor
    def factor(x)
        case x
            when 0.0...1.0
                5
            when 1.0...2.0
                20
            when 2.0...3.0
                30
            when 3.0...4.0
                40
            else
                50
        end
    end

    def check_x_speed
        x_speed_to_hour_speed
        update_x_speed_value
        if_over_max_speed_then_crash
    end

    def x_speed_to_hour_speed
        @x += @x_speed * @x_direction
        @hour_speed = (@x_speed*20).to_i
    end

    def update_x_speed_value
        if @x_speed < 0
            @x_speed = 0
            @brake.play 0.8, 0.5
            @bgsong.pause
        elsif @hour_speed > 10 and @bgsong.paused?
            @bgsong.play
        elsif @x_speed > 0
            @x_speed -= @x_friction
        end            
    end

    def if_over_max_speed_then_crash
        if @hour_speed > @hour_speed_max
            @x_speed = 0
            @bgsong.stop
            @crash.play 2
            @already_crash = true
        end
    end        

    def check_x_direction
            if @x >= @screen_width - @train.width * @scale # *  @in_p
                    train_go_left if @x_speed > 0
            elsif @x_direction == -1 and @x < @train.width * @scale #  *  @in_p * -1
                    train_go_right if @x_speed > 0
            end
    end

    def set_emo_position
        rand_emo_xy_pos
    end

    def reset_emo_scale_and_speed
        @emo_scale_x = @emo_scale = (rand(17)+7)/100.0
        @emo_scale_x *= -1 if @emo_x_speed < 0
        set_emo_rand_speed_seed
        set_emo_appear_sec
        set_timestamp
    end

    def set_emo_rand_speed_seed
        @emo_speed_seed = rand(EMO_MAX_SPEED_SEED)+5
    end

    def set_emo_velocity
        @emo_x_speed = @emo_speed_seed*EMO_SPEED_FIX
        @emo_y_speed = @emo_speed_seed*EMO_SPEED_FIX
    end

    def move_emo
        @emo_x += @emo_x_speed
        @emo_y += @emo_y_speed
        check_emo_move_boundry
    end

    def check_emo_move_boundry
        if emo_lefttop_x < emo_width_diff or emo_lefttop_x > @screen_width-emo_width_diff
            @emo_x_speed *= -1
            @emo_scale_x *= -1
        end
        if emo_lefttop_y < 0 or emo_lefttop_y > @screen_height*0.55
            @emo_y_speed *= -1
        end
    end

    def emo_lefttop_x
        @emo_x-emo_width_diff
    end

    def emo_width_diff
        @emo_width*@emo_scale/2
    end
    def emo_lefttop_y
        @emo_y-emo_height_diff
    end

    def emo_height_diff
        @emo_height*@emo_scale/2
    end

    # 随机回传+1或-1
    def set_emo_move_direction
        @p_or_n_x = rand(2) + 1 > 1 ? 1 : -1
        @p_or_n_y = rand(2) + 1 > 1 ? 1 : -1
    end

end

TrainGame.new(800,470,{:fullscreen=>true,:update_interval=>20.0}).show