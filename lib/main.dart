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
  
  runApp(NgaisCallApp());
}

enum AppScreen { mainMenu, loreLibrary, instructions, settings, game }

class NgaisCallApp extends StatefulWidget {
  const NgaisCallApp({super.key});

  @override
  _NgaisCallAppState createState() => _NgaisCallAppState();
}

class _NgaisCallAppState extends State<NgaisCallApp> with TickerProviderStateMixin {
  late NgaisCallGame game;
  AppScreen currentScreen = AppScreen.mainMenu;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    game = NgaisCallGame();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchScreen(AppScreen newScreen) {
    _fadeController.reverse().then((_) {
      setState(() {
        currentScreen = newScreen;
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'serif',
        primaryColor: Color(0xFF4CAF50),
      ),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildCurrentScreen(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentScreen) {
      case AppScreen.mainMenu:
        return MainMenuScreen(onNavigate: _switchScreen, game: game);
      case AppScreen.loreLibrary:
        return LoreLibraryScreen(onNavigate: _switchScreen);
      case AppScreen.instructions:
        return InstructionsScreen(onNavigate: _switchScreen);
      case AppScreen.settings:
        return SettingsScreen(onNavigate: _switchScreen, game: game);
      case AppScreen.game:
        return GameScreen(game: game, onNavigate: _switchScreen);
    }
  }
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
  final double joystickSize = 120.0;
  final double joystickKnobSize = 40.0;
  final double buttonSize = 70.0;
  final double buttonMargin = 40.0;
  final double opacity = 0.7;
  final double deadZone = 0.15;
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
  static final List<Map<String, String>> proverbs = [
    {"kikuyu": "Gikuyu na Mumbi", "english": "Unity gives strength", "meaning": "The founders of the Kikuyu people represent the power of working together."},
    {"kikuyu": "Harambee", "english": "We pull together", "meaning": "Community cooperation achieves what individuals cannot do alone."},
    {"kikuyu": "Mti hauendi uru na ugeeni", "english": "A tree doesn't lean without wind", "meaning": "Nothing happens without a cause - there's always a reason behind events."},
    {"kikuyu": "Kahiu gatagwo na njira", "english": "A hawk circles its prey", "meaning": "Patience and strategic planning lead to success."},
    {"kikuyu": "Mwaki wa muingi ndungagwo", "english": "A community fire burns bright", "meaning": "Collective effort creates lasting results."},
    {"kikuyu": "Muici ndacokaga na kirira", "english": "The thief returns with tears", "meaning": "Wrong actions eventually bring consequences and regret."},
    {"kikuyu": "Gutiri mwana wa nyawira", "english": "No child belongs to work alone", "meaning": "Everyone deserves rest and should not be burdened beyond their capacity."},
    {"kikuyu": "Njira ya muingi ti ya kaba", "english": "The people's path has no thorns", "meaning": "When the community agrees on something, obstacles disappear."},
    {"kikuyu": "Mti wa Ngai", "english": "Tree of the Most High", "meaning": "The sacred mugumo tree connects earth to the divine Ngai."},
    {"kikuyu": "Gikeno kia njohi", "english": "Joy comes from unity", "meaning": "True happiness is found in community celebration and togetherness."},
    {"kikuyu": "Mundu ni mundu no ugeni", "english": "A person is a person because of others", "meaning": "Our humanity is defined by our relationships and community bonds."},
    {"kikuyu": "Irigu ria mucii ritiyagwo", "english": "Home food is never wasted", "meaning": "What comes from one's own effort and culture has lasting value."},
    {"kikuyu": "Nyeki ndireyagwo na mwaki", "english": "Dry grass fears fire", "meaning": "The guilty fear justice and truth."},
    {"kikuyu": "Mwana ndatigaga nyina kana", "english": "A child never abandons the mother completely", "meaning": "One's roots and origins remain important throughout life."},
    {"kikuyu": "Mwetereri arîaga ya mûgwatio", "english": "The patient one eats the best sweet potato", "meaning": "Deep rewards come to the patient."},
    {"kikuyu": "Gũceera nĩ kũhĩga", "english": "Traveling is learning", "meaning": "Experience through travel brings wisdom."},
    {"kikuyu": "Gũcekeha ti gũicũhio", "english": "Being slim doesn't mean well-trimmed", "meaning": "Appearances can deceive."},
    {"kikuyu": "Gĩtoĩ kĩmenyaga kĩerwo", "english": "The one who doesn't know learns when told", "meaning": "Wisdom comes through teaching and guidance."},
    {"kikuyu": "Gĩtoĩ kĩraragia kĩũĩ njĩra", "english": "He who doesn't know the road delays even the one who does", "meaning": "Ignorance can hold back progress for everyone."},
    {"kikuyu": "Ya rika ithinjaga na mweri", "english": "Age-mates complete slaughter even in darkness", "meaning": "Unity and persistence get the job done."},
    {"kikuyu": "Muthenya wa gu nî gu", "english": "If today is for firewood, let it be", "meaning": "Focus on the task of the day."},
    {"kikuyu": "Gieterero ti kiinaino", "english": "Waiting is not trembling", "meaning": "Patience is not fear."},
    {"kikuyu": "Gikiunoa rukomo, kimenyi akamenya ikiunwo", "english": "A wise one understands even what is hinted", "meaning": "True wisdom reads between the lines."},
    {"kikuyu": "Gathutha konagia mundu njia", "english": "A small path may lead to the main road", "meaning": "Humble beginnings matter."},
    {"kikuyu": "Yaikio iikagia ingi", "english": "One pushed goat pushes the rest", "meaning": "Bad influence spreads fast."},
    {"kikuyu": "Ya matharara igwatagia ya nyeki", "english": "A rotten sheep infects the flock", "meaning": "Corruption spreads quickly through a group."},
    {"kikuyu": "Kũmenya werũ nĩ kũũtinda", "english": "One knows a place by living in it", "meaning": "Only insiders understand deeply."},
    {"kikuyu": "Kũmenya mũno nĩ kũmenyũka", "english": "Too much knowing leads to breaking", "meaning": "Overconfidence can destroy you."},
    {"kikuyu": "Kũmtha gũtirĩ hinya ta kũramata", "english": "It's easier to reap than to preserve", "meaning": "Sustainability is harder than achievement."},
    {"kikuyu": "Muugi ni mutaare", "english": "A wise person is the one who listens to advice", "meaning": "Wisdom comes from listening."},
    {"kikuyu": "Mbaara ti ûcûrû", "english": "War is not porridge", "meaning": "Conflict is not soft or sweet."},
    {"kikuyu": "Gatitu ka ngoro gatiunagwo", "english": "The grove of the heart is never fully open", "meaning": "True intentions are hidden."},
    {"kikuyu": "Gatinyinyiraga gatari gakunye", "english": "None cries unless pinched", "meaning": "People complain for a reason."},
    {"kikuyu": "Gicegu kia andu aingi ti kiega", "english": "Too many people ruin the plan", "meaning": "Too many cooks spoil the broth."},
    {"kikuyu": "Kamau the lightskin becomes dark", "english": "Even what was white becomes dark", "meaning": "Change is constant."},
    {"kikuyu": "Ya mwene ndiri njereri", "english": "One's own goose is never a crow", "meaning": "We overvalue what we own."},
    {"kikuyu": "Giathi kiriagwo ni kingi", "english": "One cloud hides the sun", "meaning": "Small problems can overshadow big wins."},
    {"kikuyu": "Giathi kiumu gitirĩ rũrĩrĩ", "english": "A painful journey doesn't lack an end", "meaning": "Suffering ends eventually."},
    {"kikuyu": "Cira wa mucii ndumagirio kiharo", "english": "Family disputes shouldn't be aired in public", "meaning": "Keep private matters private."},
    {"kikuyu": "Gatami kari mondo gatamaga", "english": "The cloth in another's bag doesn't patch your cloak", "meaning": "Use your own resources."},
    {"kikuyu": "Ya rika ringi ndiri mũtwe", "english": "Familiarity breeds contempt", "meaning": "Too much closeness can lead to disrespect."},
    {"kikuyu": "Gũtirĩ kĩrĩa gĩtigĩragwo", "english": "There is no gain without loss", "meaning": "Everything comes with a price."},
    {"kikuyu": "Kĩega gĩtũmarwo nĩ gĩrĩa", "english": "Goodness is known by its opposite", "meaning": "You know good by contrast."},
    {"kikuyu": "Gũtirĩ mũciarwo na gĩkeno kĩa mũthenya umwe", "english": "No one is born with a lifelong celebration", "meaning": "Life has ups and downs."},
  ];

  static final List<Map<String, String>> ancestorSayings = [
    {"saying": "Ngai watches over the faithful", "context": "Trust in the Creator's protection during difficult times."},
    {"saying": "The ancestors guide your path", "context": "Our forebears continue to influence and protect us."},
    {"saying": "Wisdom flows like the sacred river", "context": "Knowledge passes from generation to generation like water."},
    {"saying": "Mount Kenya stands eternal", "context": "Kirinyaga, the mountain of brightness, is Ngai's dwelling place."},
    {"saying": "The fig tree shelters all who seek", "context": "The sacred mugumo provides refuge and spiritual connection."},
    {"saying": "Sacred groves hold ancient power", "context": "Traditional worship sites maintain spiritual energy."},
    {"saying": "Listen to the whispers of the wind", "context": "Nature speaks to those who pay attention."},
    {"saying": "The freedom fighter's courage lives on", "context": "The Mau Mau spirit continues to inspire resistance against oppression."},
    {"saying": "Unity in the forest, strength in the struggle", "context": "The Mau Mau survived through cooperation in the forest hideouts."},
    {"saying": "The land remembers those who died for it", "context": "The soil of Kenya holds the memory of those who fought for independence."},
  ];

  static final List<Map<String, String>> artifacts = [
    {"name": "Mau Mau Spear", "description": "A traditional weapon carried by forest fighters", "significance": "Symbol of resistance against colonial rule"},
    {"name": "Kikuyu War Horn", "description": "Used to communicate across the forest", "significance": "Coordinated resistance movements"},
    {"name": "Sacred Oath Stone", "description": "Stone used in traditional oath ceremonies", "significance": "Bound fighters together in sacred commitment"},
    {"name": "Freedom Fighter's Shield", "description": "Leather shield with traditional patterns", "significance": "Protection in both physical and spiritual battles"},
    {"name": "Elder's Walking Staff", "description": "Carved staff of authority and wisdom", "significance": "Leadership and guidance in difficult times"},
    {"name": "Ceremonial Beads", "description": "Traditional beads worn during rituals", "significance": "Connection to ancestral spirits and identity"},
  ];

  static final Map<String, String> kikuyuHistory = {
    "origin": "The Kikuyu people trace their ancestry to Gikuyu and Mumbi, the first man and woman created by Ngai (God) on Mount Kenya. They were given the fertile lands around Kirinyaga (Mount Kenya) to cultivate and multiply.",
    "ngai": "Ngai is the supreme creator deity of the Kikuyu people, dwelling on Mount Kenya (Kirinyaga). Ngai provides rain, fertility, and protection to the people.",
    "maumau": "The Mau Mau uprising (1952-1960) was a Kikuyu-led anti-colonial movement against British rule in Kenya. Freedom fighters lived in forest hideouts, using traditional oaths and guerrilla tactics.",
    "culture": "Traditional Kikuyu society was organized around age sets, with elders providing wisdom and leadership. The mugumo (fig tree) served as a sacred meeting place.",
    "land": "Land was sacred to the Kikuyu, passed down through generations. The colonial seizure of ancestral lands was a primary cause of the Mau Mau uprising.",
  };

  static String getRandomProverb() {
    final proverbData = proverbs[math.Random().nextInt(proverbs.length)];
    return '${proverbData['kikuyu']} - ${proverbData['english']}';
  }
  
  static String getRandomAncestorSaying() {
    final sayingData = ancestorSayings[math.Random().nextInt(ancestorSayings.length)];
    return sayingData['saying']!;
  }
  
  static String getRandomArtifactName() {
    final artifactData = artifacts[math.Random().nextInt(artifacts.length)];
    return artifactData['name']!;
  }
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

    // Instructions removed - now accessible only from menu screen

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
    // Extend map both horizontally and vertically
    mapSize.x += GameConfig.game.mapExtensionWidth;
    mapSize.y += GameConfig.game.mapExtensionWidth * 0.5; // Add vertical extension
    forest.generateNewSection(mapSize.x - GameConfig.game.mapExtensionWidth, mapSize.y - GameConfig.game.mapExtensionWidth * 0.5);
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

      if (player.position.x > mapSize.x - 100 || player.position.y > mapSize.y - 100) {
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
    // Instructions removed from game

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

    // Instructions removed - accessible only from menu

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

  void generateNewSection(double startX, [double? startY]) {
    final random = math.Random();
    
    // Generate trees in extended area
    for (int i = 0; i < 15; i++) {
      trees.add(TreeSprite(
        position: Vector2(
          startX + random.nextDouble() * GameConfig.game.mapExtensionWidth,
          random.nextDouble() * gameRef.mapSize.y,
        ),
        size: random.nextDouble() * 30 + 20,
      ));
    }
    
    // If vertical extension, add trees in the new vertical area too
    if (startY != null) {
      for (int i = 0; i < 10; i++) {
        trees.add(TreeSprite(
          position: Vector2(
            random.nextDouble() * gameRef.mapSize.x,
            startY + random.nextDouble() * (GameConfig.game.mapExtensionWidth * 0.5),
          ),
          size: random.nextDouble() * 30 + 20,
        ));
      }
    }
    
    // Generate groves
    for (int i = 0; i < 3; i++) {
      groves.add(SacredGrove(
        position: Vector2(
          startX + random.nextDouble() * GameConfig.game.mapExtensionWidth,
          random.nextDouble() * gameRef.mapSize.y,
        ),
      ));
    }
    
    // If vertical extension, add groves in vertical area
    if (startY != null) {
      for (int i = 0; i < 2; i++) {
        groves.add(SacredGrove(
          position: Vector2(
            random.nextDouble() * gameRef.mapSize.x,
            startY + random.nextDouble() * (GameConfig.game.mapExtensionWidth * 0.5),
          ),
        ));
      }
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
    super.onCollisionStart(intersectionPoints, other);
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
    super.onCollisionStart(intersectionPoints, other);
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
  int get priority => 1001; // Render above other HUD elements
  
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
    super.onCollisionStart(intersectionPoints, other);
    final game = findGame() as NgaisCallGame?;
    if (game == null) return;

    if (other is Enemy) {
      if (isProtected || hasAncestorBlessing) {
        other.removeFromParent();
        game.score += (GameConfig.enemy.scoreOnDestroy * game.scoreMultiplier).toInt();
        game.ui.addEnergy(GameConfig.enemy.energyOnDestroy);
        if (hasAncestorBlessing) {
          game.score += (GameConfig.enemy.scoreOnDestroy * game.scoreMultiplier).toInt();
        }
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
    super.onCollisionEnd(other);
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
    super.onCollisionStart(intersectionPoints, other);
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
    super.onCollisionStart(intersectionPoints, other);
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
    super.onCollisionStart(intersectionPoints, other);
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

    final symbolPaint = Paint()..color = const Color(0x00ffffff);
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
    super.onCollisionStart(intersectionPoints, other);
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
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      (other).isInHideout = true;
      (findGame() as NgaisCallGame).trapEnemiesInHideout(this);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
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

// Screen classes for the enhanced UI system
class MainMenuScreen extends StatefulWidget {
  final Function(AppScreen) onNavigate;
  final NgaisCallGame game;

  const MainMenuScreen({super.key, required this.onNavigate, required this.game});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;
  late AnimationController _buttonsController;
  late Animation<Offset> _buttonsAnimation;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(duration: Duration(seconds: 2), vsync: this);
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
    );
    _buttonsController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _buttonsAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );
    _backgroundController = AnimationController(duration: Duration(seconds: 3), vsync: this);
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
    
    _backgroundController.forward();
    _titleController.forward();
    Future.delayed(Duration(milliseconds: 500), () => _buttonsController.forward());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final titleFontSize = isLandscape ? math.min(screenSize.height * 0.12, 48.0) : 48.0;
    final subtitleFontSize = isLandscape ? math.min(screenSize.height * 0.04, 18.0) : 18.0;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Color(0xFF0D4F3C), Color(0xFF1B5E20), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFF1B5E20), Color(0xFF2E7D32), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFF2E7D32), Color(0xFF388E3C), _backgroundAnimation.value)!,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: isLandscape ? _buildLandscapeLayout(titleFontSize, subtitleFontSize) : _buildPortraitLayout(titleFontSize, subtitleFontSize),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscapeLayout(double titleFontSize, double subtitleFontSize) {
    return Row(
      children: [
        // Left side - Title and subtitle
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _titleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _titleAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "NGAI'S CALL",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                                shadows: [
                                  Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "A Journey of Kikuyu Wisdom",
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Color(0xFF4CAF50),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Explore ancient forests, collect wisdom,\nand honor the ancestors in this spiritual adventure.",
                              style: TextStyle(
                                fontSize: subtitleFontSize * 0.7,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Right side - Buttons
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SlideTransition(
              position: _buttonsAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactMenuButton(
                    "PLAY GAME",
                    Icons.play_arrow,
                    () => widget.onNavigate(AppScreen.game),
                    Color(0xFF4CAF50),
                  ),
                  SizedBox(height: 12),
                  _buildCompactMenuButton(
                    "KIKUYU LORE",
                    Icons.menu_book,
                    () => widget.onNavigate(AppScreen.loreLibrary),
                    Color(0xFF9C27B0),
                  ),
                  SizedBox(height: 12),
                  _buildCompactMenuButton(
                    "INSTRUCTIONS",
                    Icons.help_outline,
                    () => widget.onNavigate(AppScreen.instructions),
                    Color(0xFF03A9F4),
                  ),
                  SizedBox(height: 12),
                  _buildCompactMenuButton(
                    "SETTINGS",
                    Icons.settings,
                    () => widget.onNavigate(AppScreen.settings),
                    Color(0xFFFF5722),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(double titleFontSize, double subtitleFontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _titleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _titleAnimation.value,
              child: Column(
                children: [
                  Text(
                    "NGAI'S CALL",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 8),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "A Journey of Kikuyu Wisdom",
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Color(0xFF4CAF50),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 40),
        SlideTransition(
          position: _buttonsAnimation,
          child: Column(
            children: [
              _buildMenuButton(
                "PLAY GAME",
                Icons.play_arrow,
                () => widget.onNavigate(AppScreen.game),
                Color(0xFF4CAF50),
              ),
              SizedBox(height: 20),
              _buildMenuButton(
                "KIKUYU LORE",
                Icons.menu_book,
                () => widget.onNavigate(AppScreen.loreLibrary),
                Color(0xFF9C27B0),
              ),
              SizedBox(height: 20),
              _buildMenuButton(
                "INSTRUCTIONS",
                Icons.help_outline,
                () => widget.onNavigate(AppScreen.instructions),
                Color(0xFF03A9F4),
              ),
              SizedBox(height: 20),
              _buildMenuButton(
                "SETTINGS",
                Icons.settings,
                () => widget.onNavigate(AppScreen.settings),
                Color(0xFFFF5722),
              ),
            ],
          ),
        ),
        SizedBox(height: 40),
        Text(
          "Built with Flutter & Flame • Honoring Kikuyu Heritage",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildCompactMenuButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  final NgaisCallGame game;
  final Function(AppScreen) onNavigate;

  const GameScreen({super.key, required this.game, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: game,
      overlayBuilderMap: {
        'mobileControls': (context, game) => MobileControlsOverlay(game: game as NgaisCallGame),
        'restartButton': (context, game) => RestartButtonOverlay(game: game as NgaisCallGame),
        'wisdomMessage': (context, game) => WisdomMessageOverlay(game: game as NgaisCallGame),
      },
    );
  }
}

class LoreLibraryScreen extends StatefulWidget {
  final Function(AppScreen) onNavigate;

  const LoreLibraryScreen({super.key, required this.onNavigate});

  @override
  _LoreLibraryScreenState createState() => _LoreLibraryScreenState();
}

class _LoreLibraryScreenState extends State<LoreLibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => currentIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onNavigate(AppScreen.mainMenu),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      "KIKUYU WISDOM LIBRARY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Color(0xFFFFD700),
              unselectedLabelColor: Colors.white70,
              indicatorColor: Color(0xFFFFD700),
              tabs: [
                Tab(text: "PROVERBS"),
                Tab(text: "ANCESTORS"),
                Tab(text: "ARTIFACTS"),
                Tab(text: "HISTORY"),
              ],
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProverbsTab(),
                  _buildAncestorsTab(),
                  _buildArtifactsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProverbsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: KikuyuWisdom.proverbs.length,
      itemBuilder: (context, index) {
        final proverb = KikuyuWisdom.proverbs[index];
        return Card(
          color: Colors.black.withOpacity(0.7),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proverb['kikuyu']!,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  proverb['english']!,
                  style: TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  proverb['meaning']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAncestorsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: KikuyuWisdom.ancestorSayings.length,
      itemBuilder: (context, index) {
        final saying = KikuyuWisdom.ancestorSayings[index];
        return Card(
          color: Colors.black.withOpacity(0.7),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        saying['saying']!,
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  saying['context']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtifactsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: KikuyuWisdom.artifacts.length,
      itemBuilder: (context, index) {
        final artifact = KikuyuWisdom.artifacts[index];
        return Card(
          color: Colors.black.withOpacity(0.7),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: Color(0xFF795548)),
                    SizedBox(width: 8),
                    Text(
                      artifact['name']!,
                      style: TextStyle(
                        color: Color(0xFF795548),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  artifact['description']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Significance: ${artifact['significance']!}",
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final historyEntries = KikuyuWisdom.kikuyuHistory.entries.toList();
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: historyEntries.length,
      itemBuilder: (context, index) {
        final entry = historyEntries[index];
        return Card(
          color: Colors.black.withOpacity(0.7),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InstructionsScreen extends StatelessWidget {
  final Function(AppScreen) onNavigate;

  const InstructionsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => onNavigate(AppScreen.mainMenu),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      "HOW TO PLAY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Instructions Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildInstructionCard(
                    "🎯 OBJECTIVE",
                    "Collect ancient Kikuyu wisdom while avoiding hostile red spirits. Gather proverbs, blessings, and artifacts to honor your ancestors and achieve the highest score.",
                    Color(0xFF4CAF50),
                  ),
                  _buildInstructionCard(
                    "🎮 CONTROLS",
                    "• Move with joystick (mobile) or WASD/Arrow keys\n• Press SHIELD button to activate protection\n• Protection costs spiritual energy and has cooldown\n• Pause button to pause/resume game",
                    Color(0xFF03A9F4),
                  ),
                  _buildInstructionCard(
                    "💎 COLLECTIBLES",
                    "• Green Blessings: Restore spiritual energy\n• Purple Proverbs: Grant wisdom + display sayings\n• Gold Ancestor Spirits: Temporary invincibility\n• Brown Artifacts: Score multiplier boost\n• Blue Power-ups: Speed boost or energy regen",
                    Color(0xFF9C27B0),
                  ),
                  _buildInstructionCard(
                    "⚔️ COMBAT",
                    "• Red spirits drain your life on contact\n• Use shield or ancestor blessing for protection\n• Lead enemies into brown hideouts for ambush\n• Mau Mau fighters will eliminate trapped enemies\n• Defeated enemies give points and energy",
                    Color(0xFFFF5722),
                  ),
                  _buildInstructionCard(
                    "🗺️ EXPLORATION",
                    "• Move right to discover new forest areas\n• Map expands dynamically as you explore\n• Use minimap to track enemies and collectibles\n• Sacred groves provide spiritual atmosphere\n• Each area holds new challenges and rewards",
                    Color(0xFFFFEB3B),
                  ),
                  _buildInstructionCard(
                    "💡 TIPS",
                    "• Manage your energy wisely for protection\n• Ancestor blessings make you temporarily invulnerable\n• Hideouts are strategic - use them tactically\n• Collect proverbs to learn Kikuyu wisdom\n• Higher scores unlock more challenging gameplay",
                    Color(0xFFFFD700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(String title, String content, Color accentColor) {
    return Card(
      color: Colors.black.withOpacity(0.7),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Function(AppScreen) onNavigate;
  final NgaisCallGame game;

  const SettingsScreen({super.key, required this.onNavigate, required this.game});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double joystickOpacity = GameConfig.touchControls.opacity;
  double joystickSize = GameConfig.touchControls.joystickSize;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D4F3C), Color(0xFF1B5E20)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onNavigate(AppScreen.mainMenu),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      "SETTINGS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Settings Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSettingsCard(
                    "🎮 CONTROLS",
                    [
                      _buildSliderSetting(
                        "Joystick Opacity",
                        joystickOpacity,
                        0.3,
                        1.0,
                        (value) => setState(() => joystickOpacity = value),
                        "${(joystickOpacity * 100).round()}%",
                      ),
                      _buildSliderSetting(
                        "Joystick Size",
                        joystickSize,
                        80.0,
                        150.0,
                        (value) => setState(() => joystickSize = value),
                        "${joystickSize.round()}px",
                      ),
                    ],
                  ),
                  _buildSettingsCard(
                    "🔊 AUDIO & FEEDBACK",
                    [
                      _buildSwitchSetting(
                        "Sound Effects",
                        soundEnabled,
                        (value) => setState(() => soundEnabled = value),
                        "Enable game sound effects",
                      ),
                      _buildSwitchSetting(
                        "Vibration",
                        vibrationEnabled,
                        (value) => setState(() => vibrationEnabled = value),
                        "Haptic feedback for mobile devices",
                      ),
                    ],
                  ),
                  _buildSettingsCard(
                    "📊 GAME INFO",
                    [
                      _buildInfoTile("Version", "1.0.0"),
                      _buildInfoTile("Engine", "Flutter + Flame"),
                      _buildInfoTile("Theme", "Kikuyu Heritage"),
                      _buildInfoTile("Developer", "Ngai's Call Team"),
                    ],
                  ),
                  Card(
                    color: Colors.black.withOpacity(0.7),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🏆 RESET PROGRESS",
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showResetDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF5722),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Reset All Data",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Card(
      color: Colors.black.withOpacity(0.7),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              displayValue,
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Color(0xFF4CAF50),
          inactiveColor: Colors.white30,
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    bool value,
    Function(bool) onChanged,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Color(0xFF4CAF50),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2E2E2E),
          title: Text(
            "Reset Progress?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "This will reset all your game progress, scores, and settings. This action cannot be undone.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: Color(0xFF4CAF50))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.game.resetGame();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Game progress reset successfully!"),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: Text("Reset", style: TextStyle(color: Color(0xFFFF5722))),
            ),
          ],
        );
      },
    );
  }
}
