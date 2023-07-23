// title:   Katari Space '78
// author:  lurkyphish2085
// desc:    testing collisions and ships
// license: MIT License (change this to your license of choice)
// version: 0.1
// script:  wren
// input: gamepad

var WIDTH=240
var HEIGHT=136
 
var BTN_UP=0
var BTN_DOWN=1
var BTN_LEFT=2
var BTN_RIGHT=3
var BTN_A=4
var BTN_B=5
var BTN_X=6
var BTN_Y=7
var KEY_SPC=48

class Entity {

  construct new(x, y, w, h, speed) {
    _x = x
    _y = y
    _w = w
    _h = h
    _speed = speed

    _hitbox = Hitbox.new(this)
  }
  
  x {_x}
  y {_y}
  w {_w}
  h {_h}
  speed {_speed}
  hitbox {_hitbox}

  x=(value) {_x = value}
  y=(value) {_y = value}
  w=(value) {_w = value}
  h=(value) {_h = value}
  speed=(value) {_speed = value}

  update() {
    _hitbox.update()
  }

  draw() {
    _hitbox.draw()
  }
}

class Hitbox {
  
  construct new(entity) {
    if (!(entity is Entity)) {
      Fiber.abort("Hitbox init error: supplied argument to constructor is not an instance of the class Entity")
    }
    
    _debugMode = false

    _entity = entity
    _x = entity.x
    _y = entity.y
    _w = entity.w
    _h = entity.h
    
    _defaultColor = 0
    _onCollisionColor = 4
    _color = 0
  }
  construct new(entity, debugMode) {
    if (!(entity is Entity)) {
      Fiber.abort("Hitbox init error: supplied argument to constructor is not an instance of the class Entity")
    }
    
    _debugMode = debugMode

    _entity = entity
    _x = entity.x
    _y = entity.y
    _w = entity.w
    _h = entity.h
    
    _defaultColor = 2
    _onCollisionColor = 5
    _color = _defaultColor
  }

  debugMode {_debugMode}
  debugMode=(value) {_debugMode = value}
  
  flash() {
    _color = _onCollisionColor
  }

  static checkCollision(a, b) {
    if (!(a is Entity && b is Entity)) {
      Fiber.abort("Hitbox method error: supplied arguments to method is not an instance of the class Entity")
    }
    
    var xd = ((a.x + (a.w/2)) - (b.x + (b.w/2))).abs
    var xs = a.w*0.5 + b.w*0.5
    var yd = ((a.y + (a.h/2)) - (b.y + (b.h/2))).abs
    var ys = a.h/2 + b.h / 2
    
    return (xd < xs && yd < ys)
  }
  
  update() {
    _x = _entity.x
    _y = _entity.y
    _w = _entity.w
    _h = _entity.h
  }

  draw() {
    if (!_debugMode) {
      return
    }

    TIC.rectb(_x, _y, _w, _h, _color) 
  }
}

class Explosion is Entity {

  construct new(x, y) {
    super(x, y, 8, 8, 0)
    _sprite = 376
  }

  draw() {
    TIC.spr(_sprite, x - w/2, y - 6, 0)
  }
}

class Bullet is Entity {

  construct new(holder, w, h, speed) {
    super(holder.x, holder.y, w, h, speed)

    _holder = holder
    _isLaunched = false
    _isDestroyed = false

    _launchPosX = holder.x
    _launchPosY = holder.y
    _maxY = 6
  }

  isLaunched {_isLaunched}

  launch() {
    _isLaunched = true
    x = _launchPosX
  }

  wentOutOfBounds() {
    return y <= _maxY
  }

  destroy() {
    _isDestroyed = true
  }

  update() {
    _launchPosX = _holder.x + (_holder.w / 2) - 1

    if (wentOutOfBounds() || _isDestroyed) {
      Explosion.new(x, y).draw()
      _isLaunched = false
      _isDestroyed = false
      x = _launchPosX
      y = _launchPosY
    }

    if (!_isLaunched) {
      return
    }

    y = y + -speed
  }

