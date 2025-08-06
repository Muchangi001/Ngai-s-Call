import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flame/geometry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  Flame.device.setLandscape();
  Flame.device.fullScreen();
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: NgaisCallGame(),
        overlayBuilderMap: {
          'mobileControls':
              (context, game) => MobileControlsOverlay(game: game as NgaisCallGame),
          'restartButton':
              (context, game) => RestartButtonOverlay(game: game as NgaisCallGame),
          'wisdomMessage':
              (context, game) => WisdomMessageOverlay(game: game as NgaisCallGame),
        },
      ),
    ),
  );
}

// GameConfig and KikuyuWisdom classes remain unchanged
class GameConfig {
  static final player = _PlayerConfig();
  static final enemy = _EnemyConfig();
  static final blessing = _BlessingConfig();
  static final proverb = _ProverbConfig();
  static final ancestor = _AncestorConfig();
  static final game = _GameConfig();
  static final hideout = _HideoutConfig();
  static final touchControls = _TouchControlsConfig();
  static final powerUp = _PowerUpConfig();
  static final artifact = _ArtifactConfig();
}

class _PlayerConfig {
  final double speed = 180.0;
  final double size = 15.0;
  final double protectionDuration = 3.0;
  final double protectionEnergyCost = 30.0;
  final double protectionCooldown = 2.0;
  final double deathSkidDuration = 1.5;
}

class _EnemyConfig {
  final double speed = 70.0;
  final double size = 12.0;
  final double spawnInterval = 2.2;
  final int scoreOnDestroy = 10;
  final double energyOnDestroy = 5.0;
  final double detectionRadius = 120.0;
  final double wanderingSpeed = 30.0;
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
  final double messageDuration = 4.0;
}

class _AncestorConfig {
  final double size = 20.0;
  final double spawnInterval = 25.0;
  final int scoreOnCollect = 50;
  final double energyOnCollect = 40.0;
  final double blessingDuration = 8.0;
  final int maxAncestors = 1;
  final double messageDuration = 5.0;
}

class _GameConfig {
  final double initialEnergy = 50.0;
  final double maxEnergy = 100.0;
  final int initialEnemyCount = 3;
  final double initialLife = 100.0;
  final double maxLife = 100.0;
  final double lifeDrainRate = 12.0;
  final int hideoutTrapScore = 50;
  final double hideoutTrapEnergy = 15.0;
  final double hideoutTrapRadius = 150.0;
  final double messageDuration = 3.0;
  final double gameStartDelay = 1.5;
  final double mapExtensionWidth = 800.0;
}

class _HideoutConfig {
  final double size = 70.0;
  final double spawnInterval = 30.0;
  final int maxHideouts = 1;
}

class _TouchControlsConfig {
  final double joystickSize = 100.0;
  final double joystickKnobSize = 35.0;
  final double buttonSize = 60.0;
  final double buttonMargin = 15.0;
  final double opacity = 0.6;
  final double deadZone = 0.2;
}

class _PowerUpConfig {
  final double size = 12.0;
  final double spawnInterval = 15.0;
  final double duration = 10.0;
  final int maxPowerUps = 3;
  final double speedBoostMultiplier = 1.5;
  final double energyRegenRate = 5.0;
}

class _ArtifactConfig {
  final double size = 10.0;
  final double spawnInterval = 20.0;
  final int maxArtifacts = 2;
  final double scoreMultiplierDuration = 15.0;
  final double scoreMultiplier = 2.0;
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
    "Listen to the whispers of the wind",
    "The lion's strength comes from the pride",
    "A single stick breaks, but many are strong",
    "The wise man learns from the mistakes of others",
  ];

  static final List<String> artifactNames = [
    "Mau Mau Spear",
    "Kikuyu Drum",
    "Sacred Beads",
    "Warrior Shield",
  ];

  static String getRandomProverb() =>
      proverbs[math.Random().nextInt(proverbs.length)];
  static String getRandomAncestorSaying() =>
      ancestorSayings[math.Random().nextInt(ancestorSayings.length)];
  static String getRandomArtifactName() =>
      artifactNames[math.Random().nextInt(artifactNames.length)];
}

enum GameState { playing, paused, gameOver }

class NgaisCallGame extends FlameGame with HasCollisionDetection {
  GameState state = GameState.playing;

  late Player player;
  late SpiritualEnergyBar ui;
  late ForestBackground forest;
  late MiniMap miniMap;

  late Timer _enemySpawnTimer;
  late Timer _blessingSpawnTimer;
  late Timer _proverbSpawnTimer;
  late Timer _ancestorSpawnTimer;
  late Timer _hideoutSpawnTimer;
  late Timer _powerUpSpawnTimer;
  late Timer _artifactSpawnTimer;

  int score = 0;
  int wisdom = 0;
  String? currentMessage;
  double messageTimer = 0;
  bool protectionOnCooldown = false;
  double protectionCooldownTimer = 0;

  String? wisdomMessage;
  double wisdomMessageTimer = 0;

  Vector2 joystickDelta = Vector2.zero();
  bool protectionButtonPressed = false;
  double scoreMultiplier = 1.0;
  double scoreMultiplierTimer = 0.0;

  late Vector2 mapSize;

