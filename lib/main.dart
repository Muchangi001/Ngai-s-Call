import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.setPortrait();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: NgaisCallGame(),
        overlayBuilderMap: {
          'mobileControls': (context, game) => MobileControlsOverlay(game: game as NgaisCallGame),
          'restartButton': (context, game) => RestartButtonOverlay(game: game as NgaisCallGame),
        },
      ),
    ),
  );
}

class GameConfig {
  static final player = _PlayerConfig();
  static final enemy = _EnemyConfig();
  static final blessing = _BlessingConfig();
  static final proverb = _ProverbConfig();
  static final ancestor = _AncestorConfig();
  static final game = _GameConfig();
  static final hideout = _HideoutConfig();
  static final touchControls = _TouchControlsConfig();
}

class _PlayerConfig {
  final double speed = 250.0;
  final double size = 15.0;
  final double protectionDuration = 3.0;
  final double protectionEnergyCost = 30.0;
  final double protectionCooldown = 2.0;
}

class _EnemyConfig {
  final double speed = 90.0;
  final double size = 12.0;
  final double spawnInterval = 1.8;
  final int scoreOnDestroy = 10;
  final double energyOnDestroy = 5.0;
  final double detectionRadius = 180.0;
  final double wanderingSpeed = 40.0;
  final int maxEnemies = 15;
}

class _BlessingConfig {
  final double size = 10.0;
  final double spawnInterval = 5.0;
  final int scoreOnCollect = 5;
  final double energyOnCollect = 20.0;
  final int maxBlessings = 5;
}

class _ProverbConfig {
  final double size = 8.0;
  final double spawnInterval = 12.0;
  final int scoreOnCollect = 25;
  final int wisdomOnCollect = 1;
  final double energyOnCollect = 15.0;
  final int maxProverbs = 3;
}

class _AncestorConfig {
  final double size = 20.0;
  final double spawnInterval = 25.0;
  final int scoreOnCollect = 50;
  final double energyOnCollect = 40.0;
  final double blessingDuration = 8.0;
  final int maxAncestors = 1;
}

class _GameConfig {
  final double initialEnergy = 50.0;
  final double maxEnergy = 100.0;
  final int initialEnemyCount = 3;
  final double initialLife = 100.0;
  final double maxLife = 100.0;
  final double lifeDrainRate = 15.0;
  final int hideoutTrapScore = 50;
  final double hideoutTrapEnergy = 15.0;
  final double hideoutTrapRadius = 150.0;
  final double messageDuration = 3.0;
  final double gameStartDelay = 1.5;
}

class _HideoutConfig {
  final double size = 70.0;
  final double spawnInterval = 30.0;
  final int maxHideouts = 1;
}

class _TouchControlsConfig {
  final double joystickSize = 120.0;
  final double joystickKnobSize = 40.0;
  final double buttonSize = 70.0;
  final double buttonMargin = 20.0;
  final double opacity = 0.6;
}

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
    "Gikeno kia njohi - Joy comes from unity",
  ];

  static final List<String> ancestorSayings = [
    "Ngai watches over the faithful",
    "The ancestors guide your path",
    "Wisdom flows like the sacred river",
    "Mount Kenya stands eternal",
    "The fig tree shelters all who seek",
    "Sacred groves hold ancient power",
  ];

  static String getRandomProverb() => proverbs[math.Random().nextInt(proverbs.length)];
  static String getRandomAncestorSaying() => ancestorSayings[math.Random().nextInt(ancestorSayings.length)];
}

enum GameState { playing, paused, gameOver }

class NgaisCallGame extends FlameGame with HasCollisionDetection {
  GameState state = GameState.playing;

  late Player player;
  late SpiritualEnergyBar ui;
  late ForestBackground forest;

  late Timer _enemySpawnTimer;
  late Timer _blessingSpawnTimer;
  late Timer _proverbSpawnTimer;
  late Timer _ancestorSpawnTimer;
  late Timer _hideoutSpawnTimer;

  int score = 0;
  int wisdom = 0;
  String? currentMessage;
  double messageTimer = 0;
  bool protectionOnCooldown = false;
  double protectionCooldownTimer = 0;