  draw() {
    if (!_isLaunched) {
      return
    }

    TIC.spr(375, x, y, 0)
  }
}

class Player is Entity {
  
  construct new(x, y, w, h, speed) {
    super(x, y, w, h, speed)
    _score = 0
    _bullet = Bullet.new(this, 1, 4, 2)

    _fireSfx = 0
  }

  score {_score}
  bullet {_bullet}

  score=(value) {_score = value}

  fire() {
    if (_bullet.isLaunched) {
      return
    }

    TIC.sfx(_fireSfx)
    _bullet.launch()
  }

  evalInput() {
    if (TIC.btn(BTN_LEFT)) {
      x = x + -speed
    }
    if (TIC.btn(BTN_RIGHT)) {
      x = x + speed
    }

    if (TIC.btn(BTN_A) || TIC.key(KEY_SPC)) {
      fire()
    }
  }

  update() {
    super.update()
    _bullet.update()
    evalInput()
  }

  draw() {
    super.draw()
    _bullet.draw()
    //TIC.rect(x, y, w, h, 0)
    TIC.spr(368, x, y, 0, 1, 0, 0, 2, 1)
  }
}


class Enemy is Entity {
  
  construct new(x, y, w, h, speed, playerBullet) {
    super(x, y, w, h, speed)

    if (!(playerBullet is Bullet)) {
      Fiber.abort("Enemy init error: supplied arguments to constructor is not an instance of the class Bullet")
    }
    
    _minX = 6
    _maxX = WIDTH - _minX
    _maxY = HEIGHT
    
    _playerBullet = playerBullet
    _destroyed = false
    _wentEitherSides = false
  }
  
  destroyed  {_destroyed}
  wentEitherSides {_wentEitherSides}
  wentEitherSides=(value) {_wentEitherSides = value}

  checkHit() {
    return Hitbox.checkCollision(this, _playerBullet)
  }
  
  checkBoundaryHit() {
    return ((x+w) >= _maxX) || (x <= _minX)
  }
  
  move() {
    x = x + speed
  }
  
  progressDirection() {
    _wentEitherSides = false
    x = x -speed
    speed = -speed
    y = y + 4
  }
  
  update() {
    super.update()
    move()
    
    _wentEitherSides = checkBoundaryHit()
    _destroyed = checkHit()

    if (_destroyed) {
      _playerBullet.destroy()
    }
  }
  
  draw() {
    super.draw()
    TIC.rectb(x, y, w, h, 12) 
  }
}

class EnemyGroup {

  construct new(player) {
  
    _player = player

    _defaultX = 6
    _x = _defaultX
    _y = 6
    _speed = 1
    _numOfRows = 6
    _numOfEnemyPerRow = 6
    
    /* TODO:
    
       maybe add fields for the w and h of
       enemy
    */
    
    _rows = []
    for (i in 1.._numOfRows) {
      _rows.add([])
    }
    
    _rows.each {|row|
      for (i in 1.._numOfEnemyPerRow) {
        row.add(Enemy.new(_x, _y , 8, 8, _speed, _player.bullet))
        _x = _x + 8*2
      }

     _x = _defaultX
     _y = _y + 8*2 - 6
    }
  }
  
  directProgress() {
    _rows.each {|row|
      row.each {|enemy|
         enemy.progressDirection()
      }
    }
  }
    
  checkBoundaryHit() {
    _rows.each {|row|
      row.each {|enemy|
        if (!enemy.wentEitherSides) {
          return
        }

        directProgress()
      }
    }
  }

  removeDestroyedEnemy() {
    _rows.each {|row|
      row.each {|enemy|
        if (!enemy.destroyed) {
          return
        }

        row.remove(enemy)
      }
    }
  }
  
  update() {
    checkBoundaryHit()
    removeDestroyedEnemy()
    
    _rows.each {|row|
      row.each {|enemy| enemy.update()}
    }  
  }
  
  draw() {
    _rows.each {|row|
      row.each {|enemy| enemy.draw()}
    }
  }
}

