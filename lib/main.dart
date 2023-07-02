import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: "Passion",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          visualDensity: VisualDensity.standard,
        ),
        home: Game(),
      ),
    );
  }
}

class GameProvider extends ChangeNotifier {
  List<List<PlayingCard?>> cards = [];
  GameState state = GameState.move;
  int shufflesLeft = 0;

  SharedPreferences? prefs;
  int? games;
  int? wins;

  GameProvider() {
    SharedPreferences.getInstance().then((p) {
      prefs = p;
      games = p.getInt(gamesStorageKey) ?? 0;
      wins = p.getInt(winsStorageKey) ?? 0;
      notifyListeners();
    });
  }

  void init() {
    final allCards = [
      PlayingCard(suit: Suit.hearts, kind: Kind.two),
      PlayingCard(suit: Suit.hearts, kind: Kind.three),
      PlayingCard(suit: Suit.hearts, kind: Kind.four),
      PlayingCard(suit: Suit.hearts, kind: Kind.five),
      PlayingCard(suit: Suit.hearts, kind: Kind.six),
      PlayingCard(suit: Suit.hearts, kind: Kind.seven),
      PlayingCard(suit: Suit.hearts, kind: Kind.eight),
      PlayingCard(suit: Suit.hearts, kind: Kind.nine),
      PlayingCard(suit: Suit.hearts, kind: Kind.ten),
      PlayingCard(suit: Suit.hearts, kind: Kind.jack),
      PlayingCard(suit: Suit.hearts, kind: Kind.queen),
      PlayingCard(suit: Suit.hearts, kind: Kind.king),
      PlayingCard(suit: Suit.diamonds, kind: Kind.two),
      PlayingCard(suit: Suit.diamonds, kind: Kind.three),
      PlayingCard(suit: Suit.diamonds, kind: Kind.four),
      PlayingCard(suit: Suit.diamonds, kind: Kind.five),
      PlayingCard(suit: Suit.diamonds, kind: Kind.six),
      PlayingCard(suit: Suit.diamonds, kind: Kind.seven),
      PlayingCard(suit: Suit.diamonds, kind: Kind.eight),
      PlayingCard(suit: Suit.diamonds, kind: Kind.nine),
      PlayingCard(suit: Suit.diamonds, kind: Kind.ten),
      PlayingCard(suit: Suit.diamonds, kind: Kind.jack),
      PlayingCard(suit: Suit.diamonds, kind: Kind.queen),
      PlayingCard(suit: Suit.diamonds, kind: Kind.king),
      PlayingCard(suit: Suit.clubs, kind: Kind.two),
      PlayingCard(suit: Suit.clubs, kind: Kind.three),
      PlayingCard(suit: Suit.clubs, kind: Kind.four),
      PlayingCard(suit: Suit.clubs, kind: Kind.five),
      PlayingCard(suit: Suit.clubs, kind: Kind.six),
      PlayingCard(suit: Suit.clubs, kind: Kind.seven),
      PlayingCard(suit: Suit.clubs, kind: Kind.eight),
      PlayingCard(suit: Suit.clubs, kind: Kind.nine),
      PlayingCard(suit: Suit.clubs, kind: Kind.ten),
      PlayingCard(suit: Suit.clubs, kind: Kind.jack),
      PlayingCard(suit: Suit.clubs, kind: Kind.queen),
      PlayingCard(suit: Suit.clubs, kind: Kind.king),
      PlayingCard(suit: Suit.spades, kind: Kind.two),
      PlayingCard(suit: Suit.spades, kind: Kind.three),
      PlayingCard(suit: Suit.spades, kind: Kind.four),
      PlayingCard(suit: Suit.spades, kind: Kind.five),
      PlayingCard(suit: Suit.spades, kind: Kind.six),
      PlayingCard(suit: Suit.spades, kind: Kind.seven),
      PlayingCard(suit: Suit.spades, kind: Kind.eight),
      PlayingCard(suit: Suit.spades, kind: Kind.nine),
      PlayingCard(suit: Suit.spades, kind: Kind.ten),
      PlayingCard(suit: Suit.spades, kind: Kind.jack),
      PlayingCard(suit: Suit.spades, kind: Kind.queen),
      PlayingCard(suit: Suit.spades, kind: Kind.king),
    ];
    allCards.shuffle();

    cards = [
      [
        PlayingCard(suit: Suit.hearts, kind: Kind.ace),
        null,
        ...allCards.sublist(0, 12),
      ],
      [
        PlayingCard(suit: Suit.diamonds, kind: Kind.ace),
        null,
        ...allCards.sublist(12, 24),
      ],
      [
        PlayingCard(suit: Suit.clubs, kind: Kind.ace),
        null,
        ...allCards.sublist(24, 36),
      ],
      [
        PlayingCard(suit: Suit.spades, kind: Kind.ace),
        null,
        ...allCards.sublist(36, 48),
      ],
    ];

    state = GameState.move;
    shufflesLeft = 3;
    notifyListeners();
  }