  Vector2 joystickDelta = Vector2.zero();
  bool protectionButtonPressed = false;

  @override
  Future<void> onLoad() async {
    forest = ForestBackground();
    add(forest);

    _enemySpawnTimer = Timer(
      GameConfig.enemy.spawnInterval,
      onTick: spawnEnemy,
      repeat: true,
    );
    _blessingSpawnTimer = Timer(
      GameConfig.blessing.spawnInterval,
      onTick: spawnBlessing,
      repeat: true,
    );
    _proverbSpawnTimer = Timer(
      GameConfig.proverb.spawnInterval,
      onTick: spawnProverb,
      repeat: true,
    );
    _ancestorSpawnTimer = Timer(
      GameConfig.ancestor.spawnInterval,
      onTick: spawnAncestor,
      repeat: true,
    );
    _hideoutSpawnTimer = Timer(
      GameConfig.hideout.spawnInterval,
      onTick: spawnHideout,
      repeat: true,
    );

    if (!kIsWeb) {
      overlays.add('mobileControls');
    }

    player = Player();
    add(player);

    ui = SpiritualEnergyBar();
    add(ui);

    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }

    add(InstructionsText());
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
      _enemySpawnTimer.pause();
      _blessingSpawnTimer.pause();
      _proverbSpawnTimer.pause();
      _ancestorSpawnTimer.pause();
      _hideoutSpawnTimer.pause();
    } else if (state == GameState.paused) {
      state = GameState.playing;
      _enemySpawnTimer.resume();
      _blessingSpawnTimer.resume();
      _proverbSpawnTimer.resume();
      _ancestorSpawnTimer.resume();
      _hideoutSpawnTimer.resume();
    }
  }

  void _startSpawning() {
    _enemySpawnTimer.start();
    _blessingSpawnTimer.start();
    _proverbSpawnTimer.start();
    _ancestorSpawnTimer.start();
    _hideoutSpawnTimer.start();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (state == GameState.paused) {
      final paint = Paint()..color = Colors.black.withOpacity(0.5);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
      
      final text = TextSpan(
        text: 'PAUSED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: text,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    }
  }

  void spawnEnemy() {
    if (children.whereType<Enemy>().length >= GameConfig.enemy.maxEnemies) return;

    final edge = math.Random().nextInt(4);
    Vector2 position;

    switch (edge) {
      case 0: position = Vector2(math.Random().nextDouble() * size.x, 0); break;
      case 1: position = Vector2(size.x, math.Random().nextDouble() * size.y); break;
      case 2: position = Vector2(math.Random().nextDouble() * size.x, size.y); break;
      default: position = Vector2(0, math.Random().nextDouble() * size.y); break;
    }
    add(Enemy(startPosition: position));
  }

  void spawnBlessing() {
    if (children.whereType<Blessing>().length >= GameConfig.blessing.maxBlessings) return;
    add(Blessing(
      startPosition: Vector2(
        math.Random().nextDouble() * size.x,
        math.Random().nextDouble() * size.y,
      ),
    ));
  }

  void spawnProverb() {
    if (children.whereType<KikuyuProverb>().length >= GameConfig.proverb.maxProverbs) return;
    add(KikuyuProverb(
      startPosition: Vector2(
        math.Random().nextDouble() * size.x,
        math.Random().nextDouble() * size.y,
      ),
    ));
  }

  void spawnAncestor() {
    if (children.whereType<AncestorSpirit>().length >= GameConfig.ancestor.maxAncestors) return;
    add(AncestorSpirit(
      startPosition: Vector2(
        math.Random().nextDouble() * size.x,
        math.Random().nextDouble() * size.y,
      ),
    ));
  }

  void spawnHideout() {
    if (children.whereType<Hideout>().length >= GameConfig.hideout.maxHideouts) return;
    children.whereType<Hideout>().forEach((h) => h.removeFromParent());
    add(Hideout(
      startPosition: Vector2(
        math.Random().nextDouble() * size.x,
        math.Random().nextDouble() * size.y,
      ),
    ));
  }

  void trapEnemiesInHideout(Hideout hideout) {
    int trappedCount = 0;
    final enemiesToRemove = <Enemy>[];

    for (var component in children) {
      if (component is Enemy && component.position.distanceTo(hideout.position) < GameConfig.game.hideoutTrapRadius) {
        enemiesToRemove.add(component);
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
    messageTimer = GameConfig.game.messageDuration;
  }

  void activateProtectionFromButton() {
    if (!protectionOnCooldown && ui.canUseEnergy(GameConfig.player.protectionEnergyCost)) {
      player.activateProtection();
      ui.useEnergy(GameConfig.player.protectionEnergyCost);
      protectionOnCooldown = true;
      protectionCooldownTimer = GameConfig.player.protectionCooldown;
    }
  }

  @override
  void update(double dt) {
    if (state == GameState.paused) return;
    super.update(dt);

    if (state == GameState.playing) {
      _enemySpawnTimer.update(dt);
      _blessingSpawnTimer.update(dt);
      _proverbSpawnTimer.update(dt);
      _ancestorSpawnTimer.update(dt);
      _hideoutSpawnTimer.update(dt);

      if (protectionOnCooldown) {
        protectionCooldownTimer -= dt;
        if (protectionCooldownTimer <= 0) {
          protectionOnCooldown = false;
        }
      }

      if (!kIsWeb && joystickDelta != Vector2.zero()) {
        player.handleJoystickMovement(joystickDelta);
      }

      if (!kIsWeb && protectionButtonPressed) {
        activateProtectionFromButton();
      }
    }

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
    _hideoutSpawnTimer.stop();
    
    if (!kIsWeb) {
      overlays.remove('mobileControls');
      overlays.add('restartButton');
    }
  }

  void resetGame() {
    if (!kIsWeb) {
      overlays.remove('restartButton');
      overlays.add('mobileControls');
    }

    score = 0;
    wisdom = 0;
    currentMessage = null;
    messageTimer = 0;
    protectionOnCooldown = false;
    protectionCooldownTimer = 0;

    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    children.whereType<Blessing>().forEach((b) => b.removeFromParent());
    children.whereType<KikuyuProverb>().forEach((p) => p.removeFromParent());
    children.whereType<AncestorSpirit>().forEach((a) => a.removeFromParent());
    children.whereType<Hideout>().forEach((h) => h.removeFromParent());
    children.whereType<InstructionsText>().forEach((i) => i.removeFromParent());
    children.whereType<SpiritualEnergyBar>().forEach((u) => u.removeFromParent());
    children.whereType<Player>().forEach((p) => p.removeFromParent());

    player = Player();
    add(player);

    ui = SpiritualEnergyBar();
    add(ui);

    add(InstructionsText());

    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }

    state = GameState.playing;
  }
}

class MobileControlsOverlay extends StatelessWidget {
  final NgaisCallGame game;

  const MobileControlsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: GameConfig.touchControls.buttonMargin,
          bottom: GameConfig.touchControls.buttonMargin,
          child: JoystickArea(
            game: game,
            size: GameConfig.touchControls.joystickSize,
            knobSize: GameConfig.touchControls.joystickKnobSize,
          ),
        ),
        Positioned(
          right: GameConfig.touchControls.buttonMargin,
          bottom: GameConfig.touchControls.buttonMargin,
          child: ProtectionButton(
            game: game,
            size: GameConfig.touchControls.buttonSize,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: PauseButton(game: game),
        ),
      ],
    );
  }
}

