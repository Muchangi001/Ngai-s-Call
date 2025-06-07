import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// --- Game Entry Point ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.setPortrait();
  runApp(GameWidget(game: NgaisCallGame()));
}

// --- Configuration ---
class GameConfig {
  static final player = _PlayerConfig();
  static final enemy = _EnemyConfig();
  static final blessing = _BlessingConfig();
  static final game = _GameConfig();
}

class _PlayerConfig {
  final double speed = 250.0;
  final double size = 15.0;
  final double protectionDuration = 3.0;
  final double protectionEnergyCost = 30.0;
}

class _EnemyConfig {
  final double speed = 90.0;
  final double size = 12.0;
  final double spawnInterval = 1.8;
  final int scoreOnDestroy = 10;
  final double energyOnDestroy = 5.0;
}

class _BlessingConfig {
  final double size = 10.0;
  final double spawnInterval = 5.0;
  final int scoreOnCollect = 5;
  final double energyOnCollect = 20.0;
}

class _GameConfig {
  final double initialEnergy = 50.0;
  final double maxEnergy = 100.0;
  final int initialEnemyCount = 3;
}

// --- Game State ---
enum GameState { playing, gameOver }

// --- Main Game Class ---
class NgaisCallGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  GameState state = GameState.playing;

  // Components
  late Player player;
  late SpiritualEnergyBar ui;
  late PlayerInputHandler inputHandler;

  // Timers for spawning entities
  late Timer _enemySpawnTimer;
  late Timer _blessingSpawnTimer;

  int score = 0;

  @override
  Future<void> onLoad() async {
    add(Background());

    // Initialize player
    player = Player();
    add(player);

    // Initialize UI
    ui = SpiritualEnergyBar();
    add(ui);
    
    // Add input handler - this was missing!
    inputHandler = PlayerInputHandler();
    add(inputHandler);
    
    // Start spawning
    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }
    
    // Display instructions
    add(InstructionsText());
  }

  void reset() {
    score = 0;
    state = GameState.playing;
    
    // Remove all enemies, blessings and game over screen
    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Blessing>().forEach((blessing) => blessing.removeFromParent());
    children.whereType<GameOverScreen>().forEach((screen) => screen.removeFromParent());
    
    // Reset player and UI
    player.reset();
    ui.reset();
    
    // Restart spawning
    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final result = super.onKeyEvent(event, keysPressed);
    if (keysPressed.contains(LogicalKeyboardKey.keyR) && state == GameState.gameOver) {
      reset();
      return KeyEventResult.handled;
    }
    return result;
  }
  
  void _startSpawning() {
    _enemySpawnTimer = Timer(GameConfig.enemy.spawnInterval, onTick: spawnEnemy, repeat: true);
    _blessingSpawnTimer = Timer(GameConfig.blessing.spawnInterval, onTick: spawnBlessing, repeat: true);
    _enemySpawnTimer.start();
    _blessingSpawnTimer.start();
  }

  void spawnEnemy() {
    final edge = math.Random().nextInt(4);
    Vector2 position;

    switch (edge) {
      case 0: // Top
        position = Vector2(math.Random().nextDouble() * size.x, 0);
        break;
      case 1: // Right
        position = Vector2(size.x, math.Random().nextDouble() * size.y);
        break;
      case 2: // Bottom
        position = Vector2(math.Random().nextDouble() * size.x, size.y);
        break;
      default: // Left
        position = Vector2(0, math.Random().nextDouble() * size.y);
        break;
    }
    add(Enemy(startPosition: position));
  }

  void spawnBlessing() {
    final position = Vector2(
      math.Random().nextDouble() * size.x,
      math.Random().nextDouble() * size.y,
    );
    add(Blessing(startPosition: position));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == GameState.playing) {
      _enemySpawnTimer.update(dt);
      _blessingSpawnTimer.update(dt);
    }
  }

  void onGameOver() {
    state = GameState.gameOver;
    _enemySpawnTimer.stop();
    _blessingSpawnTimer.stop();
    add(GameOverScreen());
  }
}

// --- Player Component ---
class Player extends PositionComponent with CollisionCallbacks {
  bool isProtected = false;
  late Timer _protectionTimer;
  Vector2 _moveDirection = Vector2.zero();

  Player() : super(size: Vector2.all(GameConfig.player.size * 2), anchor: Anchor.center) {
    _protectionTimer = Timer(GameConfig.player.protectionDuration, onTick: () {
      isProtected = false;
    });
  }

  @override
  Future<void> onLoad() async {
    reset();
    add(CircleHitbox());
  }
  
  void reset() {
    final gameRef = findGame();
    if (gameRef != null) {
      position = gameRef.size / 2;
    }
    isProtected = false;
    _protectionTimer.stop();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = isProtected 
        ? (Paint()..color = const Color(0xFFFFC107)) 
        : BasicPalette.lightBlue.paint();
    final glowOpacity = isProtected ? 0.5 : 0.3;
    
    // Draw glow effect
    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 3,
      Paint()..color = paint.color.withOpacity(glowOpacity)
    );
    // Draw main player circle
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isProtected) _protectionTimer.update(dt);
    
    // Update position based on movement direction
    position += _moveDirection.normalized() * GameConfig.player.speed * dt;
    
    // Keep player within screen bounds
    final gameRef = findGame();
    if (gameRef != null) {
      position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
      position.y = position.y.clamp(size.y / 2, gameRef.size.y - size.y / 2);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Enemy) {
      if (isProtected) {
        other.removeFromParent();
        final gameRef = findGame() as NgaisCallGame?;
        if (gameRef != null) {
          gameRef.score += GameConfig.enemy.scoreOnDestroy;
          gameRef.ui.addEnergy(GameConfig.enemy.energyOnDestroy);
        }
      } else {
        (findGame() as NgaisCallGame?)?.onGameOver();
      }
    } else if (other is Blessing) {
      other.removeFromParent();
      final gameRef = findGame() as NgaisCallGame?;
      if (gameRef != null) {
        gameRef.score += GameConfig.blessing.scoreOnCollect;
        gameRef.ui.addEnergy(GameConfig.blessing.energyOnCollect);
      }
    }
  }

  void handleMovement(Set<LogicalKeyboardKey> keysPressed) {
    _moveDirection = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || 
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      _moveDirection.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || 
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      _moveDirection.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || 
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _moveDirection.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || 
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _moveDirection.x = 1;
    }
  }

  void handleProtection(Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      final game = findGame() as NgaisCallGame?;
      if (game != null && game.ui.canUseEnergy(GameConfig.player.protectionEnergyCost)) {
        activateProtection();
        game.ui.useEnergy(GameConfig.player.protectionEnergyCost);
      }
    }
  }

  void activateProtection() {
    isProtected = true;
    _protectionTimer.start();
  }
}