  @override
  Future<void> onLoad() async {
    // Wait for device to be ready and get actual screen size
    await Future.delayed(Duration(milliseconds: 100));
    
    // Get the actual device screen size for landscape
    mapSize = size.clone();
    
    // Ensure we have reasonable minimum size for landscape
    if (mapSize.x < mapSize.y) {
      // If somehow we're in portrait, swap dimensions
      final temp = mapSize.x;
      mapSize.x = mapSize.y;
      mapSize.y = temp;
    }

    // Initialize world
    world = World();
    await add(world);

    // Set up the camera to fill the entire screen
    camera = CameraComponent.withFixedResolution(
      width: mapSize.x,
      height: mapSize.y,
      world: world,
    );
    camera.viewfinder.anchor = Anchor.center;
    await add(camera);

    // Set initial camera bounds
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, mapSize.x, mapSize.y),
    );

    // Initialize and add components to the world
    forest = ForestBackground();
    await world.add(forest);

    player = Player();
    await world.add(player);

    // Add HUD components - these stay fixed on screen
    ui = SpiritualEnergyBar();
    await add(ui);

    miniMap = MiniMap();
    await add(miniMap);

    await world.add(InstructionsText());

    // Initialize timers
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
    _powerUpSpawnTimer = Timer(
      GameConfig.powerUp.spawnInterval,
      onTick: spawnPowerUp,
      repeat: true,
    );
    _artifactSpawnTimer = Timer(
      GameConfig.artifact.spawnInterval,
      onTick: spawnArtifact,
      repeat: true,
    );

    if (!kIsWeb) {
      overlays.add('mobileControls');
    }

    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }

    // Make camera follow the player
    camera.follow(player);
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
      _pauseTimers();
    } else if (state == GameState.paused) {
      state = GameState.playing;
      _resumeTimers();
    }
  }

  void _pauseTimers() {
    _enemySpawnTimer.pause();
    _blessingSpawnTimer.pause();
    _proverbSpawnTimer.pause();
    _ancestorSpawnTimer.pause();
    _hideoutSpawnTimer.pause();
    _powerUpSpawnTimer.pause();
    _artifactSpawnTimer.pause();
  }

  void _resumeTimers() {
    _enemySpawnTimer.resume();
    _blessingSpawnTimer.resume();
    _proverbSpawnTimer.resume();
    _ancestorSpawnTimer.resume();
    _hideoutSpawnTimer.resume();
    _powerUpSpawnTimer.resume();
    _artifactSpawnTimer.resume();
  }

  void _startSpawning() {
    _enemySpawnTimer.start();
    _blessingSpawnTimer.start();
    _proverbSpawnTimer.start();
    _ancestorSpawnTimer.start();
    _hideoutSpawnTimer.start();
    _powerUpSpawnTimer.start();
    _artifactSpawnTimer.start();
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
      case 0:
        position = Vector2(math.Random().nextDouble() * mapSize.x, 0);
        break;
      case 1:
        position = Vector2(mapSize.x, math.Random().nextDouble() * mapSize.y);
        break;
      case 2:
        position = Vector2(math.Random().nextDouble() * mapSize.x, mapSize.y);
        break;
      default:
        position = Vector2(0, math.Random().nextDouble() * mapSize.y);
        break;
    }
    world.add(Enemy(startPosition: position));
  }

  void spawnBlessing() {
    if (children.whereType<Blessing>().length >= GameConfig.blessing.maxBlessings) return;
    world.add(
      Blessing(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
      ),
    );
  }

  void spawnProverb() {
    if (children.whereType<KikuyuProverb>().length >= GameConfig.proverb.maxProverbs) return;
    world.add(
      KikuyuProverb(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
      ),
    );
  }

  void spawnAncestor() {
    if (children.whereType<AncestorSpirit>().length >= GameConfig.ancestor.maxAncestors) return;
    world.add(
      AncestorSpirit(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
      ),
    );
  }

  void spawnHideout() {
    if (children.whereType<Hideout>().length >= GameConfig.hideout.maxHideouts) return;
    children.whereType<Hideout>().forEach((h) => h.removeFromParent());
    world.add(
      Hideout(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
      ),
    );
  }

  void spawnPowerUp() {
    if (children.whereType<PowerUp>().length >= GameConfig.powerUp.maxPowerUps) return;
    world.add(
      PowerUp(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
        type: math.Random().nextBool() ? PowerUpType.speedBoost : PowerUpType.energyRegen,
      ),
    );
  }

  void spawnArtifact() {
    if (children.whereType<MauMauArtifact>().length >= GameConfig.artifact.maxArtifacts) return;
    world.add(
      MauMauArtifact(
        startPosition: Vector2(
          math.Random().nextDouble() * mapSize.x,
          math.Random().nextDouble() * mapSize.y,
        ),
      ),
    );
  }

  void trapEnemiesInHideout(Hideout hideout) {
    int trappedCount = 0;
    final enemiesToRemove = <Enemy>[];

    for (var component in world.children) {
      if (component is Enemy &&
          component.position.distanceTo(hideout.position) < GameConfig.game.hideoutTrapRadius) {
        enemiesToRemove.add(component);
      }
    }

    for (var enemy in enemiesToRemove) {
      enemy.removeFromParent();
      score += (GameConfig.game.hideoutTrapScore * scoreMultiplier).toInt();
      ui.addEnergy(GameConfig.game.hideoutTrapEnergy);
      trappedCount++;
      showMessage("Played sound: Ambush!");
    }

    if (trappedCount > 0) {
      showMessage("Fellow Mau Mau fighters ambushed $trappedCount troops!");
    }
  }

  void showMessage(String message) {
    currentMessage = message;
    messageTimer = GameConfig.game.messageDuration;
  }

  void showWisdomMessage(String message) {
    wisdomMessage = message;
    wisdomMessageTimer = GameConfig.proverb.messageDuration;
    if (!kIsWeb) {
      overlays.add('wisdomMessage');
      Future.delayed(
        Duration(seconds: GameConfig.proverb.messageDuration.toInt()),
        () {
          overlays.remove('wisdomMessage');
        },
      );
    }
  }

  void showAncestorMessage(String message) {
    wisdomMessage = message;
    wisdomMessageTimer = GameConfig.ancestor.messageDuration;
    if (!kIsWeb) {
      overlays.add('wisdomMessage');
      Future.delayed(
        Duration(seconds: GameConfig.ancestor.messageDuration.toInt()),
        () {
          overlays.remove('wisdomMessage');
        },
      );
    }
  }

  void activateProtectionFromButton() {
    if (!protectionOnCooldown && ui.canUseEnergy(GameConfig.player.protectionEnergyCost)) {
      player.activateProtection();
      ui.useEnergy(GameConfig.player.protectionEnergyCost);
      protectionOnCooldown = true;
      protectionCooldownTimer = GameConfig.player.protectionCooldown;
      showMessage("Played sound: Protection Activated!");
    }
  }

  void extendMap() {
    mapSize.x += GameConfig.game.mapExtensionWidth;
    forest.generateNewSection(mapSize.x - GameConfig.game.mapExtensionWidth);
    showMessage("New forest area discovered!");
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, mapSize.x, mapSize.y),
    );
  }

  double getDynamicEnemySpawnInterval() {
    return GameConfig.enemy.spawnInterval / (1 + score / 10000);
  }

  double getDynamicEnemySpeed() {
    return GameConfig.enemy.speed * (1 + score / 20000);
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
      _powerUpSpawnTimer.update(dt);
      _artifactSpawnTimer.update(dt);

      if (protectionOnCooldown) {
        protectionCooldownTimer -= dt;
        if (protectionCooldownTimer <= 0) {
          protectionOnCooldown = false;
        }
      }

      if (scoreMultiplierTimer > 0) {
        scoreMultiplierTimer -= dt;
        if (scoreMultiplierTimer <= 0) {
          scoreMultiplier = 1.0;
          showMessage("Mau Mau Artifact effect ended!");
        }
      }

      if (!kIsWeb && joystickDelta != Vector2.zero()) {
        player.handleJoystickMovement(joystickDelta);
      }

      if (!kIsWeb && protectionButtonPressed) {
        activateProtectionFromButton();
      }

      if (player.position.x > mapSize.x - 100) {
        extendMap();
      }
    }

    if (messageTimer > 0) {
      messageTimer -= dt;
      if (messageTimer <= 0) {
        currentMessage = null;
      }
    }

    if (wisdomMessageTimer > 0) {
      wisdomMessageTimer -= dt;
      if (wisdomMessageTimer <= 0) {
        wisdomMessage = null;
        if (!kIsWeb) {
          overlays.remove('wisdomMessage');
        }
      }
    }
  }

  void onGameOver() {
    state = GameState.gameOver;
    _pauseTimers();

    if (!kIsWeb) {
      overlays.remove('mobileControls');
      overlays.add('restartButton');
    }
    showMessage("Game Over! Final Score: $score");
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
    wisdomMessage = null;
    wisdomMessageTimer = 0;
    protectionOnCooldown = false;
    protectionCooldownTimer = 0;
    scoreMultiplier = 1.0;
    scoreMultiplierTimer = 0.0;
    mapSize = size.clone();

    // Clear world components
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<Blessing>().forEach((b) => b.removeFromParent());
    world.children.whereType<KikuyuProverb>().forEach((p) => p.removeFromParent());
    world.children.whereType<AncestorSpirit>().forEach((a) => a.removeFromParent());
    world.children.whereType<Hideout>().forEach((h) => h.removeFromParent());
    world.children.whereType<PowerUp>().forEach((p) => p.removeFromParent());
    world.children.whereType<MauMauArtifact>().forEach((a) => a.removeFromParent());
    world.children.whereType<ForestBackground>().forEach((f) => f.removeFromParent());
    world.children.whereType<Player>().forEach((p) => p.removeFromParent());
    world.children.whereType<InstructionsText>().forEach((i) => i.removeFromParent());

    // Clear screen-space components
    children.whereType<SpiritualEnergyBar>().forEach((u) => u.removeFromParent());
    children.whereType<MiniMap>().forEach((m) => m.removeFromParent());

    // Reinitialize components
    forest = ForestBackground();
    world.add(forest);

    player = Player();
    world.add(player);

    ui = SpiritualEnergyBar();
    add(ui);

    miniMap = MiniMap();
    add(miniMap);

    world.add(InstructionsText());

    _startSpawning();
    for (int i = 0; i < GameConfig.game.initialEnemyCount; i++) {
      spawnEnemy();
    }

    camera.setBounds(
      Rectangle.fromLTRB(0, 0, mapSize.x, mapSize.y),
    );

    camera.follow(player);
    state = GameState.playing;
  }
}