class PauseButton extends StatelessWidget {
  final NgaisCallGame game;

  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => game.togglePause(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          game.state == GameState.paused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class RestartButtonOverlay extends StatelessWidget {
  final NgaisCallGame game;

  const RestartButtonOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: game.resetGame,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: const Text(
            'RESTART GAME',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class JoystickArea extends StatefulWidget {
  final NgaisCallGame game;
  final double size;
  final double knobSize;

  const JoystickArea({
    super.key,
    required this.game,
    required this.size,
    required this.knobSize,
  });

  @override
  _JoystickAreaState createState() => _JoystickAreaState();
}

class _JoystickAreaState extends State<JoystickArea> {
  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _updateKnobPosition(details.localPosition);
        });
      },
      onPanUpdate: (details) => _updateKnobPosition(details.localPosition),
      onPanEnd: (details) => _resetKnob(),
      onPanCancel: () => _resetKnob(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(GameConfig.touchControls.opacity),
        ),
        child: Stack(
          children: [
            Positioned(
              left: (widget.size / 2) - (widget.knobSize / 2) + _knobPosition.dx,
              top: (widget.size / 2) - (widget.knobSize / 2) + _knobPosition.dy,
              child: Container(
                width: widget.knobSize,
                height: widget.knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_isDragging ? 0.9 : 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateKnobPosition(Offset localPosition) {
    final center = widget.size / 2;
    final dx = (localPosition.dx - center).clamp(-center, center);
    final dy = (localPosition.dy - center).clamp(-center, center);

    setState(() => _knobPosition = Offset(dx, dy));
    widget.game.joystickDelta = Vector2(dx / center, dy / center);
  }

  void _resetKnob() {
    setState(() {
      _knobPosition = Offset.zero;
      _isDragging = false;
    });
    widget.game.joystickDelta = Vector2.zero();
  }
}

class ProtectionButton extends StatefulWidget {
  final NgaisCallGame game;
  final double size;

  const ProtectionButton({super.key, required this.game, required this.size});

  @override
  _ProtectionButtonState createState() => _ProtectionButtonState();
}

class _ProtectionButtonState extends State<ProtectionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() => _isPressed = true);
        widget.game.protectionButtonPressed = true;
      },
      onTapUp: (details) {
        setState(() => _isPressed = false);
        widget.game.protectionButtonPressed = false;
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.game.protectionButtonPressed = false;
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? Colors.amber.withOpacity(0.9)
              : Colors.black.withOpacity(GameConfig.touchControls.opacity),
          border: Border.all(color: Colors.amber, width: 2.0),
        ),
        child: const Center(
          child: Text(
            'PROTECT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class ForestBackground extends Component with HasGameRef<NgaisCallGame> {
  final List<TreeSprite> trees = [];
  final List<SacredGrove> groves = [];

  @override
  Future<void> onLoad() async {
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
    final rect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    for (final grove in groves) grove.render(canvas);
    for (final tree in trees) tree.render(canvas);
  }
}

class TreeSprite {
  final Vector2 position;
  final double size;

  TreeSprite({required this.position, required this.size});

  void render(Canvas canvas) {
    final trunkPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(position.x, position.y + size * 0.3),
        width: size * 0.2,
        height: size * 0.6,
      ),
      trunkPaint,
    );

    final canopyPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(
      Offset(position.x, position.y - size * 0.2),
      size * 0.4,
      canopyPaint,
    );

    final lightFoliage = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(position.x - size * 0.1, position.y - size * 0.3), size * 0.15, lightFoliage);
    canvas.drawCircle(Offset(position.x + size * 0.1, position.y - size * 0.1), size * 0.12, lightFoliage);
  }
}

class SacredGrove {
  final Vector2 position;

