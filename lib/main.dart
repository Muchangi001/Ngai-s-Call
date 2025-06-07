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
  static final proverb = _ProverbConfig();
  static final ancestor = _AncestorConfig();
  static final game = _GameConfig();
  static final hideout = _HideoutConfig(); // New hideout config
}

class _PlayerConfig {
  final double speed = 250.0;
  final double size = 15.0;
  final double protectionDuration = 3.0;
  final double protectionEnergyCost = 30.0;
}

class _EnemyConfig {
  final double speed = 90.0; // Base pursuit speed
  final double size = 12.0;
  final double spawnInterval = 1.8;
  final int scoreOnDestroy = 10;
  final double energyOnDestroy = 5.0;
  final double detectionRadius = 180.0; // How close player needs to be to trigger chase
  final double wanderingSpeed = 40.0; // Speed when not chasing
}

class _BlessingConfig {
  final double size = 10.0;
  final double spawnInterval = 5.0;
  final int scoreOnCollect = 5;
  final double energyOnCollect = 20.0;
}

class _ProverbConfig {
  final double size = 8.0;
  final double spawnInterval = 12.0;
  final int scoreOnCollect = 25;
  final int wisdomOnCollect = 1;
  final double energyOnCollect = 15.0;
}

class _AncestorConfig {
  final double size = 20.0;
  final double spawnInterval = 25.0;
  final int scoreOnCollect = 50;
  final double energyOnCollect = 40.0;
  final double blessingDuration = 8.0;
}

class _GameConfig {
  final double initialEnergy = 50.0;
  final double maxEnergy = 100.0;
  final int initialEnemyCount = 3;
  final double initialLife = 100.0; // Initial player life
  final double maxLife = 100.0; // Maximum player life
  final double lifeDrainRate = 15.0; // Life drained per second when hit by enemy
  final int hideoutTrapScore = 50; // Score gained per trapped enemy
  final double hideoutTrapEnergy = 15.0; // Energy gained per trapped enemy
  final double hideoutTrapRadius = 150.0; // Radius around hideout to trap enemies
}

class _HideoutConfig {
  final double size = 70.0;
  final double spawnInterval = 30.0; // New hideout will appear after sometime
}

// --- Kikuyu Wisdom Database ---
class KikuyuWisdom {
  static final List<String> proverbs = [
    "Gikuyu na Mumbi - Unity gives strength",
    "Harambee - We pull together",
    "Mti hauendi uru na ugeeni - A tree doesn't lean without wind",
    "Kahiu gatagwo na njira - A hawk circles its prey",
    "Mwaki wa muingi ndungagwo - A community fire burns bright",
    "Muici ndacokaga na kirira - The thief returns with tears",
    "Gutiri mwana wa nyawira - No child belongs to work alone",
    "Njira ya muingi ti ya kaba - The people's path has no thorns",
    "Mti wa Ngai - Tree of the Most High",
    "Gikeno kia njohi - Joy comes from unity"
  ];

  static final List<String> ancestorSayings = [
    "Ngai watches over the faithful",
    "The ancestors guide your path",
    "Wisdom flows like the sacred river",
    "Mount Kenya stands eternal",
    "The fig tree shelters all who seek",
    "Sacred groves hold ancient power"
  ];

  static String getRandomProverb() => proverbs[math.Random().nextInt(proverbs.length)];
  static String getRandomAncestorSaying() => ancestorSayings[math.Random().nextInt(ancestorSayings.length)];
}

// --- Game State ---
enum GameState { splash, playing, gameOver } // Added splash state