class WisdomMessageOverlay extends StatelessWidget {
  final NgaisCallGame game;

  const WisdomMessageOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.wisdomMessage == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10, // Align with safe area
      left: 20,
      right: 20,
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: Text(
              game.wisdomMessage!,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MobileControlsOverlay extends StatelessWidget {
  final NgaisCallGame game;

  const MobileControlsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Joystick - positioned in bottom left
        Positioned(
          left: GameConfig.touchControls.buttonMargin,
          bottom: GameConfig.touchControls.buttonMargin,
          child: JoystickArea(
            game: game,
            size: GameConfig.touchControls.joystickSize,
            knobSize: GameConfig.touchControls.joystickKnobSize,
          ),
        ),
        // Protection button - positioned in bottom right
        Positioned(
          right: GameConfig.touchControls.buttonMargin,
          bottom: GameConfig.touchControls.buttonMargin,
          child: ProtectionButton(
            game: game,
            size: GameConfig.touchControls.buttonSize,
          ),
        ),
        // Pause button - positioned in top right
        Positioned(
          top: MediaQuery.of(context).padding.top + 5, // Adjusted for safe area
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          game.state == GameState.paused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
          size: 24,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: const Text(
            'RESTART GAME',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
                  color: Colors.white.withOpacity(_isDragging ? 0.9 : 0.7),
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

    final direction = Vector2(dx / center, dy / center);
    widget.game.joystickDelta = direction;
    widget.game.player.handleJoystickMovement(direction);
  }

  void _resetKnob() {
    setState(() {
      _knobPosition = Offset.zero;
      _isDragging = false;
    });
    widget.game.joystickDelta = Vector2.zero();
    widget.game.player.handleJoystickMovement(Vector2.zero());
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
        child: Center(
          child: Text(
            'SHIELD',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.size * 0.15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
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
    _generateSection(0, gameRef.mapSize.x);
  }

  void generateNewSection(double startX) {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      trees.add(TreeSprite(
        position: Vector2(
          startX + random.nextDouble() * GameConfig.game.mapExtensionWidth,
          random.nextDouble() * gameRef.mapSize.y,
        ),
        size: random.nextDouble() * 30 + 20,
      ));
    }
    for (int i = 0; i < 3; i++) {
      groves.add(SacredGrove(
        position: Vector2(
          startX + random.nextDouble() * GameConfig.game.mapExtensionWidth,
          random.nextDouble() * gameRef.mapSize.y,
        ),
      ));
    }
  }

  void _generateSection(double startX, double endX) {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      trees.add(TreeSprite(
        position: Vector2(
          startX + random.nextDouble() * (endX - startX),
          random.nextDouble() * gameRef.mapSize.y,
        ),
        size: random.nextDouble() * 30 + 20,
      ));
    }
    for (int i = 0; i < 6; i++) {
      groves.add(SacredGrove(
        position: Vector2(
          startX + random.nextDouble() * (endX - startX),
          random.nextDouble() * gameRef.mapSize.y,
        ),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, gameRef.mapSize.x, gameRef.mapSize.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    for (final grove in groves) {
      grove.render(canvas);
    }
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
    canvas.drawCircle(
      Offset(position.x - size * 0.1, position.y - size * 0.3),
      size * 0.15,
      lightFoliage,
    );
    canvas.drawCircle(
      Offset(position.x + size * 0.1, position.y - size * 0.1),
      size * 0.12,
      lightFoliage,
    );
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

enum PowerUpType { speedBoost, energyRegen }

class PowerUp extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  final PowerUpType type;
  double _pulseTimer = 0;

  PowerUp({required this.startPosition, required this.type})
      : super(
          size: Vector2.all(GameConfig.powerUp.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final color = type == PowerUpType.speedBoost ? const Color(0xFF2196F3) : const Color(0xFFFFEB3B);
    final pulseEffect = (math.sin(_pulseTimer * 4) * 0.2 + 1.0);

    canvas.drawCircle(
      Offset.zero,
      (size.x / 2) * pulseEffect + 3,
      Paint()..color = color.withOpacity(0.3 * pulseEffect),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      size.x / 3,
      Paint()..color = color.withOpacity(0.7),
    );
  }

  @override
  void update(double dt) => _pulseTimer += dt;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      final game = findGame() as NgaisCallGame?;
      if (game != null) {
        if (type == PowerUpType.speedBoost) {
          game.player.activateSpeedBoost();
          game.showMessage("Played sound: Speed Boost!");
        } else {
          game.player.activateEnergyRegen();
          game.showMessage("Played sound: Energy Regen!");
        }
        removeFromParent();
      }
    }
  }
}

class MauMauArtifact extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  final String name = KikuyuWisdom.getRandomArtifactName();
  double _glowTimer = 0;

  MauMauArtifact({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.artifact.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final artifactPaint = Paint()..color = const Color(0xFF795548);
    final glowEffect = (math.sin(_glowTimer * 3) * 0.3 + 0.7);

    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 6,
      Paint()..color = artifactPaint.color.withOpacity(0.2 * glowEffect),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, artifactPaint);

    final symbolPaint = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, 0),
        width: size.x / 3,
        height: size.x / 3,
      ),
      symbolPaint,
    );
  }

  @override
  void update(double dt) => _glowTimer += dt;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      final game = findGame() as NgaisCallGame?;
      if (game != null) {
        game.scoreMultiplier = GameConfig.artifact.scoreMultiplier;
        game.scoreMultiplierTimer = GameConfig.artifact.scoreMultiplierDuration;
        game.showMessage("Collected $name! Score multiplier activated!");
        removeFromParent();
      }
    }
  }
}