  SacredGrove({required this.position});

  void render(Canvas canvas) {
    final grovePaint = Paint()..color = const Color(0xFF1B5E20).withOpacity(0.3);
    canvas.drawCircle(Offset(position.x, position.y), 60, grovePaint);

    final sacredPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(position.x, position.y), 50, sacredPaint);
  }
}

class Player extends PositionComponent with CollisionCallbacks {
  bool isProtected = false;
  bool hasAncestorBlessing = false;
  bool isHitByEnemy = false;
  bool isInHideout = false;

  late Timer _protectionTimer;
  late Timer _ancestorBlessingTimer;
  Vector2 _moveDirection = Vector2.zero();

  double life = GameConfig.game.initialLife;
  final double maxLife = GameConfig.game.maxLife;

  Player() : super(size: Vector2.all(GameConfig.player.size * 2), anchor: Anchor.center) {
    _protectionTimer = Timer(GameConfig.player.protectionDuration, onTick: () => isProtected = false);
    _ancestorBlessingTimer = Timer(GameConfig.ancestor.blessingDuration, onTick: () => hasAncestorBlessing = false);
  }

  @override
  Future<void> onLoad() async {
    reset();
    add(CircleHitbox());
  }

  void reset() {
    final gameRef = findGame();
    if (gameRef != null) position = gameRef.size / 2;
    life = GameConfig.game.initialLife;
    isProtected = false;
    hasAncestorBlessing = false;
    isHitByEnemy = false;
    isInHideout = false;
    _protectionTimer.stop();
    _ancestorBlessingTimer.stop();
  }