// --- Main Game Class ---
class NgaisCallGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  GameState state = GameState.splash; // Initial state is splash

  // Components
  late Player player;
  late SpiritualEnergyBar ui;
  late PlayerInputHandler inputHandler;
  late ForestBackground forest;

  // Timers for spawning entities
  late Timer _enemySpawnTimer;
  late Timer _blessingSpawnTimer;
  late Timer _proverbSpawnTimer;
  late Timer _ancestorSpawnTimer;
  late Timer _hideoutSpawnTimer; // New timer for hideouts

  int score = 0;
  int wisdom = 0;
  String? currentMessage;
  double messageTimer = 0;

  @override
  Future<void> onLoad() async {
    // Add forest background first
    forest = ForestBackground();
    add(forest);

    // Add the splash screen initially
    add(SplashScreen());
  }

  // Method to start the actual game
  void startGame() {
    // Remove all components that are not the background
    children.whereType<SplashScreen>().forEach((screen) => screen.removeFromParent());
    children.whereType<GameOverScreen>().forEach((screen) => screen.removeFromParent());

    // Initialize player
    player = Player();
    add(player);

    // Initialize UI
    ui = SpiritualEnergyBar();
    add(ui);
    
    // Add input handler
    inputHandler = PlayerInputHandler();
    add(inputHandler);
    
    // Start spawning
    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }
    
    // Display instructions
    add(InstructionsText());

    state = GameState.playing; // Transition to playing state
  }

  void reset() {
    score = 0;
    wisdom = 0;
    currentMessage = null;
    messageTimer = 0;
    
    // Remove all game-specific entities
    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Blessing>().forEach((blessing) => blessing.removeFromParent());
    children.whereType<KikuyuProverb>().forEach((proverb) => proverb.removeFromParent());
    children.whereType<AncestorSpirit>().forEach((ancestor) => ancestor.removeFromParent());
    children.whereType<Hideout>().forEach((hideout) => hideout.removeFromParent());
    children.whereType<InstructionsText>().forEach((instr) => instr.removeFromParent());
    children.whereType<SpiritualEnergyBar>().forEach((uiBar) => uiBar.removeFromParent());
    children.whereType<Player>().forEach((p) => p.removeFromParent());
    children.whereType<PlayerInputHandler>().forEach((handler) => handler.removeFromParent());

    // Stop all timers
    _enemySpawnTimer.stop();
    _blessingSpawnTimer.stop();
    _proverbSpawnTimer.stop();
    _ancestorSpawnTimer.stop();
    _hideoutSpawnTimer.stop();
    
    // Go back to splash screen state
    state = GameState.splash;
    add(SplashScreen());
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final result = super.onKeyEvent(event, keysPressed);
    if (state == GameState.splash) {
      // If in splash screen, any key press starts the game
      startGame();
      return KeyEventResult.handled;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyR) && state == GameState.gameOver) {
      reset();
      return KeyEventResult.handled;
    }
    return result;
  }
  
  void _startSpawning() {
    _enemySpawnTimer = Timer(GameConfig.enemy.spawnInterval, onTick: spawnEnemy, repeat: true);
    _blessingSpawnTimer = Timer(GameConfig.blessing.spawnInterval, onTick: spawnBlessing, repeat: true);
    _proverbSpawnTimer = Timer(GameConfig.proverb.spawnInterval, onTick: spawnProverb, repeat: true);
    _ancestorSpawnTimer = Timer(GameConfig.ancestor.spawnInterval, onTick: spawnAncestor, repeat: true);
    _hideoutSpawnTimer = Timer(GameConfig.hideout.spawnInterval, onTick: spawnHideout, repeat: true); // Start hideout timer
    
    _enemySpawnTimer.start();
    _blessingSpawnTimer.start();
    _proverbSpawnTimer.start();
    _ancestorSpawnTimer.start();
    _hideoutSpawnTimer.start(); // Start hideout timer
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

  void spawnProverb() {
    final position = Vector2(
      math.Random().nextDouble() * size.x,
      math.Random().nextDouble() * size.y,
    );
    add(KikuyuProverb(startPosition: position));
  }

  void spawnAncestor() {
    final position = Vector2(
      math.Random().nextDouble() * size.x,
      math.Random().nextDouble() * size.y,
    );
    add(AncestorSpirit(startPosition: position));
  }

  void spawnHideout() {
    // Ensure only one hideout exists at a time for simplicity of trapping
    children.whereType<Hideout>().forEach((h) => h.removeFromParent());
    final position = Vector2(
      math.Random().nextDouble() * size.x,
      math.Random().nextDouble() * size.y,
    );
    add(Hideout(startPosition: position));
  }

  // New method to trap enemies when player enters a hideout
  void trapEnemiesInHideout(Hideout hideout) {
    int trappedCount = 0;
    final enemiesToRemove = <Enemy>[];

    for (var component in children) {
      if (component is Enemy) {
        // Check if enemy is within trapping radius of the hideout
        if (component.position.distanceTo(hideout.position) < GameConfig.game.hideoutTrapRadius) {
          enemiesToRemove.add(component);
        }
      }
    }

    for (var enemy in enemiesToRemove) {
      enemy.removeFromParent();
      score += GameConfig.game.hideoutTrapScore;
      ui.addEnergy(GameConfig.game.hideoutTrapEnergy);
      trappedCount++;
    }

    if (trappedCount > 0) {
      showMessage("Fellow Mau Mau fighters ambushed $trappedCount troops!");
    }
  }

  void showMessage(String message) {
    currentMessage = message;
    messageTimer = 3.0; // Show for 3 seconds
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == GameState.playing) {
      _enemySpawnTimer.update(dt);
      _blessingSpawnTimer.update(dt);
      _proverbSpawnTimer.update(dt);
      _ancestorSpawnTimer.update(dt);
      _hideoutSpawnTimer.update(dt); // Update hideout timer
    }
    
    // Update message timer
    if (messageTimer > 0) {
      messageTimer -= dt;
      if (messageTimer <= 0) {
        currentMessage = null;
      }
    }
  }

  void onGameOver() {
    state = GameState.gameOver;
    _enemySpawnTimer.stop();
    _blessingSpawnTimer.stop();
    _proverbSpawnTimer.stop();
    _ancestorSpawnTimer.stop();
    _hideoutSpawnTimer.stop(); // Stop hideout timer
    add(GameOverScreen());
  }
}