class MiniMap extends PositionComponent with HasGameRef<NgaisCallGame> {
  @override
  bool get isHud => true; // Ensure this is rendered in screen space

  @override
  void render(Canvas canvas) {
    final miniMapWidth = 120.0;
    final miniMapHeight = 80.0;
    final scale = miniMapWidth / gameRef.mapSize.x;

    // Position minimap in top-right corner, below safe area and pause button
    final safeAreaTop = gameRef.canvasSize.y * 0.05; // 5% of screen height for safe area
    final mapX = gameRef.size.x - miniMapWidth - 15;
    final mapY = safeAreaTop + 10; // Position below safe area

    final bgPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mapX, mapY, miniMapWidth, miniMapHeight),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mapX, mapY, miniMapWidth, miniMapHeight),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // Draw player
    final playerPaint = Paint()..color = const Color(0xFF03A9F4);
    canvas.drawCircle(
      Offset(
        gameRef.player.position.x * scale + mapX,
        gameRef.player.position.y * scale + mapY,
      ),
      3,
      playerPaint,
    );

    // Draw enemies
    final enemyPaint = Paint()..color = const Color(0xFFD32F2F);
    for (var enemy in gameRef.world.children.whereType<Enemy>()) {
      canvas.drawCircle(
        Offset(
          enemy.position.x * scale + mapX,
          enemy.position.y * scale + mapY,
        ),
        2,
        enemyPaint,
      );
    }

    // Draw collectibles
    final blessingPaint = Paint()..color = const Color(0xFF4CAF50);
    for (var blessing in gameRef.world.children.whereType<Blessing>()) {
      canvas.drawCircle(
        Offset(
          blessing.position.x * scale + mapX,
          blessing.position.y * scale + mapY,
        ),
        1.5,
        blessingPaint,
      );
    }

    final proverbPaint = Paint()..color = const Color(0xFF9C27B0);
    for (var proverb in gameRef.world.children.whereType<KikuyuProverb>()) {
      canvas.drawCircle(
        Offset(
          proverb.position.x * scale + mapX,
          proverb.position.y * scale + mapY,
        ),
        1.5,
        proverbPaint,
      );
    }

    final ancestorPaint = Paint()..color = const Color(0xFFFFD700);
    for (var ancestor in gameRef.world.children.whereType<AncestorSpirit>()) {
      canvas.drawCircle(
        Offset(
          ancestor.position.x * scale + mapX,
          ancestor.position.y * scale + mapY,
        ),
        2,
        ancestorPaint,
      );
    }

    final hideoutPaint = Paint()..color = const Color(0xFF3E2723);
    for (var hideout in gameRef.world.children.whereType<Hideout>()) {
      canvas.drawCircle(
        Offset(
          hideout.position.x * scale + mapX,
          hideout.position.y * scale + mapY,
        ),
        2,
        hideoutPaint,
      );
    }
  }
}