  @override
  void render(Canvas canvas) {
    Color baseColor = const Color(0xFF03A9F4);
    if (hasAncestorBlessing) baseColor = const Color(0xFFFFD700);
    if (isProtected) baseColor = const Color(0xFFFFC107);
    if (isHitByEnemy) baseColor = Colors.red;

    final paint = Paint()..color = baseColor;
    final glowOpacity = (isProtected || hasAncestorBlessing) ? 0.6 : 0.3;

    if (hasAncestorBlessing) {
      canvas.drawCircle(Offset.zero, size.x / 2 + 8, Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));
    }

    canvas.drawCircle(Offset.zero, size.x / 2 + 3, Paint()..color = paint.color.withOpacity(glowOpacity));
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    canvas.drawCircle(Offset.zero, size.x / 3, Paint()..color = Colors.white.withOpacity(0.7));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isProtected) _protectionTimer.update(dt);
    if (hasAncestorBlessing) _ancestorBlessingTimer.update(dt);

    if (isHitByEnemy && !isProtected && !hasAncestorBlessing) {
      life = (life - GameConfig.game.lifeDrainRate * dt).clamp(0, maxLife);
      if (life <= 0) {
        (findGame() as NgaisCallGame).onGameOver();
      }
    }

    final speed = hasAncestorBlessing ? GameConfig.player.speed * 1.5 : GameConfig.player.speed;
    position += _moveDirection.normalized() * speed * dt;

    final gameRef = findGame();
    if (gameRef != null) {
      position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
      position.y = position.y.clamp(size.y / 2, gameRef.size.y - size.y / 2);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    final gameRef = findGame() as NgaisCallGame?;
    if (gameRef == null) return;

    if (other is Enemy) {
      if (isProtected || hasAncestorBlessing) {
        other.removeFromParent();
        gameRef.score += GameConfig.enemy.scoreOnDestroy;
        gameRef.ui.addEnergy(GameConfig.enemy.energyOnDestroy);
        if (hasAncestorBlessing) gameRef.score += GameConfig.enemy.scoreOnDestroy;
      } else {
        isHitByEnemy = true;
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
      gameRef.showMessage((other as KikuyuProverb).proverb);
    } else if (other is AncestorSpirit) {
      other.removeFromParent();
      gameRef.score += GameConfig.ancestor.scoreOnCollect;
      gameRef.ui.addEnergy(GameConfig.ancestor.energyOnCollect);
      activateAncestorBlessing();
      gameRef.showMessage((other as AncestorSpirit).saying);
    } else if (other is Hideout) {
      isInHideout = true;
      gameRef.trapEnemiesInHideout(other as Hideout);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Enemy) isHitByEnemy = false;
    if (other is Hideout) isInHideout = false;
  }

  void handleJoystickMovement(Vector2 direction) {
    _moveDirection = direction;
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

class Enemy extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  Vector2 _currentWaypoint = Vector2.zero();
  final math.Random _random = math.Random();

  Enemy({required this.startPosition}) : super(size: Vector2.all(GameConfig.enemy.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
    _pickNewWaypoint();
  }

  void _pickNewWaypoint() {
    _currentWaypoint = Vector2(
      _random.nextDouble() * game.size.x,
      _random.nextDouble() * game.size.y,
    );
  }

  @override
  void render(Canvas canvas) {
    final enemyPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(Offset.zero, size.x / 2 + 4, Paint()..color = enemyPaint.color.withOpacity(0.4));
    canvas.drawCircle(Offset.zero, size.x / 2, enemyPaint);
    canvas.drawCircle(Offset.zero, size.x / 4, Paint()..color = const Color(0xFF8B0000));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    final playerPosition = game.player.position;
    final distanceToPlayer = position.distanceTo(playerPosition);

    if (distanceToPlayer < GameConfig.enemy.detectionRadius) {
      final direction = (playerPosition - position).normalized();
      position += direction * GameConfig.enemy.speed * dt;
    } else {
      if (position.distanceTo(_currentWaypoint) < 5) _pickNewWaypoint();
      final direction = (_currentWaypoint - position).normalized();
      position += direction * GameConfig.enemy.wanderingSpeed * dt;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Hideout) removeFromParent();
  }
}

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
    final blessingPaint = Paint()..color = const Color(0xFF4CAF50);
    final pulseEffect = (math.sin(_pulseTimer * 4) * 0.2 + 1.0);

    canvas.drawCircle(Offset.zero, (size.x / 2) * pulseEffect + 3, Paint()..color = blessingPaint.color.withOpacity(0.3 * pulseEffect));
    canvas.drawCircle(Offset.zero, size.x / 2, blessingPaint);
    canvas.drawCircle(Offset.zero, size.x / 3, Paint()..color = const Color(0xFF81C784));
  }

  @override
  void update(double dt) => _pulseTimer += dt;
}