  void moveCard(int row, int column) {
    final prevCard = cards[row][column - 1];
    if (prevCard == null) return;

    final nextCard = prevCard.next();
    if (nextCard == null) return;

    var nextRow = -1;
    var nextColumn = -1;
    for (final row in cards.asMap().entries) {
      for (final card in row.value.asMap().entries) {
        if (card.value?.equals(nextCard) ?? false) {
          nextRow = row.key;
          nextColumn = card.key;
        }
      }
    }

    cards[row][column] = cards[nextRow][nextColumn];
    cards[nextRow][nextColumn] = null;

    var hasMove = false;
    outer:
    for (final row in cards.asMap().entries) {
      for (final card in row.value.asMap().entries) {
        if (card.value != null) continue;
        final prevCard = cards[row.key][card.key - 1];
        if (prevCard == null) continue;
        if (prevCard.kind != Kind.king) {
          hasMove = true;
          break outer;
        }
      }
    }

    if (!hasMove) {
      var hasError = false;
      for (final row in cards.asMap().entries) {
        PlayingCard? expected = PlayingCard(
          suit: suitByIndex(row.key),
          kind: Kind.ace,
        );
        for (final card in row.value) {
          if (card == null ? expected != null : !card.equals(expected)) {
            hasError = true;
            break;
          }
          if (expected != null) expected = expected.next();
        }
      }

      if (!hasError) {
        state = GameState.win;

        final newGames = (games ?? 0) + 1;
        final newWins = (wins ?? 0) + 1;
        prefs?.setInt(gamesStorageKey, newGames);
        prefs?.setInt(winsStorageKey, newWins);

        games = newGames;
        wins = newWins;
      } else if (shufflesLeft == 0) {
        state = GameState.loss;

        final newGames = (games ?? 0) + 1;
        prefs?.setInt(gamesStorageKey, newGames);

        games = newGames;
      } else {
        state = GameState.shuffle;
      }
    }

    notifyListeners();
  }

  void shuffle() {
    final cardsToShuffle = <PlayingCard>[];

    for (final row in cards.asMap().entries) {
      PlayingCard? expected = PlayingCard(
        suit: suitByIndex(row.key),
        kind: Kind.ace,
      );

      for (final card in row.value.asMap().entries) {
        final cardValue = card.value;
        if (cardValue == null
            ? expected != null
            : !cardValue.equals(expected)) {
          for (var i = card.key; i < cards[row.key].length; i++) {
            final shuffleCard = cards[row.key][i];
            if (shuffleCard != null) cardsToShuffle.add(shuffleCard);
          }
          cards[row.key].removeRange(card.key, 14);
          break;
        }
        if (expected != null) expected = expected.next();
      }
    }

    cardsToShuffle.shuffle();

    for (final row in cards) {
      if (row.length == 14) continue;

      row.add(null);
      while (row.length < 14) {
        row.add(cardsToShuffle.removeAt(0));
      }
    }

    state = GameState.move;
    shufflesLeft -= 1;

    notifyListeners();
  }

  Suit suitByIndex(int index) {
    switch (index) {
      case 0:
        return Suit.hearts;
      case 1:
        return Suit.diamonds;
      case 2:
        return Suit.clubs;
      case 3:
        return Suit.spades;
    }
    throw Exception("Bad index $index");
  }