class Game is TIC {

  construct new() {
    _tick = 0
    _bgColor = 0
    _x = 86
    _y = 84

    _p1 = Player.new(WIDTH/2 - 16, HEIGHT - 20, 16, 8, 1)
    _eg = EnemyGroup.new(_p1)
  }

  UPDATE() {
    _p1.update()
    _eg.update()

    _tick = _tick + 1
  }

  DRAW() {
    _p1.draw()
    _eg.draw()
    TIC.print("Katari-Space78", _x, _y, 12)
    TIC.print("Alien Movement Test", _x - 16, _y + 8, 12)
  }

  TIC() {
    TIC.cls(_bgColor)
    this.UPDATE()
    this.DRAW()
  }
}

// <TILES>
// 001:dddddddd33333ddd444333dd444443dd444433dd4443dddd433ddddd3ddddddd
// 002:ddddddddddddddddd00dddddd00ddddddddd00dddddd00ddd00dddddd00ddddd
// 003:ddddddddd0dd4d0dd4dddd4dddd0ddddd44d4d0dd0dddd4ddddd0ddddd4ddddd
// 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
// 017:ddddddddddddddddd00dddddd00ddddddddd00dddddd00ddd00dddddd00ddddd
// 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
// 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
// 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
// </TILES>

// <SPRITES>
// 042:00000000000c00000c0c0c0000ccc000000c000000ccc0000c0c0c00000c0000
// 045:000000000000000000000000000000000ccccc00000000000000000000000000
// 048:0000000000ccc0000c000c000c00cc000c0c0c000cc00c000c000c0000ccc000
// 049:00000000000c000000cc0000000c0000000c0000000c0000000c000000ccc000
// 050:0000000000ccc0000c000c0000000c00000cc00000c000000c0000000ccccc00
// 051:000000000ccccc0000000c000000c000000cc00000000c000c000c0000ccc000
// 052:000000000000c000000cc00000c0c0000c00c0000ccccc000000c0000000c000
// 053:000000000ccccc000c0000000cccc00000000c0000000c000c000c0000ccc000
// 054:00000000000ccc0000c000000c0000000cccc0000c000c000c000c0000ccc000
// 055:000000000ccccc0000000c000000c000000c000000c0000000c0000000c00000
// 056:0000000000ccc0000c000c000c000c0000ccc0000c000c000c000c0000ccc000
// 057:0000000000ccc0000c000c000c000c0000cccc0000000c000000c0000ccc0000
// 060:000000000000c000000c000000c000000c00000000c00000000c00000000c000
// 061:0000000000000000000000000ccccc00000000000ccccc000000000000000000
// 062:00000000000c00000000c00000000c00000000c000000c000000c000000c0000
// 063:0000000000ccc0000c000c000000c000000c0000000c000000000000000c0000
// 065:00000000000c000000c0c0000c000c000c000c000ccccc000c000c000c000c00
// 066:000000000cccc0000c000c000c000c000cccc0000c000c000c000c000cccc000
// 067:0000000000ccc0000c000c000c0000000c0000000c0000000c000c0000ccc000
// 068:000000000cccc0000c000c000c000c000c000c000c000c000c000c000cccc000
// 069:000000000ccccc000c0000000c0000000cccc0000c0000000c0000000ccccc00
// 070:000000000ccccc000c0000000c0000000cccc0000c0000000c0000000c000000
// 071:0000000000cccc000c0000000c0000000c0000000c00cc000c000c0000cccc00
// 072:000000000c000c000c000c000c000c000ccccc000c000c000c000c000c000c00
// 073:000000000ccc000000c0000000c0000000c0000000c0000000c000000ccc0000
// 074:0000000000000c0000000c0000000c0000000c0000000c000c000c0000ccc000
// 075:000000000c000c000c00c0000c0c00000cc000000c0c00000c00c0000c000c00
// 076:000000000c0000000c0000000c0000000c0000000c0000000c0000000ccccc00
// 077:000000000c000c000cc0cc000c0c0c000c0c0c000c000c000c000c000c000c00
// 078:000000000c000c000c000c000cc00c000c0c0c000c00cc000c000c000c000c00
// 079:0000000000ccc0000c000c000c000c000c000c000c000c000c000c0000ccc000
// 080:000000000cccc0000c000c000c000c000cccc0000c0000000c0000000c000000
// 081:0000000000ccc0000c000c000c000c000c000c000c0c0c000c00c00000cc0c00
// 082:000000000cccc0000c000c000c000c000cccc0000c0c00000c00c0000c000c00
// 083:0000000000ccc0000c000c000c00000000ccc00000000c000c000c0000ccc000
// 084:000000000ccccc00000c0000000c0000000c0000000c0000000c0000000c0000
// 085:000000000c000c000c000c000c000c000c000c000c000c000c000c0000ccc000
// 086:000000000c000c000c000c000c000c000c000c000c000c0000c0c000000c0000
// 087:000000000c000c000c000c000c000c000c0c0c000c0c0c000cc0cc000c000c00
// 088:000000000c000c000c000c0000c0c000000c000000c0c0000c000c000c000c00
// 089:000000000c000c000c000c0000c0c000000c0000000c0000000c0000000c0000
// 090:000000000ccccc0000000c000000c000000c000000c000000c0000000ccccc00
// 096:0000022200022222002222220220220222222222002220020002000000000000
// 097:2220000022222000222222002022022022222222200222000000200000000000
// 098:0020020200020000202002200000222200222020000022222020020202002000
// 099:0002002000000200022000000022002020022002202200000220000020000200
// 112:0000000500000055000000550005555500555555005555550055555500000000
// 113:0000000050000000500000005555000055555000555550005555500000000000
// 114:0000000500000000000000050005000505000500000555550055555500000000
// 115:0000000000000500005050005000000050555000555005005555050000000005
// 116:0050000050000005005000000000050500500005000500000000555500555055
// 117:0005500000000005055000000000005050055005555000005555000055550050
// 119:5000000050000000500000005000000000000000000000000000000000000000
// 120:2000200200200020022222202222222222222222022222200020020020020002
// 122:0000055500005555000555550055555505555555055555550555555505555555
// 123:5555555555555555555555555555555555555555555555555555555555555555
// 124:5000000055000000555000005555000055555000555550005555500055555000
// 128:000ccccc0cccccccccccccccccc00cc0cccccccc000cc00c00cc0cc0cc000000
// 129:c0000000ccc00000cccc00000ccc0000cccc0000c0000000cc00000000cc0000
// 130:000ccccc0cccccccccccccccccc00cc0cccccccc000cc00c0cc00cc000cc0000
// 131:c0000000ccc00000cccc00000ccc0000cccc0000c00000000cc00000cc000000
// 132:000c00000c00c00000c00000000c0000cc000000000c000000c00c000c00c000
// 133:00c000000c00c000000c000000c000000000cc0000c00000c00c00000c00c000
// 138:0555555505555555055555550555555505555555055555500555550005555500
// 139:5555555555555555555555555555555500000055000000050000000000000000
// 140:5555500055555000555550005555500055555000555550005555500055555000
// 144:00c00000c00c000cc0ccccccccc0ccc0cccccccc00cccccc00c000000c000000
// 145:c000000000c00000c0c00000ccc00000ccc00000c0000000c00000000c000000
// 146:00c00000000c000c00cccccc0cc0ccc0ccccccccc0ccccccc0c00000000cc0cc
// 147:c000000000000000c0000000cc000000ccc00000c0c00000c0c0000000000000
// 160:000cc00000cccc000cccccc0cc0cc0cccccccccc00c00c000c0cc0c000000000
// 161:000cc00000cccc000cccccc0cc0cc0cccccccccc0c0cc0c0c000000c00000000
// 176:0c000000c00000000c00000000c000000c000000c00000000c00000000000000
// 177:c00000000c00000000c000000c000000c00000000c00000000c0000000000000
// 178:0c00000000c000000c000000c00000000c00000000c000000c000000c0000000
// 179:00c000000c000000c00000000c00000000c000000c000000c000000000000000
// 180:0c0000000c0000000c0000000c0000000c000000ccc000000000000000000000
// 181:0c0000000c000000ccc000000c0000000c000000000000000000000000000000
// 182:0c000000ccc000000c0000000c0000000c000000000000000000000000000000
// 183:ccc000000c0000000c0000000c0000000c000000000000000000000000000000
// 184:0c0000000c0000000c0000000c0000000c0000000c0000000c00000000000000
// 185:0c000000cc0000000cc000000c0000000c000000cc0000000cc0000000000000
// 186:0c0000000c0000000c0000000c0000000c0000000c0000000c00000000000000
// 187:0cc00000cc0000000c0000000cc00000cc0000000c0000000c00000000000000
// 188:00c00000c000c00000cc0c000cccc000c0ccc0000ccccc00c0ccc0000c0c0c00
// </SPRITES>