class KikuyuProverb extends PositionComponent {
  final Vector2 startPosition;
  final String proverb = KikuyuWisdom.getRandomProverb();
  double _glowTimer = 0;

  KikuyuProverb({required this.startPosition}) : super(size: Vector2.all(GameConfig.proverb.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final proverbPaint = Paint()..color = const Color(0xFF9C27B0);
    final glowEffect = (math.sin(_glowTimer * 3) * 0.3 + 0.7);

    canvas.drawCircle(Offset.zero, size.x / 2 + 6, Paint()..color = proverbPaint.color.withOpacity(0.2 * glowEffect));
    canvas.drawCircle(Offset.zero, size.x / 2, proverbPaint);

    final symbolPaint = Paint()..color = const Color(0xFFE1BEE7);
    canvas.drawCircle(Offset(-size.x / 4, -size.y / 4), 2, symbolPaint);
    canvas.drawCircle(Offset(size.x / 4, -size.y / 4), 2, symbolPaint);
    canvas.drawCircle(Offset(0, size.y / 4), 2, symbolPaint);
  }

  @override
  void update(double dt) => _glowTimer += dt;
}

class AncestorSpirit extends PositionComponent {
  final Vector2 startPosition;
  final String saying = KikuyuWisdom.getRandomAncestorSaying();
  double _floatTimer = 0;
  late Vector2 _originalPosition;

  AncestorSpirit({required this.startPosition}) : super(size: Vector2.all(GameConfig.ancestor.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    _originalPosition = startPosition.clone();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final ancestorPaint = Paint()..color = const Color(0xFFFFD700);
    final floatEffect = math.sin(_floatTimer * 2) * 0.3 + 1.0;

    canvas.drawCircle(Offset.zero, (size.x / 2 + 10) * floatEffect, Paint()..color = ancestorPaint.color.withOpacity(0.15));
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()
      ..color = ancestorPaint.color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset.zero, size.x / 3, ancestorPaint);

    final symbolPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(0, -size.y / 4), 3, symbolPaint);
    canvas.drawCircle(Offset(-size.x / 4, size.y / 6), 3, symbolPaint);
    canvas.drawCircle(Offset(size.x / 4, size.y / 6), 3, symbolPaint);
  }

  @override
  void update(double dt) {
    _floatTimer += dt;
    final floatOffset = Vector2(0, math.sin(_floatTimer * 2) * 5);
    position = _originalPosition + floatOffset;
  }
}

class Hideout extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  double _pulseTimer = 0;

  Hideout({required this.startPosition}) : super(size: Vector2.all(GameConfig.hideout.size * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final hideoutPaint = Paint()..color = const Color(0xFF3E2723);
    final pulseEffect = (math.sin(_pulseTimer * 2) * 0.1 + 0.9);

    canvas.drawCircle(Offset.zero, size.x / 2 * pulseEffect + 10, Paint()..color = const Color(0xFF2E7D32).withOpacity(0.2));
    canvas.drawCircle(Offset.zero, size.x / 2, hideoutPaint);

    final entrancePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, size.y / 4), width: size.x * 0.4, height: size.y * 0.2),
      entrancePaint,
    );
  }

  @override
  void update(double dt) => _pulseTimer += dt;
}