// --- Enemy Component ---
class Enemy extends PositionComponent with HasGameRef<NgaisCallGame> {
  final Vector2 startPosition;

  Enemy({required this.startPosition}) : super(size: Vector2.all(GameConfig.enemy.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final enemyPaint = BasicPalette.red.paint();
    
    // Dark aura
    canvas.drawCircle(Offset.zero, size.x / 2 + 4, 
        Paint()..color = enemyPaint.color.withOpacity(0.4));
    // Core
    canvas.drawCircle(Offset.zero, size.x / 2, enemyPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    
    // Move towards player
    final direction = (game.player.position - position).normalized();
    position += direction * GameConfig.enemy.speed * dt;
  }
}

// --- Blessing Component ---
class Blessing extends PositionComponent {
  final Vector2 startPosition;
  double _pulseTimer = 0;

  Blessing({required this.startPosition}) : super(size: Vector2.all(GameConfig.blessing.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final blessingPaint = BasicPalette.green.paint();
    final pulseEffect = (math.sin(_pulseTimer * 4) * 0.2 + 1.0);
    
    // Pulsing glow
    canvas.drawCircle(
      Offset.zero,
      (size.x / 2) * pulseEffect + 3,
      Paint()..color = blessingPaint.color.withOpacity(0.3 * pulseEffect)
    );
    // Core
    canvas.drawCircle(Offset.zero, size.x / 2, blessingPaint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }
}

// --- UI Components ---

class SpiritualEnergyBar extends PositionComponent with HasGameRef<NgaisCallGame> {
  double energy = GameConfig.game.initialEnergy;
  final double maxEnergy = GameConfig.game.maxEnergy;

  void addEnergy(double amount) => energy = (energy + amount).clamp(0, maxEnergy);
  void useEnergy(double amount) => energy = (energy - amount).clamp(0, maxEnergy);
  bool canUseEnergy(double amount) => energy >= amount;
  
  void reset() => energy = GameConfig.game.initialEnergy;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Energy bar background
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(const Rect.fromLTWH(10, 10, 200, 20), bgPaint);

    // Energy bar fill
    final energyPaint = Paint()..color = energy > GameConfig.player.protectionEnergyCost 
        ? Colors.lightBlueAccent 
        : Colors.redAccent;
    final energyWidth = (energy / maxEnergy) * 200;
    canvas.drawRect(Rect.fromLTWH(10, 10, energyWidth, 20), energyPaint);

    // Score Text
    TextPainter(
      text: TextSpan(text: 'Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, const Offset(10, 35));
  }
}

// Fixed input handler
class PlayerInputHandler extends Component with KeyboardHandler, HasGameRef<NgaisCallGame> {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.state == GameState.playing) {
      game.player.handleMovement(keysPressed);
      game.player.handleProtection(keysPressed);
    }
    return true;
  }
}

class InstructionsText extends PositionComponent with HasGameRef<NgaisCallGame> {
  @override
  Future<void> onLoad() async {
    final regular = const TextStyle(color: Colors.white70, fontSize: 12);
    final highlight = const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold);

    add(
      TextComponent(
        text: 'WASD/Arrows: Move   |   Space: Call for Ngai\'s Protection',
        textRenderer: TextPaint(style: regular),
        position: Vector2(10, game.size.y - 50)
      )
    );
    
    add(
      TextComponent(
        text: 'Gather green blessings (Thaay). Dispel red spirits (Ngoma).',
        textRenderer: TextPaint(style: highlight),
        position: Vector2(10, game.size.y - 30)
      )
    );
  }
}

class GameOverScreen extends PositionComponent with HasGameRef<NgaisCallGame> {
  @override
  Future<void> onLoad() async {
    final style = TextStyle(fontSize: 32, color: BasicPalette.red.color, fontWeight: FontWeight.bold);
    final text = 'Ngai\'s Call has Ended\nScore: ${game.score}\n\nPress \'R\' to try again';
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center
    );
    textPainter.layout();

    final position = Vector2(
      (game.size.x / 2) - (textPainter.width / 2),
      (game.size.y / 2) - (textPainter.height / 2),
    );
    
    // Background
    add(
      RectangleComponent(
        position: position - Vector2.all(20),
        size: Vector2(textPainter.width, textPainter.height) + Vector2.all(40),
        paint: Paint()..color = Colors.black.withOpacity(0.7)
      )
    );
    
    add(TextComponent(text: text, textRenderer: TextPaint(style: style), position: position));
  }
}

class Background extends Component with HasGameRef<NgaisCallGame> {
  @override
  void render(Canvas canvas) {
    final gameSize = gameRef.size;
    final rect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1a237e), Color(0xFF000000)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }
}