class Player extends PositionComponent with CollisionCallbacks, HasGameRef<NgaisCallGame> {
  bool isProtected = false;
  bool hasAncestorBlessing = false;
  bool isHitByEnemy = false;
  bool isInHideout = false;
  bool isDead = false;
  Vector2 deathVelocity = Vector2.zero();
  bool hasSpeedBoost = false;
  bool hasEnergyRegen = false;

  late Timer _protectionTimer;
  late Timer _ancestorBlessingTimer;
  late Timer _deathSkidTimer;
  late Timer _speedBoostTimer;
  late Timer _energyRegenTimer;
  Vector2 _moveDirection = Vector2.zero();

  double life = GameConfig.game.initialLife;
  final double maxLife = GameConfig.game.maxLife;

  Player()
      : super(
          size: Vector2.all(GameConfig.player.size * 2),
          anchor: Anchor.center,
        ) {
    _protectionTimer = Timer(
      GameConfig.player.protectionDuration,
      onTick: () => isProtected = false,
    );
    _ancestorBlessingTimer = Timer(
      GameConfig.ancestor.blessingDuration,
      onTick: () => hasAncestorBlessing = false,
    );
    _deathSkidTimer = Timer(
      GameConfig.player.deathSkidDuration,
      onTick: () => isDead = false,
    );
    _speedBoostTimer = Timer(
      GameConfig.powerUp.duration,
      onTick: () => hasSpeedBoost = false,
    );
    _energyRegenTimer = Timer(
      GameConfig.powerUp.duration,
      onTick: () => hasEnergyRegen = false,
    );
  }

  @override
  Future<void> onLoad() async {
    reset();
    add(CircleHitbox());
  }

  void reset() {
    position = gameRef.mapSize / 2;
    life = GameConfig.game.initialLife;
    isProtected = false;
    hasAncestorBlessing = false;
    isHitByEnemy = false;
    isInHideout = false;
    isDead = false;
    hasSpeedBoost = false;
    hasEnergyRegen = false;
    _moveDirection = Vector2.zero();
    deathVelocity = Vector2.zero();
    _protectionTimer.stop();
    _ancestorBlessingTimer.stop();
    _deathSkidTimer.stop();
    _speedBoostTimer.stop();
    _energyRegenTimer.stop();
  }