class SpiritualEnergyBar extends PositionComponent with HasGameRef<NgaisCallGame> {
  double energy = GameConfig.game.initialEnergy;
  final double maxEnergy = GameConfig.game.maxEnergy;

  void addEnergy(double amount) => energy = (energy + amount).clamp(0, maxEnergy);
  void useEnergy(double amount) => energy = (energy - amount).clamp(0, maxEnergy);
  bool canUseEnergy(double amount) => energy >= amount;

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 200, 20), const Radius.circular(10)), bgPaint);

    final energyPaint = Paint()
      ..color = energy > GameConfig.player.protectionEnergyCost ? const Color(0xFF4CAF50) : const Color(0xFFFF5722);
    final energyWidth = (energy / maxEnergy) * 200;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, energyWidth, 20), const Radius.circular(10)), energyPaint);

    final lifeYOffset = 35.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, lifeYOffset, 200, 20), const Radius.circular(10)), bgPaint);

    final lifePaint = Paint()
      ..color = game.player.life > (game.player.maxLife / 3) ? Colors.red : const Color(0xFFFF5722);
    final lifeWidth = (game.player.life / game.player.maxLife) * 200;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, lifeYOffset, lifeWidth, 20), const Radius.circular(10)), lifePaint);

    final lifeTextPainter = TextPainter(
      text: TextSpan(text: 'Life: ${game.player.life.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    lifeTextPainter.layout();
    lifeTextPainter.paint(canvas, Offset(10 + (200 - lifeTextPainter.width) / 2, lifeYOffset + 2));

    final scorePainter = TextPainter(
      text: TextSpan(text: 'Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(canvas, const Offset(10, 60));

    final wisdomPainter = TextPainter(
      text: TextSpan(text: 'Wisdom: ${game.wisdom}', style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    wisdomPainter.layout();
    wisdomPainter.paint(canvas, const Offset(10, 80));

    if (game.currentMessage != null) {
      final messagePaint = Paint()..color = Colors.black.withOpacity(0.8);
      final messageRect = Rect.fromLTWH(10, game.size.y - 120, game.size.x - 20, 60);
      canvas.drawRRect(RRect.fromRectAndRadius(messageRect, const Radius.circular(8)), messagePaint);

      final textPainter = TextPainter(
        text: TextSpan(text: game.currentMessage!, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: game.size.x - 40);
      textPainter.paint(canvas, Offset(20, game.size.y - 110));
    }

    if (game.protectionOnCooldown) {
      final cooldownText = TextPainter(
        text: TextSpan(
          text: 'Protection Cooldown: ${game.protectionCooldownTimer.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      cooldownText.layout();
      cooldownText.paint(canvas, Offset(game.size.x - cooldownText.width - 10, 10));
    }
  }
}

class InstructionsText extends PositionComponent with HasGameRef<NgaisCallGame> {
  @override
  Future<void> onLoad() async {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, offset: Offset(1, 1)),
        Shadow(color: Colors.black, offset: Offset(-1, -1))
      ],
    );

    add(TextComponent(
      text: 'Collect Blessings(green), Proverbs(purple), Ancestors(gold)',
      textRenderer: TextPaint(style: textStyle),
      position: Vector2(game.size.x / 2, game.size.y - GameConfig.touchControls.joystickSize - 50),
      anchor: Anchor.topCenter,
    ));

    add(TextComponent(
      text: 'Avoid red spirits. Use Hideouts(brown) to trap enemies!',
      textRenderer: TextPaint(style: textStyle),
      position: Vector2(game.size.x / 2, game.size.y - GameConfig.touchControls.joystickSize - 35),
      anchor: Anchor.topCenter,
    ));

    add(TextComponent(
      text: 'PROTECT button (right) uses energy for temporary shield',
      textRenderer: TextPaint(style: textStyle),
      position: Vector2(game.size.x / 2, game.size.y - GameConfig.touchControls.joystickSize - 20),
      anchor: Anchor.topCenter,
    ));
  }
}