// --- Forest Background ---
class ForestBackground extends Component with HasGameRef<NgaisCallGame> {
  final List<TreeSprite> trees = [];
  final List<SacredGrove> groves = [];

  @override
  Future<void> onLoad() async {
    // Generate forest elements
    _generateTrees();
    _generateSacredGroves();
  }

  void _generateTrees() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      trees.add(TreeSprite(
        position: Vector2(
          random.nextDouble() * gameRef.size.x,
          random.nextDouble() * gameRef.size.y,
        ),
        size: random.nextDouble() * 30 + 20,
      ));
    }
  }

  void _generateSacredGroves() {
    final random = math.Random();
    for (int i = 0; i < 3; i++) {
      groves.add(SacredGrove(
        position: Vector2(
          random.nextDouble() * gameRef.size.x,
          random.nextDouble() * gameRef.size.y,
        ),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final gameSize = gameRef.size;
    
    // Forest gradient background
    final rect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Render sacred groves first (background layer)
    for (final grove in groves) {
      grove.render(canvas);
    }
    
    // Render trees
    for (final tree in trees) {
      tree.render(canvas);
    }
  }
}

class TreeSprite {
  final Vector2 position;
  final double size;

  TreeSprite({required this.position, required this.size});

  void render(Canvas canvas) {
    // Tree trunk
    final trunkPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(position.x, position.y + size * 0.3), width: size * 0.2, height: size * 0.6),
      trunkPaint
    );
    
    // Tree canopy
    final canopyPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(position.x, position.y - size * 0.2), size * 0.4, canopyPaint);
    
    // Lighter foliage details
    final lightFoliage = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(position.x - size * 0.1, position.y - size * 0.3), size * 0.15, lightFoliage);
    canvas.drawCircle(Offset(position.x + size * 0.1, position.y - size * 0.1), size * 0.12, lightFoliage);
  }
}