// <WAVES>
// 000:00000000ffffffff00000000ffffffff
// 001:0123456789abcdeffedcba9876543210
// 002:0123456789abcdef0123456789abcdef
// </WAVES>

// <SFX>
// 000:00d100d500c500c500b600b600a60096008500660051003600030006000500050005000500060007100020004000600080009000a000e000f000f000329000000000
// 001:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300331000000000
// 008:02000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020070b000000000
// </SFX>

// <PATTERNS>
// 000:6ff184000000000000000000000000000000000000000000dff182000000000000000000000000000000000000000000fff182000000000000000000000000000000000000000000aff182000000000000000000000000000000000000000000bff1820000000000000000000000000000000000000000006ff182000000000000000000000000000000000000000000bff182000000000000000000000000000000000000000000dff182000000000000000300100080000000000000000000
// 001:aff1180000000000000000000000000000000000000000008ff1180000000000000000000000000000000000000000006ff1180000000000000000000000000000000000000000005ff118000000000000000000000000000000000000000000fff116000000000000000000000000000000000000000000dff116000000000000000000000000000000000000000000fff1160000000000000000000000000000000000000000005ff118000000000000000000000000000000000000000000
// 002:6ff1180000000000000000000000000000000000000000005ff118000000000000000000000000000000000000000000fff116000000000000000000000000000000000000000000dff116000000000000000000000000000000000000000000bff116000000000000000000000000000000000000000000aff116000000000000000000000000000000000000000000bff1160000000000000000000000000000000000000000008ff114000000000000000000000000000000000000000000
// 003:6ff116000000000000000000aff116000000000000000000dff116000000000000000000bff116000000000000000000aff1160000000000000000006ff116000000000000000000aff1160000000000000000008ff1160000000000000000006ff116000000000000000000fff1140000000000000000006ff116000000000000000000dff116000000000000000000bff116000000000000000000fff116000000000000000000dff116000000000000000000bff116000000000000000000
// 004:aff1160000000000000000006ff1160000000000000000008ff1160000000000000000005ff1180000000000000000006ff118000000000000000000aff118000000000000000000dff118000000000000000000dff116000000000000000000fff116000000000000000000bff116000000000000000000dff116000000000000000000aff1160000000000000000006ff1160000000000000000006ff1180000000000001000006ff1180000000000000000000000000000005ff118000000
// 005:6ff1180000005ff1180000006ff1180000006ff1160000005ff116000000dff1160000008ff116000000aff1160000006ff1160000006ff1180000005ff118000000fff1160000005ff118000000bff118000000dff118000000fff118000000bff118000000aff1180000008ff118000000bff118000000aff1180000008ff1180000006ff1180000005ff118000000fff116000000dff116000000bff116000000aff1160000008ff116000000bff116000000aff1160000008ff116000000
// 006:6ff1160000008ff116000000aff116000000bff116000000dff1160000008ff116000000dff116000000bff116000000aff116000000fff116000000dff116000000bff116000000dff116000000bff116000000aff1160000008ff1160000006ff116000000fff114000000fff1160000005ff1180000006ff1180000005ff118000000fff116000000dff116000000bff116000000aff1160000008ff116000000fff116000000dff116000000fff116000000dff116000000bff116000000
// 007:aff116000000000000000000aff1180000000000000000008ff1180000000000000000000000000000000000000000001000000000000000000000006ff118000000000000000000aff118000000000000000000000000000000000000000000fff118000000000000000000000000000000000000000000dff118000000000000000000000000000000000000000000fff1180000000000000000000000000000000000000000005ff11a000000000000000000000000000000000000000000
// 008:6ff11a0000000000000000006ff1180000000000000000005ff118000000000000000000000000000000000000000000100000000000000000000000fff1160000000000000000006ff1180000000000000000000000000000000000001000006ff1180000000000000000000000000000000000000000000000000000000000001000006ff1180000000000001000006ff118000000000000000000bff1180000000000000000008ff118000000000000000000dff118000000000000000000
// 009:dff118000000aff118bff118dff118000000aff118bff118dff118dff116fff1165ff1186ff1188ff118aff118bff118aff1180000006ff1188ff118aff118000000aff116bff116dff116fff116dff116bff116dff116aff116bff116dff116bff116000000fff116dff116bff116000000aff1168ff116aff1168ff1166ff1168ff116aff116bff116dff116fff116bff116000000fff116dff116fff1160000005ff1186ff118dff116fff1165ff1186ff1188ff118aff118bff118dff118
// 010:aff1180000006ff1188ff118aff1180000008ff1186ff1188ff1185ff1186ff1188ff118aff1188ff1186ff1185ff1186ff118000000fff1165ff1186ff1180000006ff1168ff116aff116bff116aff1168ff116aff1166ff1185ff1186ff118fff1160000006ff1185ff118fff116000000dff116bff116dff116bff116aff116bff116dff116fff1165ff1186ff118fff1160000006ff1185ff1186ff1180000005ff118fff1165ff1186ff1188ff1186ff1185ff1186ff118fff1165ff118
// 011:6ff1180000000000000000001000000000000000000000005ff118000000000000000000100000000000000000000000fff1160000000000000000001000000000000000000000006ff1180000000000000000001000000000000000000000006ff1160000000000000000001000000000000000000000006ff1160000000000000000001000000000000000000000006ff1160000000000000000001000000000000000000000008ff116000000000000000000100000000000000000000000
// 012:100000000000000000000000dff116000000000000000000100000000000000000000000dff116000000000000000000100000000000000000000000aff116000000000000000000100000000000000000000000dff116000000000000000000100000000000000000000000bff116000000000000000000100000000000000000000000aff116000000000000000000100000000000000000000000bff1160000000000000000001000000000000000000000008ff118000000000000000000
// 013:aff118000000aff116000000bff116000000aff1160000008ff1160000008ff118000000aff1180000008ff1180000006ff118000000aff1160000006ff116000000fff116000000dff116000000dff114000000bff114000000dff114000000fff114000000fff1160000005ff118000000fff116000000dff116000000dff114000000bff114000000dff114000000fff114000000fff116000000dff116000000fff1160000005ff1180000005ff116000000fff1140000005ff116000000
// 014:6ff1160000006ff1180000008ff1180000006ff1180000005ff1180000005ff1160000006ff1160000005ff116000000fff114000000fff116000000dff116000000fff1160000005ff1180000005ff116000000aff1160000008ff1160000006ff1160000006ff1180000008ff118000000bff118000000aff118000000aff116000000dff116000000aff1180000006ff118000000bff118000000aff118000000bff1180000008ff118000000dff116000000bff116000000dff116000000
// 015:aff116000000dff116100000dff116100000dff116100000dff116100000dff116100000dff116100000dff116000000aff116100000aff116100000aff116100000aff116100000aff116100000aff116000000dff116100000dff116000000bff116100000bff116100000bff1160000006ff1181000006ff1181000006ff1181000006ff1181000006ff1181000006ff1181000006ff118000000fff116100000fff116000000dff116100000dff1160000008ff1180000005ff118000000
// 016:dff116000000aff118100000aff118100000aff1180000008ff1181000008ff1181000008ff1181000008ff1180000006ff1181000006ff1181000006ff1181000006ff118000000dff118100000dff118100000dff118100000dff118000000fff118100000fff118100000fff118100000fff118000000dff118100000dff118100000dff118100000dff118000000fff118100000fff118100000fff118100000fff1180000005ff11a0000005ff1181000005ff1181000005ff118000000
// 017:6ff1180000006ff1168ff116aff1160000006ff1160000005ff1160000005ff1186ff1188ff1180000005ff118000000fff116000000fff1145ff1166ff116000000fff1140000005ff116000000dff116bff116aff1160000008ff1160000006ff116000000bff116aff1168ff116000000bff116000000aff1160000006ff1168ff116aff116000000dff116000000bff116000000fff116dff116bff116000000aff1160000008ff116000000dff116bff116aff1160000008ff116000000
// 018:aff1160000006ff1185ff1186ff118000000aff116000000dff116000000dff116fff1165ff118000000dff116000000aff1160000006ff1186ff118aff1180000006ff118000000aff118000000aff1188ff1186ff1180000005ff118000000fff116000000fff116dff116fff1160000005ff1180000006ff118000000aff1188ff1186ff118000000aff118000000bff1180000006ff1185ff118fff116000000fff116000000dff1160000008ff116000000dff106100000dff106000000
// 019:dff116000000000000000000000000000000000000000000000000000000000000100000dff1160000000000000000006ff116000000000000000000000000000000000000000000000000000000000000000000dff116000000000000100000bff116000000000000000000000000000000000000000000dff116000000000000000000000000000000000000000000bff1160000000000000000006ff1160000000000001000006ff106000000000000000000000000000000fff104000000
// 020:6ff1160000000000000000006ff1180000000000000000005ff118000000000000000000000000000000000000000000fff116000000000000000000000000000000000000000000dff1160000000000000000000000000000000000000000006ff1160000000000000000000000000000008ff116000000aff116000000000000000000000000000000000000000000fff1160000000000000000000000000000000000000000008ff1160000000000000000000000001000008ff116000000
// 021:aff116000000000000000000000000000000aff118100000aff118000000bff118000000aff1180000008ff1180000006ff1180000000000000000000000001000006ff1180000006ff1180000008ff1180000006ff1180000005ff118000000fff1160000000000000000000000000000000000000000006ff1180000000000000000000000000000000000000000006ff1180000004ff118000000fff1160000004ff118000000dff116000000000000000000000000100000dff116000000
// 022:dff116000000000000000000000000000000dff118100000dff118000000fff118000000dff118000000bff118000000aff118000000000000000000000000100000aff118100000aff118000000bff118000000aff1180000008ff1180000006ff1180000004ff118000000fff1160000004ff118000000dff116000000000000000000000000100000dff116000000bff1160000000000000000006ff1180000000000000000005ff1180000000000000000000000001000005ff118000000
// 023:6ff1180000000000001000006ff1180000000000000000000000000000000000000000005ff118000000000000000000000000000000000000000000fff116000000000000000000000000000000000000000000dff116000000000000000000000000000000000000000000bff116000000000000000000000000000000000000000000aff1160000000000000000000000000000000000000000000000000000008ff1161000008ff116000000000000000000000000000000000000000000
// 024:aff116000000000000000000aff1180000000000000000000000000000000000000000008ff1180000000000000000006ff1180000000000000000006ff11a0000000000000000000000000000000000000000004ff11a000000000000000000fff1180000000000000000000000000000000000000000006ff11a000000000000000000dff118000000000000000000fff118000000000000000000000000000000000000000000dff118000000000000000000000000000000000000000000
// 025:dff118000000000000000000000000000000000000000000dff116000000000000000000000000000000bff116000000aff116000000000000000000000000000000000000000000aff1180000000000000000000000000000008ff1180000006ff1180000000000000000000000000000000000000000000000000000000000001000006ff1080000000000001000006ff1080000000000000000000000000000000000000000005ff108000000000000000000000000000000000000000000
// 026:6ff1180000000000000000006ff1160000000000000000005ff1160000000000000000005ff118000000000000000000fff116000000000000000000fff114000000000000000000dff114000000000000000000dff116000000000000000000bff116000000000000000000bff118000000000000000000aff118000000000000000000aff1160000000000000000008ff116000000000000000000fff1160000000000000000008ff1160000000000000000008ff118000000000000000000
// 027:aff118000000000000000000aff1160000000000000000008ff1160000000000000000008ff1180000000000000000006ff1180000000000000000006ff1160000000000000000005ff1160000000000000000005ff118000000000000000000fff116000000000000000000fff118000000000000000000dff118000000000000000000dff116000000000000000000bff1160000000000000000000000000000008ff118000000dff118000000000000100000dff108000000000000000000
// 028:6ff104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// 029:dff116000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// 030:aff118000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// 031:6ff118000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// </PATTERNS>