  @override
  void render(Canvas canvas) {
    if (isDead) {
      final ghostPaint = Paint()
        ..color = const Color(0xFF03A9F4).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, size.x / 2 + 5, ghostPaint);
      canvas.drawCircle(Offset.zero, size.x / 2, ghostPaint);
      return;
    }

    Color baseColor = const Color(0xFF03A9F4);
    if (hasAncestorBlessing) baseColor = const Color(0xFFFFD700);
    if (isProtected) baseColor = const Color(0xFFFFC107);
    if (isHitByEnemy) baseColor = Colors.red;
    if (hasSpeedBoost) baseColor = const Color(0xFF2196F3);
    if (hasEnergyRegen) baseColor = const Color(0xFFFFEB3B);

    final paint = Paint()..color = baseColor;
    final glowOpacity = (isProtected || hasAncestorBlessing || hasSpeedBoost || hasEnergyRegen) ? 0.6 : 0.3;

    if (hasAncestorBlessing) {
      canvas.drawCircle(
        Offset.zero,
        size.x / 2 + 8,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.4),
      );
    }

    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 3,
      Paint()..color = paint.color.withOpacity(glowOpacity),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    canvas.drawCircle(
      Offset.zero,
      size.x / 3,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _deathSkidTimer.update(dt);
      position += deathVelocity * dt;
      deathVelocity *= 0.95;
      return;
    }

    if (isProtected) _protectionTimer.update(dt);
    if (hasAncestorBlessing) _ancestorBlessingTimer.update(dt);
    if (hasSpeedBoost) _speedBoostTimer.update(dt);
    if (hasEnergyRegen) {
      _energyRegenTimer.update(dt);
      gameRef.ui.addEnergy(GameConfig.powerUp.energyRegenRate * dt);
    }

    if (isHitByEnemy && !isProtected && !hasAncestorBlessing) {
      life = (life - GameConfig.game.lifeDrainRate * dt).clamp(0, maxLife);
      if (life <= 0) {
        onDeath();
        gameRef.onGameOver();
      }
    }

    if (_moveDirection != Vector2.zero()) {
      final speed = hasSpeedBoost
          ? GameConfig.player.speed * GameConfig.powerUp.speedBoostMultiplier
          : hasAncestorBlessing
              ? GameConfig.player.speed * 1.3
              : GameConfig.player.speed;
      position += _moveDirection.normalized() * speed * dt;
    }

    position.x = position.x.clamp(size.x / 2, gameRef.mapSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, gameRef.mapSize.y - size.y / 2);
  }

  void onDeath() {
    isDead = true;
    deathVelocity = _moveDirection.normalized() * GameConfig.player.speed * 0.8;
    _deathSkidTimer.start();
    gameRef.showMessage("Played sound: Player Death!");
  }

  void handleJoystickMovement(Vector2 direction) {
    if (direction.length > GameConfig.touchControls.deadZone) {
      _moveDirection = direction;
    } else {
      _moveDirection = Vector2.zero();
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

  void activateSpeedBoost() {
    hasSpeedBoost = true;
    _speedBoostTimer.start();
  }

  void activateEnergyRegen() {
    hasEnergyRegen = true;
    _energyRegenTimer.start();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    final game = findGame() as NgaisCallGame?;
    if (game == null) return;

    if (other is Enemy) {
      if (isProtected || hasAncestorBlessing) {
        other.removeFromParent();
        game.score += (GameConfig.enemy.scoreOnDestroy * game.scoreMultiplier).toInt();
        game.ui.addEnergy(GameConfig.enemy.energyOnDestroy);
        if (hasAncestorBlessing)
          game.score += (GameConfig.enemy.scoreOnDestroy * game.scoreMultiplier).toInt();
        game.showMessage("Played sound: Enemy Defeated!");
      } else if (!isHitByEnemy) {
        isHitByEnemy = true;
      }
    } else if (other is Blessing) {
      other.removeFromParent();
      game.score += (GameConfig.blessing.scoreOnCollect * game.scoreMultiplier).toInt();
      game.ui.addEnergy(GameConfig.blessing.energyOnCollect);
      game.showMessage("Played sound: Blessing Collected!");
    } else if (other is KikuyuProverb) {
      other.removeFromParent();
      game.score += (GameConfig.proverb.scoreOnCollect * game.scoreMultiplier).toInt();
      game.wisdom += GameConfig.proverb.wisdomOnCollect;
      game.ui.addEnergy(GameConfig.proverb.energyOnCollect);
      game.showWisdomMessage((other).proverb);
      game.showMessage("Played sound: Proverb Collected!");
    } else if (other is AncestorSpirit) {
      other.removeFromParent();
      game.score += (GameConfig.ancestor.scoreOnCollect * game.scoreMultiplier).toInt();
      game.ui.addEnergy(GameConfig.ancestor.energyOnCollect);
      activateAncestorBlessing();
      game.showAncestorMessage((other).saying);
      game.showMessage("Played sound: Ancestor Collected!");
    } else if (other is Hideout) {
      isInHideout = true;
      game.trapEnemiesInHideout(other);
    } else if (other is PowerUp) {
      other.removeFromParent();
    } else if (other is MauMauArtifact) {
      other.removeFromParent();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Enemy) isHitByEnemy = false;
    if (other is Hideout) isInHideout = false;
  }
}

class Enemy extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  Vector2 _currentWaypoint = Vector2.zero();
  final math.Random _random = math.Random();

  Enemy({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.player.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
    _pickNewWaypoint();
  }

  void _pickNewWaypoint() {
    _currentWaypoint = Vector2(
      _random.nextDouble() * gameRef.mapSize.x,
      _random.nextDouble() * gameRef.mapSize.y,
    );
  }

  @override
  void render(Canvas canvas) {
    final enemyPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 4,
      Paint()..color = enemyPaint.color.withOpacity(0.4),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, enemyPaint);
    canvas.drawCircle(
      Offset.zero,
      size.x / 4,
      Paint()..color = const Color(0xFF8B0000),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.state != GameState.playing) return;

    final playerPosition = gameRef.player.position;
    final distanceToPlayer = position.distanceTo(playerPosition);

    final dynamicSpeed = gameRef.getDynamicEnemySpeed();

    if (distanceToPlayer < GameConfig.enemy.detectionRadius) {
      final direction = (playerPosition - position).normalized();
      position += direction * dynamicSpeed * dt;
    } else {
      if (position.distanceTo(_currentWaypoint) < 5) _pickNewWaypoint();
      final direction = (_currentWaypoint - position).normalized();
      position += direction * GameConfig.enemy.wanderingSpeed * dt;
    }

    position.x = position.x.clamp(size.x / 2, gameRef.mapSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, gameRef.mapSize.y - size.y / 2);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Hideout) removeFromParent();
  }
}

