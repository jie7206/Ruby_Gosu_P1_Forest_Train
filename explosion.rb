class Explosion

    PATH_ROOT = '.'
    attr_reader :finished

    def initialize(window, x, y, scale = 1)
        @x = x
        @y = y
        @scale = scale
        @radius = 30
        @images = Gosu::Image.load_tiles("#{PATH_ROOT}/Assets/Images/explosions.png", 60, 60)
        @image_index = 0
        @finished = false
    end

    def draw
        if @image_index < @images.count
            @images[@image_index].draw(@x - @radius*@scale, @y - @radius*@scale, 3, @scale, @scale)
            @image_index += 1
        else
            @finished = true
        end
    end

end