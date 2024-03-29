require 'gosu'
require 'pathname'
require_relative 'bullet'
require_relative 'explosion'
require_relative 'params'

class TrainGame < Gosu::Window

    include Gosu::Button 

    def initialize( width, height, fullscreen )
        super width, height, fullscreen
        set_initinal_params width, height
        load_all_assets
    end

    def update
        case @scene
        when :game
            update_game
        when :end
            update_end
        end
    end

    def update_game
        if @game_mode == "cannon"
          check_x_speed
          check_x_direction
          make_train_vibration
          train_speed_up if press_up
          train_speed_down if press_down
          cannon_angle_right if press_right
          cannon_angle_left if press_left
          fire_cannon(true) if press_fire
          set_cannon_pos
          check_bullets_hit_emo
        elsif @game_mode == "gun"
          shoot_gun(true) if press_shoot
        end
        reset_emo_scale_and_speed if delta_sec > @emo_appear_sec
        move_emo
        set_emo_visible
        emo_pause_or_play
        move_bullets
        clear_explosions
        if_over_time_then_game_over
    end

    def update_end

    end

    def check_bullets_hit_emo
        @bullets.each do |bullet|
            if Gosu.distance(@emo_x, @emo_y, bullet.x, bullet.y) < @emo_width*@emo_scale*0.5 + bullet.radius*2 and @emo_visible >= 0 and @emo_pause < 0
                exe_hit_emo
                @bullets.delete bullet
                add_explosion
            end
        end
        clear_bullets
    end

    def clear_bullets
        @bullets.dup.each do |bullet|
            @bullets.delete bullet if !bullet.onscreen?
        end
    end

    def clear_explosions
        @explosions.dup.each do |explosion|
            @explosions.delete explosion if explosion.finished
        end
    end

    def move_bullets
        @bullets.each do |bullet|
            bullet.move
        end
        @bullet_period -= 1
    end

    def draw_bullets
        @bullets.each do |bullet|
            bullet.draw
        end
    end

    def draw_explosions
        @explosions.each do |explosion|
            explosion.draw
        end
    end

    def set_cannon_pos
        if @scale_x > 0
            @cannon_x_fix = 27
            @cannon_y_fix = 17
        else
            @cannon_x_fix = -27
            @cannon_y_fix = 17
        end

    end

    def emo_pause_or_play
        @emo_pause -= 1
        set_emo_position if @emo_pause == 1
    end

    def delta_sec
        (Gosu::milliseconds - @start_time)/1000
    end

    def draw
        case @scene
        when :start
            draw_start
        when :game
            draw_game
        when :end
            draw_end
        end
    end

    def draw_start
        @background.draw(0, 0, 0)
        @speed_title.draw("#{GAME_CAPTION}游戏说明", @screen_width/2-@screen_width/4+55, 50, 3, 1.3, 1.3, 0xff_000000)
        @speed_title.draw("按回车或鼠标左键开始，空白键或鼠标左键发射，上下键加减速，左右键调角度", 70, 130, 3, 0.92, 0.92, 0xff_000000)
        @speed_title.draw("一旦火车时速到达#{@hour_speed_max}公里以上或超过#{GAME_OVER_SECONDS}秒，游戏将自动结束", 75, 190, 3, 1.2, 1.2, 0xff_000000)
    end

    def draw_game
        @background.draw(0, 0, 0)
        if @game_mode == "gun"
          @gun.draw(mouse_x-@gun_width*@gun_scale/2, mouse_y-@gun_height*@gun_scale/2, 3, @gun_scale, @gun_scale)
        end
        if @game_mode == "cannon"
          @train.draw(@x,@y,2,@scale_x,@scale)
          @cannon.draw_rot(@x+@cannon_x_fix,@y+@cannon_y_fix,1,@cannon_angle,0.5,0.54,@scale_x,@scale)
        end
        @emo.draw(@emo_x-@emo_width*@emo_scale/2,@emo_y-@emo_height*@emo_scale/2,2,@emo_scale_x,@emo_scale,Gosu::Color.argb(EMO_ALPHA, 255, 255, 255)) if @emo_visible > 0 and @emo_pause < 1
        @fire.draw(@x+88,@y-39,2,0.15,0.2) if press_up and @x_direction == 1
        @fire.draw(@x-105,@y-39,2,0.15,0.2) if press_up and @x_direction == -1
        @stop.draw(@x+40,@y+20,2,0.17,0.12) if press_down and @x_direction == 1
        @stop.draw(@x-90,@y+20,2,0.17,0.12) if press_down and @x_direction == -1
        @speed_title.draw(@speed_descr, @screen_width/2 - 330, 40, 3, 1.0, 1.0, 0xff_000000)
        @speed_title.draw("剩下：#{GAME_OVER_SECONDS-((Gosu::milliseconds - @pass_time)/1000).to_i}秒，发出：#{@gun_fire_count} 发 打中：#{@hit_emo_count} 发 命中率：#{get_fire_rate} %", @screen_width/2 - 140, 40, 3, 1.0, 1.0, 0xff_000000)
        draw_bullets
        draw_explosions
    end

    def draw_end
        @background.draw(0, 0, 0)
        @speed_title.draw("#{@speed_descr}，发出：#{@gun_fire_count} 发 打中：#{@hit_emo_count} 发 命中率：#{get_fire_rate} %", @screen_width/2 - 300, 40, 3, 1.0, 1.0, 0xff_000000)
        @game_over.draw("游戏结束", @screen_width/2 - 130, 150, 3, 1.2, 1.2, 0xff_990000)
        @game_over.draw("按ESC离开，按回车重新开始", @screen_width/2 - 200, 260, 3, 0.6, 0.6, 0xff_990000)
    end

    def draw_fire_explore
        if @emo_visible >= 0
            if @emo_x_speed > 0
                @stop.draw(@emo_x-@emo_width*@emo_scale/2,@emo_y-@emo_height*@emo_scale/2,2,@emo_scale*0.7,@emo_scale*0.7)
            else
                @stop.draw(@emo_x-@emo_width*@emo_scale*1.5,@emo_y-@emo_height*@emo_scale/2,2,@emo_scale*0.7,@emo_scale*0.7)
            end
        end
    end

    def button_down( keyid )
        case @scene
        when :start
            button_down_start( keyid )
        when :game
            button_down_game( keyid )
        when :end
            button_down_end( keyid )
        end
    end

    def button_down_start( keyid )
      # 手柄对应
      # GpButton0 = A 按钮：通常用于确认或执行操作
      # GpButton1 = B 按钮：通常用于取消或返回
      # GpButton2 = X 按钮：在游戏中具有多种用途
      # GpButton3 = Y 按钮：在游戏中具有多种用途
      # GpButton4 = Back 或 View 按钮：用于显示额外信息或选项
      # GpButton5 = 无对应
      # GpButton6 = Start 或 Menu 按钮：用于暂停游戏或打开菜单
      # GpButton7 = 左摇杆按下（LS）：用于控制角色移动
      # GpButton8 = 右摇杆按下（RS）：用于控制角色移动 
      # GpButton9 = LB 
      # GpButton10 = RB
      # GpButton11 = LT 
      # GpButton12 = RT 
      # GpButton13 = 无对应
      # GpButton14 = 无对应
      # GpButton15 = 无对应 

      case keyid
      when Gosu::KB_RETURN,GpButton6
          initialize_game
      when MsLeft
          @game_mode = "gun"
          initialize_game
      when KbEscape,GpButton4
          close
      end
    end

    def button_down_game( keyid )
        case keyid
        when KbEscape,GpButton4
            close
        when MsLeft
            shoot_gun if @game_mode == "gun"
        when KbSpace,GpButton2
            fire_cannon
        when KbR
            restart_game
        end
    end

    def button_down_end( keyid )
        case keyid
        when KbEscape,GpButton4
            close
        when Gosu::KB_RETURN,GpButton6
            start_game
        end
    end

    def get_bullet_x
        @x_direction > 0 ? @x+@cannon_x_fix-7 : @x+@cannon_x_fix+5
    end

    def get_bullet_y
        @y+@cannon_y_fix-10
    end

    def get_bullet_angle
        @x_direction > 0 ? @cannon_angle+90 : @cannon_angle-90
    end

    def mechanism_period( mechanism = false, division = 2 )
      @bullet_period < 0 or ( mechanism and @bullet_period < BULLET_PERIOD/division)
    end

    def fire_cannon( mechanism = false )
      if @game_mode == "cannon" and mechanism_period(mechanism)
        @bullets.push Bullet.new(self, get_bullet_x, get_bullet_y, get_bullet_angle)
        @bullet_sound.play 1.0
        @gun_fire_count += 1
        @bullet_period = BULLET_PERIOD
      end      
    end

    def shoot_gun( mechanism = false )
        if @game_mode == "gun" and mechanism_period(mechanism)
          @gun_fire.play 0.5
          @gun_fire_count += 1
          @bullet_period = BULLET_PERIOD
          if Gosu.distance(mouse_x, mouse_y, @emo_x, @emo_y) < @emo_width*@emo_scale and @emo_visible >= 0 and @emo_pause < 0
              exe_hit_emo
          else
              exe_nohit_emo
          end
        end
    end

    def exe_hit_emo
        @hit_emo = 1
        @hit_emo_count += 1
        @emo_pause = EMO_PAUSE_FRAMES
        add_explosion
        destroy_emo
    end

    def add_explosion
        @explosions.push Explosion.new(self, @emo_x, @emo_y, @emo_scale*5)
    end

    def destroy_emo

    end

    def exe_nohit_emo
        @hit_emo = -1
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
        @pass_time = Gosu::milliseconds
        @scene = :start
        set_font_params
        set_timestamp
        set_train_params
        set_emo_params
        set_cannon_params
        set_bullet_params
        set_explosion_params
        set_gun_params
        set_game_mode
    end

    def initialize_game
        start_game
    end

    def set_game_mode
      @game_mode = "cannon"
    end

    def set_emo_params
        @emo_width = 250
        @emo_height = 205
        @emo_scale_x = @emo_scale = 0.2
        @emo_visible = 0
        set_emo_velocity
        set_emo_appear_sec
    end

    def set_gun_params
        @gun_width = 250
        @gun_height = 177 #261
        @gun_scale = 0.2
        @hit_emo = 0
        @gun_fire_count = 0
        @hit_emo_count = 0
        @emo_pause = 0
    end

    def set_cannon_params
        @cannon_angle = 0
    end

    def set_bullet_params
        @bullets = []
        @bullet_period = 0
    end

    def set_explosion_params
        @explosions = []
    end

    def set_emo_visible
        @emo_visible -= 1
        @emo_visible = EMO_VISIBLE_PARAM if @emo_visible < -10 and rand < 0.03
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
        @hour_speed_max = MAX_TRAIN_SPEED # 火车超过此时速则爆炸
        @x = 1 # 火车的初始位置
        @in_p = 1 # 火车全部进去的比率
    end
  
    def set_font_params
        @speed_title = Gosu::Font.new((20*FONT_SCALE).to_i, name: FONT_TTF)
        @game_over = Gosu::Font.new((50*FONT_SCALE).to_i, name: FONT_TTF)
    end

    def load_all_assets
        @background = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/background.jpg")
        @train = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/train.png")
        @fire = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/fire.png")
        @stop = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/stop.png")
        @emo = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/emo.png")
        @gun = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/gun.png")
        @cannon = Gosu::Image.new( "#{PATH_ROOT}/Assets/Images/cannon.png")
        @bgsong = Gosu::Song.new("#{PATH_ROOT}/Assets/Sounds/background.mp3")
        @go = Gosu::Sample.new("#{PATH_ROOT}/Assets/Sounds/go.wav")
        @brake = Gosu::Sample.new("#{PATH_ROOT}/Assets/Sounds/brake.wav")
        @crash = Gosu::Sample.new("#{PATH_ROOT}/Assets/Sounds/crash.wav")
        @gun_fire = Gosu::Sample.new("#{PATH_ROOT}/Assets/Sounds/gun_fire.wav")
        @bullet_sound = Gosu::Sample.new("#{PATH_ROOT}/Assets/Sounds/bullet.wav")
    end

    def start_game
        @bgsong.play true
        @x_speed = @ini_x_speed
        restart_game
    end

    def restart_game
        @scene = :game
        reset_pass_time
        set_emo_params
        set_emo_position
        set_gun_params
    end

    def reset_pass_time
        @pass_time = Gosu::milliseconds
    end

    def press_fire
        Gosu::button_down? KbF or Gosu::button_down? GpButton1
    end

    def press_shoot
        Gosu::button_down? MsRight
    end

    def press_up
        Gosu::button_down? KbUp or Gosu::button_down? GpButton3 or Gosu::button_down? GpButton11
    end

    def press_down
        Gosu::button_down? KbDown or Gosu::button_down? GpButton0 or Gosu::button_down? GpButton12
    end

    def press_left
        Gosu::button_down? KbLeft or Gosu::button_down? GpLeft or Gosu::button_down? GpUp
    end

    def press_right
        Gosu::button_down? KbRight or Gosu::button_down? GpRight or Gosu::button_down? GpDown
    end

    def make_train_vibration
        @y =  435 #Math.sin(@x*@x_speed*factor(@x_speed)) + 435
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
        @cannon_angle *= -1
    end

    def train_go_left
        @x_direction = -1
        @scale_x = @scale * -1
        @cannon_angle *= -1
    end

    def cannon_angle_right
        if @scale_x > 0
            @cannon_angle += CANNON_ANGLE_DEGREE
            @cannon_angle = 0 if @cannon_angle > 0
        end
        if @scale_x < 0
            @cannon_angle += CANNON_ANGLE_DEGREE
            @cannon_angle = CANNON_MAX_ANGLE if @cannon_angle > CANNON_MAX_ANGLE
        end
    end


    def cannon_angle_left
        if @scale_x > 0
            @cannon_angle -= CANNON_ANGLE_DEGREE
            @cannon_angle = CANNON_MAX_ANGLE*-1 if @cannon_angle < CANNON_MAX_ANGLE*-1
        end
        if @scale_x < 0
            @cannon_angle -= CANNON_ANGLE_DEGREE
            @cannon_angle = 0 if @cannon_angle < 0
        end
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
        @speed_descr = "时速(公里/小时)：#{@hour_speed.to_i}"
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

    def if_over_time_then_game_over
        if (Gosu::milliseconds - @pass_time)/1000 >= GAME_OVER_SECONDS
            exe_game_over
        end
    end

    def if_over_max_speed_then_crash
        if @hour_speed > @hour_speed_max
            exe_game_over
        end
    end

    def exe_game_over
        @x_speed = 0
        @bgsong.stop
        @crash.play 2
        @scene = :end
    end

    def check_x_direction
            if @x >= @screen_width # - @train.width * @scale # *  @in_p
                    #train_go_left if @x_speed > 0
                    @x = @train.width*@scale*-1
            elsif @x_direction == -1 and @x < @train.width * @scale #  *  @in_p * -1
                    train_go_right if @x_speed > 0
            end
    end

    def set_emo_position
        rand_emo_xy_pos
        set_emo_appear_sec
    end

    def reset_emo_scale_and_speed
        if @emo_pause <= 0
            @emo_scale_x = @emo_scale = (rand(30)+10)/100.0
            set_emo_velocity
            set_emo_position
            set_timestamp
        end
    end

    def set_emo_velocity
        @emo_speed_seed = rand(40)+10
        @emo_x_speed = @emo_speed_seed*EMO_SPEED_FIX
        @emo_y_speed = @emo_speed_seed*EMO_SPEED_FIX
    end

    def move_emo
        if @emo_pause <= 0
            @emo_x += @emo_x_speed
            @emo_y += @emo_y_speed
            check_emo_move_boundry
        end
    end

    def check_emo_move_boundry
        if emo_lefttop_x < emo_width_diff or emo_lefttop_x > @screen_width-emo_width_diff
            @emo_x_speed *= -1
            @emo_scale_x *= -1
            @emo_x += 30 if @emo_x_speed > 0
            @emo_x -= 30 if @emo_x_speed < 0
        end
        if emo_lefttop_y < 0 or emo_lefttop_y > @screen_height*0.55
            @emo_y_speed *= -1
            @emo_y += 30 if @emo_y_speed > 0
            @emo_y -= 30 if @emo_y_speed < 0

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