// <TRACKS>
// 000:1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf
// </TRACKS>

// <SCREEN>
// 000:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 001:ddddffffddffddfdffddddffddddfffffdffffddffffdffdddddfffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 002:ddddffddfdffddfdffddddffddddffdddddffddfffdddffdddddffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 003:ddddffffddffddfdffddddffddddffffdddffdddfffdddddddddffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 004:ddddffddfdffddfdffddddffddddffdddddffddddfffdffddddddddffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 005:ddddffffdddfffddfffffdfffffdfffffddffddffffddffdddddffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 006:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 007:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 008:ddddfffffdffddfdfffffdffdffdffffdfffffddffffdffddddddfffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 009:ddddffddddfffdfdffddddfffffddffddffddddfffdddffdddddffddfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 010:ddddffffddfffffdffffddfffffddffddffffdddfffddddddddddfffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 011:ddddffddddffdffdffddddfdfdfddffddffddddddfffdffdddddffddfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 012:ddddfffffdffddfdfffffdfdddfdffffdfffffdffffddffddddddfffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 013:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 014:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 015:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 016:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 017:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 018:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 019:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 020:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 021:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 022:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 023:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 024:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 025:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 026:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 027:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 028:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 029:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 030:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 031:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 032:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 033:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 034:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 035:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 036:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 037:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 038:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 039:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 040:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 041:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 042:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 043:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 044:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 045:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 046:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 047:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 048:dddddd00dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 049:dddddd00dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 050:dddd00ddd00ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 051:dddd00ddd00dddd0000dddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 052:dddddd00dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 053:dddddd00dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 054:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 055:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 056:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 057:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 058:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 059:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 060:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 061:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 062:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 063:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 064:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 065:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 066:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 067:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 068:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 069:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 070:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 071:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 072:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 073:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 074:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 075:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 076:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 077:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddd
// 078:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddd
// 079:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddd
// 080:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddd
// 081:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 082:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 083:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 084:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 085:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 086:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 087:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 088:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 089:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 090:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 091:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 092:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 093:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 094:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 095:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 096:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd0000dddddddd0000dd
// 097:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd0000dddddddd0000dd
// 098:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd0000dddddddd0000dd
// 099:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd0000dddddddd0000dd
// 100:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 101:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 102:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 103:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 104:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 105:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 106:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 107:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd
// 108:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd
// 109:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd
// 110:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000dddddddddddddddddddddddddd0000dddddddd
// 111:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 112:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 113:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 114:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 115:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 116:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 117:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 118:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 119:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 120:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 121:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 122:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 123:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 124:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 125:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 126:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 127:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 128:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 129:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 130:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 131:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 132:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 133:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 134:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// 135:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// </SCREEN>

// <PALETTE>
// 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
// </PALETTE>

