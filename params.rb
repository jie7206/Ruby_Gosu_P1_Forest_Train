PATH_ROOT = '.' #Pathname.new(File.dirname(__FILE__)).realpath # 为了与Ubuntu相容
TRAIN_INI_SPEED = 2
GAME_CAPTION = "阿杰森林小火车"
MAX_TRAIN_SPEED = 300 # 火车超过此时速则爆炸
EOM_APPEAR_MAX_SEC = 4 # 飞机变换大小的最长间隔秒数
EMO_MAX_SPEED_SEED = 40 # 飞机每次移动的最大距离(像素)
EMO_SPEED_FIX = 0.1 # 飞机速度修正值
EMO_ALPHA = 255 # 飞机贴图的透明度
EMO_VISIBLE_PARAM = 80 # 控制飞机出现的参数
EMO_PAUSE_FRAMES = 50 # 中目标后暂停几个帧
CANNON_ANGLE_DEGREE = 5 # 火炮每按一次增减的角度
CANNON_MAX_ANGLE = 60 # 火炮展开的最大角度
BULLET_PERIOD = 30 # 每一发炮弹的间隔
BULLET_SPEED = 2 # 炮弹的速度
BULLET_RADIUS = 20 # 炮弹感应区大小
GAME_OVER_SECONDS = 60*3 # 游戏结束的秒数
FONT_TTF = "#{PATH_ROOT}/Assets/Fonts/WenDaoKai.ttf"
FONT_SCALE = 1.3