class Blessing extends PositionComponent with CollisionCallbacks {
  final Vector2 startPosition;
  double _pulseTimer = 0;

  Blessing({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.blessing.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final blessingPaint = Paint()..color = const Color(0xFF4CAF50);
    final pulseEffect = (math.sin(_pulseTimer * 4) * 0.2 + 1.0);

    canvas.drawCircle(
      Offset.zero,
      (size.x / 2) * pulseEffect + 3,
      Paint()..color = blessingPaint.color.withOpacity(0.3 * pulseEffect),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, blessingPaint);
    canvas.drawCircle(
      Offset.zero,
      size.x / 3,
      Paint()..color = const Color(0xFF81C784),
    );
  }

  @override
  void update(double dt) => _pulseTimer += dt;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      removeFromParent();
    }
  }
}

class KikuyuProverb extends PositionComponent with CollisionCallbacks {
  final Vector2 startPosition;
  final String proverb = KikuyuWisdom.getRandomProverb();
  double _glowTimer = 0;

  KikuyuProverb({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.proverb.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final proverbPaint = Paint()..color = const Color(0xFF9C27B0);
    final glowEffect = (math.sin(_glowTimer * 3) * 0.3 + 0.7);

    canvas.drawCircle(
      Offset.zero,
      size.x / 2 + 6,
      Paint()..color = proverbPaint.color.withOpacity(0.2 * glowEffect),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, proverbPaint);

    final symbolPaint = Paint()..color = const Color(0xFFE1BEE7);
    canvas.drawCircle(Offset(-size.x / 4, -size.y / 4), 2, symbolPaint);
    canvas.drawCircle(Offset(size.x / 4, -size.y / 4), 2, symbolPaint);
    canvas.drawCircle(Offset(0, size.y / 4), 2, symbolPaint);
  }

  @override
  void update(double dt) => _glowTimer += dt;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      removeFromParent();
    }
  }
}

class AncestorSpirit extends PositionComponent with CollisionCallbacks {
  final Vector2 startPosition;
  final String saying = KikuyuWisdom.getRandomAncestorSaying();
  double _floatTimer = 0;
  late Vector2 _originalPosition;

  AncestorSpirit({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.ancestor.size * 2),
          anchor: Anchor.center,
        );

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

    canvas.drawCircle(
      Offset.zero,
      (size.x / 2 + 10) * floatEffect,
      Paint()..color = ancestorPaint.color.withOpacity(0.15),
    );
    canvas.drawCircle(
      Offset.zero,
      size.x / 2,
      Paint()
        ..color = ancestorPaint.color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset.zero, size.x / 3, ancestorPaint);

    final symbolPaint = Paint()..color = const Color(0xFFFFFF);
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

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      removeFromParent();
    }
  }
}

class Hideout extends PositionComponent with HasGameRef<NgaisCallGame>, CollisionCallbacks {
  final Vector2 startPosition;
  double _pulseTimer = 0;

  Hideout({required this.startPosition})
      : super(
          size: Vector2.all(GameConfig.hideout.size * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = startPosition;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final hideoutPaint = Paint()..color = const Color(0xFF3E2723);
    final pulseEffect = (math.sin(_pulseTimer * 2) * 0.1 + 0.9);

    canvas.drawCircle(
      Offset.zero,
      size.x / 2 * pulseEffect + 10,
      Paint()..color = const Color(0xFF2E7D32).withOpacity(0.2),
    );
    canvas.drawCircle(Offset.zero, size.x / 2, hideoutPaint);

    final entrancePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, size.y / 4),
        width: size.x * 0.4,
        height: size.y * 0.2,
      ),
      entrancePaint,
    );
  }

  @override
  void update(double dt) => _pulseTimer += dt;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      (other).isInHideout = true;
      (findGame() as NgaisCallGame).trapEnemiesInHideout(this);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Player) {
      (other).isInHideout = false;
    }
  }
}