class SacredGrove {
  final Vector2 position;

  SacredGrove({required this.position});

  void render(Canvas canvas) {
    // Sacred circle
    final grovePaint = Paint()..color = const Color(0xFF1B5E20).withOpacity(0.3);
    canvas.drawCircle(Offset(position.x, position.y), 60, grovePaint);
    
    // Inner sacred ring
    final sacredPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(position.x, position.y), 50, sacredPaint);
  }
}

// --- Player Component ---
class Player extends PositionComponent with CollisionCallbacks {
  bool isProtected = false;
  bool hasAncestorBlessing = false;
  bool isHitByEnemy = false; // New: true when colliding with enemy and not protected
  bool isInHideout = false; // New: true when inside a hideout

  late Timer _protectionTimer;
  late Timer _ancestorBlessingTimer;
  Vector2 _moveDirection = Vector2.zero();

  double life = GameConfig.game.initialLife; // Player's current life
  final double maxLife = GameConfig.game.maxLife; // Player's max life

  Player() : super(size: Vector2.all(GameConfig.player.size * 2), anchor: Anchor.center) {
    _protectionTimer = Timer(GameConfig.player.protectionDuration, onTick: () {
      isProtected = false;
    });
    _ancestorBlessingTimer = Timer(GameConfig.ancestor.blessingDuration, onTick: () {
      hasAncestorBlessing = false;
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
    life = GameConfig.game.initialLife; // Reset life
    isProtected = false;
    hasAncestorBlessing = false;
    isHitByEnemy = false;
    isInHideout = false;
    _protectionTimer.stop();
    _ancestorBlessingTimer.stop();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Base color based on state
    Color baseColor = const Color(0xFF03A9F4); // Light blue
    if (hasAncestorBlessing) baseColor = const Color(0xFFFFD700); // Gold
    if (isProtected) baseColor = const Color(0xFFFFC107); // Amber
    if (isHitByEnemy) baseColor = Colors.red; // Indicate damage

    final paint = Paint()..color = baseColor;
    final glowOpacity = (isProtected || hasAncestorBlessing) ? 0.6 : 0.3;
    
    // Draw spiritual aura
    if (hasAncestorBlessing) {
      // Ancestor blessing aura (golden)
      canvas.drawCircle(
        Offset.zero,
        size.x / 2 + 8,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.4)
      );
    }
    
    // Draw glow effect
    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 3,
      Paint()..color = paint.color.withOpacity(glowOpacity)
    );
    
    // Draw main player circle
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    
    // Draw inner spiritual core
    canvas.drawCircle(
      Offset.zero, 
      size.x / 3, 
      Paint()..color = Colors.white.withOpacity(0.7)
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isProtected) _protectionTimer.update(dt);
    if (hasAncestorBlessing) _ancestorBlessingTimer.update(dt);
    
    // Reduce life if hit by enemy and not protected
    if (isHitByEnemy && !isProtected && !hasAncestorBlessing) {
      life = (life - GameConfig.game.lifeDrainRate * dt).clamp(0, maxLife);
      if (life <= 0) {
        final gameRef = findGame() as NgaisCallGame?;
        gameRef?.onGameOver();
      }
    }

    // Update position based on movement direction
    final speed = hasAncestorBlessing ? GameConfig.player.speed * 1.5 : GameConfig.player.speed;
    position += _moveDirection.normalized() * speed * dt;
    
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
    final gameRef = findGame() as NgaisCallGame?;
    if (gameRef == null) return;
    
    if (other is Enemy) {
      if (isProtected || hasAncestorBlessing) {
        other.removeFromParent();
        gameRef.score += GameConfig.enemy.scoreOnDestroy;
        gameRef.ui.addEnergy(GameConfig.enemy.energyOnDestroy);
        if (hasAncestorBlessing) {
          gameRef.score += GameConfig.enemy.scoreOnDestroy; // Double score with ancestor blessing
        }
      } else {
        isHitByEnemy = true; // Player is now being hit
      }
    } else if (other is Blessing) {
      other.removeFromParent();
      gameRef.score += GameConfig.blessing.scoreOnCollect;
      gameRef.ui.addEnergy(GameConfig.blessing.energyOnCollect);
    } else if (other is KikuyuProverb) {
      other.removeFromParent();
      gameRef.score += GameConfig.proverb.scoreOnCollect;
      gameRef.wisdom += GameConfig.proverb.wisdomOnCollect;
      gameRef.ui.addEnergy(GameConfig.proverb.energyOnCollect);
      gameRef.showMessage(other.proverb);
    } else if (other is AncestorSpirit) {
      other.removeFromParent();
      gameRef.score += GameConfig.ancestor.scoreOnCollect;
      gameRef.ui.addEnergy(GameConfig.ancestor.energyOnCollect);
      activateAncestorBlessing();
      gameRef.showMessage(other.saying);
    } else if (other is Hideout) {
      isInHideout = true;
      gameRef.trapEnemiesInHideout(other); // Trigger trap when entering hideout
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Enemy) {
      isHitByEnemy = false; // Player is no longer being hit
    } else if (other is Hideout) {
      isInHideout = false;
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

  void activateAncestorBlessing() {
    hasAncestorBlessing = true;
    _ancestorBlessingTimer.start();
  }
}

// --- Enemy Component ---
class Enemy extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  Vector2 _currentWaypoint = Vector2.zero(); // New: for wandering behavior
  final math.Random _random = math.Random();

  Enemy({required this.startPosition}) : super(size: Vector2.all(GameConfig.enemy.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
    _pickNewWaypoint(); // Initialize first waypoint
  }

  void _pickNewWaypoint() {
    _currentWaypoint = Vector2(
      _random.nextDouble() * game.size.x,
      _random.nextDouble() * game.size.y,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final enemyPaint = Paint()..color = const Color(0xFFD32F2F);
    
    // Dark aura
    canvas.drawCircle(Offset.zero, size.x / 2 + 4, 
        Paint()..color = enemyPaint.color.withOpacity(0.4));
    // Core
    canvas.drawCircle(Offset.zero, size.x / 2, enemyPaint);
    // Evil eye
    canvas.drawCircle(Offset.zero, size.x / 4, 
        Paint()..color = const Color(0xFF8B0000));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    
    final playerPosition = game.player.position;
    final distanceToPlayer = position.distanceTo(playerPosition);

    if (distanceToPlayer < GameConfig.enemy.detectionRadius) {
      // Chase player if within detection radius
      final direction = (playerPosition - position).normalized();
      position += direction * GameConfig.enemy.speed * dt;
    } else {
      // Wander if player is outside detection radius
      if (position.distanceTo(_currentWaypoint) < 5) { // If close to waypoint
        _pickNewWaypoint();
      }
      final direction = (_currentWaypoint - position).normalized();
      position += direction * GameConfig.enemy.wanderingSpeed * dt;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // If enemy collides with a hideout, it gets removed (trapped)
    if (other is Hideout) {
      removeFromParent();
    }
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
    final blessingPaint = Paint()..color = const Color(0xFF4CAF50);
    final pulseEffect = (math.sin(_pulseTimer * 4) * 0.2 + 1.0);
    
    // Pulsing glow
    canvas.drawCircle(
      Offset.zero,
      (size.x / 2) * pulseEffect + 3,
      Paint()..color = blessingPaint.color.withOpacity(0.3 * pulseEffect)
    );
    // Core
    canvas.drawCircle(Offset.zero, size.x / 2, blessingPaint);
    // Inner light
    canvas.drawCircle(Offset.zero, size.x / 3, 
        Paint()..color = const Color(0xFF81C784));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }
}

// --- Kikuyu Proverb Component ---
class KikuyuProverb extends PositionComponent {
  final Vector2 startPosition;
  final String proverb;
  double _glowTimer = 0;

  KikuyuProverb({required this.startPosition}) 
    : proverb = KikuyuWisdom.getRandomProverb(),
      super(size: Vector2.all(GameConfig.proverb.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final proverbPaint = Paint()..color = const Color(0xFF9C27B0); // Purple for wisdom
    final glowEffect = (math.sin(_glowTimer * 3) * 0.3 + 0.7);
    
    // Wisdom aura
    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 6,
      Paint()..color = proverbPaint.color.withOpacity(0.2 * glowEffect)
    );
    
    // Main circle
    canvas.drawCircle(Offset.zero, size.x / 2, proverbPaint);
    
    // Wisdom symbol (small inner circles)
    canvas.drawCircle(Offset(-size.x/4, -size.y/4), 2, 
        Paint()..color = const Color(0xFFE1BEE7));
    canvas.drawCircle(Offset(size.x/4, -size.y/4), 2, 
        Paint()..color = const Color(0xFFE1BEE7));
    canvas.drawCircle(Offset(0, size.y/4), 2, 
        Paint()..color = const Color(0xFFE1BEE7));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _glowTimer += dt;
  }
}

// --- Ancestor Spirit Component ---
class AncestorSpirit extends PositionComponent {
  final Vector2 startPosition;
  final String saying;
  double _floatTimer = 0;
  late Vector2 _originalPosition;

  AncestorSpirit({required this.startPosition}) 
    : saying = KikuyuWisdom.getRandomAncestorSaying(),
      super(size: Vector2.all(GameConfig.ancestor.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    _originalPosition = startPosition.clone();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final ancestorPaint = Paint()..color = const Color(0xFFFFD700); // Gold
    final floatEffect = math.sin(_floatTimer * 2) * 0.3 + 1.0;
    
    // Divine aura
    canvas.drawCircle(
      Offset.zero,
      (size.x / 2 + 10) * floatEffect,
      Paint()..color = ancestorPaint.color.withOpacity(0.15)
    );
    
    // Outer ring
    canvas.drawCircle(Offset.zero, size.x / 2, 
        Paint()
          ..color = ancestorPaint.color.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    
    // Inner core
    canvas.drawCircle(Offset.zero, size.x / 3, ancestorPaint);
    
    // Sacred symbols
    final symbolPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(0, -size.y/4), 3, symbolPaint);
    canvas.drawCircle(Offset(-size.x/4, size.y/6), 3, symbolPaint);
    canvas.drawCircle(Offset(size.x/4, size.y/6), 3, symbolPaint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _floatTimer += dt;
    
    // Floating motion
    final floatOffset = Vector2(0, math.sin(_floatTimer * 2) * 5);
    position = _originalPosition + floatOffset;
  }
}

// --- Hideout Component (New) ---
class Hideout extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  double _pulseTimer = 0;

  Hideout({required this.startPosition}) 
    : super(size: Vector2.all(GameConfig.hideout.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final hideoutPaint = Paint()..color = const Color(0xFF3E2723); // Dark brown
    final pulseEffect = (math.sin(_pulseTimer * 2) * 0.1 + 0.9);

    // Outer "safe zone" glow
    canvas.drawCircle(
      Offset.zero,
      size.x / 2 * pulseEffect + 10,
      Paint()..color = const Color(0xFF2E7D32).withOpacity(0.2) // Greenish glow
    );

    // Inner hideout area
    canvas.drawCircle(Offset.zero, size.x / 2, hideoutPaint);

    // Entrance mark
    final entrancePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromCenter(center: Offset(0, size.y / 4), width: size.x * 0.4, height: size.y * 0.2), entrancePaint);
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
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 200, 20), const Radius.circular(10)), bgPaint);

    // Energy bar fill
    final energyPaint = Paint()..color = energy > GameConfig.player.protectionEnergyCost 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFFF5722);
    final energyWidth = (energy / maxEnergy) * 200;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, energyWidth, 20), const Radius.circular(10)), energyPaint);

    // --- Player Life Bar (New) ---
    final lifeYOffset = 35.0; // Position below energy bar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, lifeYOffset, 200, 20), const Radius.circular(10)), bgPaint);

    final lifePaint = Paint()..color = game.player.life > (game.player.maxLife / 3) 
        ? Colors.red 
        : const Color(0xFFFF5722); // Red for life, orange if low
    final lifeWidth = (game.player.life / game.player.maxLife) * 200;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, lifeYOffset, lifeWidth, 20), const Radius.circular(10)), lifePaint);

    // Life text
    final lifeTextPainter = TextPainter(
      text: TextSpan(text: 'Life: ${game.player.life.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    lifeTextPainter.layout();
    lifeTextPainter.paint(canvas, Offset(10 + (200 - lifeTextPainter.width) / 2, lifeYOffset + 2));


    // Score and Wisdom Text
    final scoreStyle = const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
    final wisdomStyle = const TextStyle(color: Color(0xFF9C27B0), fontSize: 14, fontWeight: FontWeight.bold);
    
    final scorePainter = TextPainter(
      text: TextSpan(text: 'Score: ${game.score}', style: scoreStyle),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(canvas, const Offset(10, 60)); // Adjusted position
    
    final wisdomPainter = TextPainter(
      text: TextSpan(text: 'Wisdom: ${game.wisdom}', style: wisdomStyle),
      textDirection: TextDirection.ltr,
    );
    wisdomPainter.layout();
    wisdomPainter.paint(canvas, const Offset(10, 80)); // Adjusted position

    // Current message display
    if (game.currentMessage != null) {
      final messagePaint = Paint()..color = Colors.black.withOpacity(0.8);
      final messageRect = Rect.fromLTWH(10, game.size.y - 120, game.size.x - 20, 60);
      canvas.drawRRect(RRect.fromRectAndRadius(messageRect, const Radius.circular(8)), messagePaint);
      
      final messageStyle = const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold);
      final textPainter = TextPainter(
        text: TextSpan(text: game.currentMessage!, style: messageStyle),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: game.size.x - 40);
      textPainter.paint(canvas, Offset(20, game.size.y - 110));
    }
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
    final regular = const TextStyle(color: Colors.white70, fontSize: 11);
    final highlight = const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold);
    final wisdom = const TextStyle(color: Color(0xFF9C27B0), fontSize: 11, fontWeight: FontWeight.bold);

    add(
      TextComponent(
        text: 'WASD/Arrows: Move   |   Space: Call for Ngai\'s Protection',
        textRenderer: TextPaint(style: regular),
        position: Vector2(10, game.size.y - 70)
      )
    );
    
    add(
      TextComponent(
        text: 'Green: Thaay (Blessings)  |  Purple: Proverbs (Wisdom)  |  Gold: Ancestors',
        textRenderer: TextPaint(style: highlight),
        position: Vector2(10, game.size.y - 55)
      )
    );

    add(
      TextComponent(
        text: 'Collect Kikuyu wisdom in the sacred forest. Avoid red spirits. Use Hideouts to trap troops!',
        textRenderer: TextPaint(style: wisdom),
        position: Vector2(10, game.size.y - 40)
      )
    );
  }
}