  void reset() {
    if (state != GameState.win && state != GameState.loss) {
      final newGames = (games ?? 0) + 1;
      prefs?.setInt(gamesStorageKey, newGames);
      games = newGames;
    }

    cards = [];
    state = GameState.move;
    shufflesLeft = 0;

    notifyListeners();
  }
}

enum GameState {
  move,
  shuffle,
  win,
  loss,
}

class Game extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>();

    return Scaffold(
      body: SafeArea(
        child: state.cards.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => state.init(),
                      child: Text("Start"),
                    ),
                    if (state.games != null) ...[
                      Text("Games played: ${state.games}"),
                      Text("Games won: ${state.wins}"),
                    ]
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...state.cards.asMap().entries.map((row) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.value.asMap().entries.map((card) {
                        return card.value ??
                            Padding(
                              padding:
                                  defaultTargetPlatform == TargetPlatform.iOS
                                      ? EdgeInsets.zero
                                      : EdgeInsets.only(left: 7, right: 7),
                              child: ElevatedButton(
                                onPressed: () {
                                  state.moveCard(row.key, card.key);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: cardBorder,
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(4),
                                ),
                                child: SizedBox(
                                  height: cardHeight,
                                  width: cardWidth,
                                ),
                              ),
                            );
                      }).toList(),
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.state == GameState.win
                          ? "You Win!"
                          : state.state == GameState.loss
                              ? "Game Over!"
                              : "${state.shufflesLeft} shuffles left"),
                      if (state.state == GameState.shuffle) ...[
                        SizedBox(width: 24),
                        ElevatedButton(
                          child: Text("Shuffle"),
                          onPressed: () {
                            state.shuffle();
                          },
                        ),
                      ],
                      SizedBox(width: 24),
                      ElevatedButton(
                        child: Text("Reset"),
                        onPressed: () {
                          state.reset();
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.suit,
    required this.kind,
  });

  final Suit suit;
  final Kind kind;

  bool equals(PlayingCard? other) {
    return other == null ? false : kind == other.kind && suit == other.suit;
  }

  PlayingCard? next() {
    final nextKind = kind.next;
    if (nextKind == null) return null;
    return PlayingCard(suit: suit, kind: nextKind);
  }

  @override
  Widget build(BuildContext context) {
    Icon icon;
    switch (suit) {
      case Suit.hearts:
        icon = Icon(
          Icons.favorite,
          color: Colors.red,
        );
        break;
      case Suit.diamonds:
        icon = Icon(
          Icons.diamond,
          color: Colors.red,
        );
        break;
      case Suit.clubs:
        icon = Icon(Icons.spa);
        break;
      case Suit.spades:
        icon = Icon(Icons.energy_savings_leaf_rounded);
        break;
    }

    return Card(
      shape: cardBorder,
      margin: EdgeInsets.only(
        left: 7,
        right: 7,
        bottom: 4,
        top: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: cardHeight,
          width: cardWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon, Text(kind.symbol)],
          ),
        ),
      ),
    );
  }
}

enum Suit {
  hearts,
  diamonds,
  clubs,
  spades,
}

enum Kind {
  ace(symbol: "A", next: Kind.two),
  two(symbol: "2", next: Kind.three),
  three(symbol: "3", next: Kind.four),
  four(symbol: "4", next: Kind.five),
  five(symbol: "5", next: Kind.six),
  six(symbol: "6", next: Kind.seven),
  seven(symbol: "7", next: Kind.eight),
  eight(symbol: "8", next: Kind.nine),
  nine(symbol: "9", next: Kind.ten),
  ten(symbol: "10", next: Kind.jack),
  jack(symbol: "J", next: Kind.queen),
  queen(symbol: "Q", next: Kind.king),
  king(symbol: "K");

  const Kind({
    required this.symbol,
    this.next,
  });

  final String symbol;
  final Kind? next;
}

const double cardHeight = 48;
const double cardWidth = 26;

const RoundedRectangleBorder cardBorder = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
  side: BorderSide(),
);

const gamesStorageKey = "games";
const winsStorageKey = "wins";
