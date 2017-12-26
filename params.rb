PATH_ROOT = Pathname.new(File.dirname(__FILE__)).realpath
TRAIN_INI_SPEED = 2
GAME_CAPTION = "麦可的森林小火车"
EOM_APPEAR_MAX_SEC = 4 # 恶魔变换大小的最长间隔秒数
EMO_MAX_SPEED_SEED = 40 # 恶魔每次移动的最大距离(像素)
EMO_SPEED_FIX = 0.1 # 恶魔速度修正值
EMO_VISIBLE_PARAM = 80 # 控制恶魔出现的参数
EMO_PAUSE_FRAMES = 50 # 中目标后暂停几个帧
CANNON_ANGLE_DEGREE = 5 # 火炮每按一次增减的角度
CANNON_MAX_ANGLE = 60 # 火炮展开的最大角度
BULLET_PERIOD = 50 # 每一发炮弹的间隔
BULLET_SPEED = 2
BULLET_RADIUS = 10