class GameOverScreen extends PositionComponent with HasGameRef<NgaisCallGame> {
  double _fadeOpacity = 0.0;
  late Timer _fadeTimer;

  @override
  Future<void> onLoad() async {
    _fadeOpacity = 0.0;
    _fadeTimer = Timer(2.0, onTick: () { // Fade in over 2 seconds
      // No specific action needed here, just controls the fade-in duration
    });
    _fadeTimer.start();

    final titleStyle = TextStyle(fontSize: 28, color: BasicPalette.red.color, fontWeight: FontWeight.bold);
    final statsStyle = const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold);
    final wisdomStyle = const TextStyle(fontSize: 14, color: Color(0xFF9C27B0), fontWeight: FontWeight.bold);
    
    final title = 'Ngai\'s Call has Ended';
    final stats = 'Score: ${game.score}\nWisdom Collected: ${game.wisdom}';
    final instruction = '\nPress \'R\' to seek Ngai\'s guidance again';
    
    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center
    );
    titlePainter.layout();

    final statsPainter = TextPainter(
      text: TextSpan(text: stats, style: statsStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center
    );
    statsPainter.layout();

    final instructionPainter = TextPainter(
      text: TextSpan(text: instruction, style: wisdomStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center
    );
    instructionPainter.layout();

    final totalHeight = titlePainter.height + statsPainter.height + instructionPainter.height + 40;
    final maxWidth = math.max(math.max(titlePainter.width, statsPainter.width), instructionPainter.width);

    final backgroundPosition = Vector2(
      (game.size.x / 2) - (maxWidth / 2) - 30,
      (game.size.y / 2) - (totalHeight / 2) - 20,
    );
    
    // Background with forest theme
    add(
      RectangleComponent(
        position: backgroundPosition,
        size: Vector2(maxWidth + 60, totalHeight + 40),
        paint: Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xAA0D4F3C), Color(0xAA000000)],
          ).createShader(Rect.fromLTWH(0, 0, maxWidth + 60, totalHeight + 40))
      )
    );
    
    // Title
    add(TextComponent(
      text: title, 
      textRenderer: TextPaint(style: titleStyle), 
      position: Vector2((game.size.x / 2) - (titlePainter.width / 2), (game.size.y / 2) - (totalHeight / 2))
    ));
    
    // Stats
    add(TextComponent(
      text: stats, 
      textRenderer: TextPaint(style: statsStyle), 
      position: Vector2((game.size.x / 2) - (statsPainter.width / 2), (game.size.y / 2) - (totalHeight / 2) + titlePainter.height + 20)
    ));
    
    // Instruction
    add(TextComponent(
      text: instruction, 
      textRenderer: TextPaint(style: wisdomStyle), 
      position: Vector2((game.size.x / 2) - (instructionPainter.width / 2), (game.size.y / 2) - (totalHeight / 2) + titlePainter.height + statsPainter.height + 30)
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fadeTimer.update(dt);
    _fadeOpacity = (_fadeTimer.progress).clamp(0.0, 1.0); // Fade in effect
  }

  @override
  void render(Canvas canvas) {
    // Apply fade effect to the entire screen
    final fadePaint = Paint()
      ..color = Colors.black.withOpacity(_fadeOpacity * 0.7); // Adjust opacity for desired darkness
    canvas.drawRect(Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y), fadePaint);

    // Render child components (text, background) after the fade layer
    super.render(canvas);
  }
}