class SpiritualEnergyBar extends PositionComponent with HasGameRef<NgaisCallGame> {
  double energy = GameConfig.game.initialEnergy;
  final double maxEnergy = GameConfig.game.maxEnergy;

  void addEnergy(double amount) => energy = (energy + amount).clamp(0, maxEnergy);
  void useEnergy(double amount) => energy = (energy - amount).clamp(0, maxEnergy);
  bool canUseEnergy(double amount) => energy >= amount;

  @override
  bool get isHud => true; // Ensure this is rendered in screen space

  @override
  void render(Canvas canvas) {
    // Adjust position to account for safe area (notch, status bar)
    final safeAreaTop = gameRef.canvasSize.y * 0.05; // 5% of screen height for safe area

    // Energy bar
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, safeAreaTop + 10, 180, 16),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    final energyPaint = Paint()
      ..color = energy > GameConfig.player.protectionEnergyCost
          ? const Color(0xFF4CAF50)
          : const Color(0xFFFF5722);
    final energyWidth = (energy / maxEnergy) * 180;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, safeAreaTop + 10, energyWidth, 16),
        const Radius.circular(8),
      ),
      energyPaint,
    );

    // Life bar
    final lifeYOffset = safeAreaTop + 30.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, lifeYOffset, 180, 16),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    final lifePaint = Paint()
      ..color = gameRef.player.life > (gameRef.player.maxLife / 3)
          ? Colors.red
          : const Color(0xFFFF5722);
    final lifeWidth = (gameRef.player.life / gameRef.player.maxLife) * 180;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, lifeYOffset, lifeWidth, 16),
        const Radius.circular(8),
      ),
      lifePaint,
    );

    // Life text
    final lifeTextPainter = TextPainter(
      text: TextSpan(
        text: 'Life: ${gameRef.player.life.toInt()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    lifeTextPainter.layout();
    lifeTextPainter.paint(
      canvas,
      Offset(10 + (180 - lifeTextPainter.width) / 2, lifeYOffset + 2),
    );

    // Score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: 'Score: ${gameRef.score}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(canvas, Offset(10, safeAreaTop + 50));

    // Wisdom
    final wisdomPainter = TextPainter(
      text: TextSpan(
        text: 'Wisdom: ${gameRef.wisdom}',
        style: const TextStyle(
          color: Color(0xFF9C27B0),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    wisdomPainter.layout();
    wisdomPainter.paint(canvas, Offset(10, safeAreaTop + 68));

    // Score multiplier
    if (gameRef.scoreMultiplier > 1.0) {
      final multiplierPainter = TextPainter(
        text: TextSpan(
          text: 'Multiplier: ${gameRef.scoreMultiplier.toStringAsFixed(1)}x (${gameRef.scoreMultiplierTimer.toStringAsFixed(1)}s)',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      multiplierPainter.layout();
      multiplierPainter.paint(canvas, Offset(10, safeAreaTop + 85));
    }

    // Game messages
    if (gameRef.currentMessage != null) {
      final messagePaint = Paint()..color = Colors.black.withOpacity(0.8);
      final messageRect = Rect.fromLTWH(
        10,
        gameRef.size.y - 80,
        gameRef.size.x - 20,
        50,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(messageRect, const Radius.circular(8)),
        messagePaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: gameRef.currentMessage!,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: gameRef.size.x - 40);
      textPainter.paint(canvas, Offset(20, gameRef.size.y - 70));
    }

    // Protection cooldown
    if (gameRef.protectionOnCooldown) {
      final cooldownText = TextPainter(
        text: TextSpan(
          text: 'Shield: ${gameRef.protectionCooldownTimer.toStringAsFixed(1)}s',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      cooldownText.layout();
      cooldownText.paint(
        canvas,
        Offset(gameRef.size.x - cooldownText.width - 15, safeAreaTop + 50),
      );
    }
  }
}

class InstructionsText extends PositionComponent with HasGameRef<NgaisCallGame> {
  @override
  Future<void> onLoad() async {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, offset: Offset(1, 1)),
        Shadow(color: Colors.black, offset: Offset(-1, -1)),
      ],
    );

    add(
      TextComponent(
        text: 'Collect: Green(Blessings) Purple(Proverbs) Gold(Ancestors) Brown(Artifacts)',
        textRenderer: TextPaint(style: textStyle),
        position: Vector2(
          gameRef.size.x / 2,
          gameRef.size.y - 70,
        ),
        anchor: Anchor.topCenter,
      ),
    );

    add(
      TextComponent(
        text: 'Avoid RED spirits! Use Brown Hideouts to trap enemies!',
        textRenderer: TextPaint(style: textStyle),
        position: Vector2(
          gameRef.size.x / 2,
          gameRef.size.y - 55,
        ),
        anchor: Anchor.topCenter,
      ),
    );

    add(
      TextComponent(
        text: 'SHIELD button uses energy. Blue=Speed, Yellow=Energy Regen',
        textRenderer: TextPaint(style: textStyle),
        position: Vector2(
          gameRef.size.x / 2,
          gameRef.size.y - 40,
        ),
        anchor: Anchor.topCenter,
      ),
    );

    add(
      TextComponent(
        text: 'Move RIGHT to explore new forest areas!',
        textRenderer: TextPaint(style: textStyle),
        position: Vector2(
          gameRef.size.x / 2,
          gameRef.size.y - 25,
        ),
        anchor: Anchor.topCenter,
      ),
    );
  }
}