// --- Splash Screen Component (New) ---
class SplashScreen extends PositionComponent with HasGameRef<NgaisCallGame> {
  double _pulseTimer = 0;

  @override
  Future<void> onLoad() async {
    // Semi-transparent background
    add(
      RectangleComponent(
        size: gameRef.size,
        paint: Paint()..color = const Color(0xFF0D4F3C).withOpacity(0.8), // Dark forest green
      )
    );

    // Title text
    add(
      TextComponent(
        text: 'Ngai\'s Call',
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 48,
            color: const Color(0xFFFFD700), // Gold
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(5.0, 5.0),
              ),
            ],
          ),
        ),
        anchor: Anchor.center,
        position: gameRef.size / 2 - Vector2(0, 50),
      )
    );

    // Instruction text
    add(
      TextComponent(
        text: 'Press any key to begin...',
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
        anchor: Anchor.center,
        position: gameRef.size / 2 + Vector2(0, 50),
      )
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
    // Simple pulsing effect for the title (optional, but adds drama)
    final textComponent = children.whereType<TextComponent>().first; // Assuming title is the first TextComponent
    if (textComponent.text == 'Ngai\'s Call') {
      textComponent.textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 48 + (math.sin(_pulseTimer * 3) * 2), // Pulse effect
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(5.0, 5.0),
            ),
          ],
        ),
      );
    }
  }
}