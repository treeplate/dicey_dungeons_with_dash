import 'package:dice_icons/dice_icons.dart';
import 'package:dicey_dungeons_with_dash/logic.dart';
import 'package:flutter/material.dart';

const Color darkRed = Color.fromARGB(255, 125, 20, 12);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DashBird dashbird = DashBird(
    30,
    2,
    [
      [
        SwordMachine(),
        RerollMachine(),
      ],
    ],
    lose,
    () => setState(() {}),
  );
  late Player opponent = AngryCow(
    20,
    2,
    [
      [
        ChargeMachine(),
      ],
    ],
    win,
    () => setState(() {}),
  );
  late Set<Die> oldDice = dashbird.dice.toSet();

  bool seeEnemyMoves = false;

  bool lose() {
    showDialog(
      context: context,
      builder: (context) {
        return BoilerplateDialog(
          title: 'You Lose!',
          children: [
            Text(
                "${dashbird.name} is dead! You brought ${opponent.name} down to ${opponent.health} out of ${opponent.maxHealth} health."),
            const Text("Click out of the dialog to restart."),
          ],
        );
      },
    );
    reset();
    return true;
  }

  bool win() {
    showDialog(
      context: context,
      builder: (context) {
        return BoilerplateDialog(
          title: 'You Win!',
          children: [
            Text(
                "${opponent.name} is dead! You are down to ${dashbird.health} out of ${dashbird.maxHealth} health."),
            const Text(
                "This is currently the end of my prototype. Click out of the dialog to restart."),
          ],
        );
      },
    );
    reset();
    return true;
  }

  void reset() {
    setState(() {
      opponent.health = opponent.maxHealth;
      opponent.abilityProgress = 0;
      for (List<Machine> element in opponent.machines) {
        for (Machine element in element) {
          for (DieSlot element in element.dieSlots) {
            element is CountdownDieSlot
                ? element.countdown = element.maxCountdown
                : null;
          }
        }
      }
      dashbird.health = dashbird.maxHealth;
      dashbird.abilityProgress = 0;
      if (dashbird.turnHappening) {
        dashbird.endTurn();
      } else if (opponent.turnHappening) {
        opponent.endTurn();
      }
      dashbird.startTurn();
      oldDice.addAll(dashbird.dice);
    });
  }

  @override
  void initState() {
    dashbird.startTurn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Expanded(flex: 1, child: Text('unimplemented: corner')),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: opponent.dice
                        .map((e) =>
                            dieWidget(e, !oldDice.contains(e), e.size * 80, 80))
                        .toList(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                      onPressed: () {
                        setState(() {
                          seeEnemyMoves = !seeEnemyMoves;
                        });
                      },
                      child: Text(
                          seeEnemyMoves ? 'see own moves' : 'see enemy moves')),
                ),
                Expanded(
                    flex: 1,
                    child: CharacterStats(
                      player: opponent,
                      opponent: dashbird,
                      setState: setState,
                    )),
                renderPlayer(opponent),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (seeEnemyMoves ? opponent : dashbird)
                  .machines
                  .map(
                    (e) => Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: e
                          .map((f) => renderMachine(dashbird, f, opponent,
                              setState, endTurn, oldDice))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                renderPlayer(dashbird),
                Expanded(
                  flex: 1,
                  child: CharacterStats(
                    player: dashbird,
                    opponent: opponent,
                    setState: setState,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: dashbird.dice
                        .map((e) =>
                            dieWidget(e, !oldDice.contains(e), e.size * 80, 80))
                        .toList(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                    child: const Row(children: [
                      Text('End Turn'),
                      Icon(Icons.arrow_forward)
                    ]),
                    onPressed: () {
                      setState(endTurn);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void endTurn() {
    dashbird.endTurn();
    opponent.startTurn();
    oldDice.addAll(opponent.dice);
    seeEnemyMoves = true;
    void onValue(value) {
      if (opponent.dice.every((element) => element.usable == false)) {
        setState(() {
          if (!opponent.turnHappening) return;
          opponent.endTurn();
          dashbird.startTurn();
          oldDice.addAll(dashbird.dice);
          seeEnemyMoves = false;
        });
      } else {
        insertDie(
            opponent.dice.firstWhere((element) => element.usable),
            setState,
            (a) => a
                ? opponent.machines.single.single.standby[0] =
                    opponent.dice.firstWhere((element) => element.usable)
                : opponent.machines.single.single.standby[0] = null,
            opponent,
            dashbird,
            oldDice,
            () {},
            opponent.machines.single.single);
        Future.delayed(const Duration(seconds: 1)).then(onValue);
      }
    }

    Future.delayed(const Duration(seconds: 1)).then(onValue);
  }
}

class CharacterStats extends StatelessWidget {
  const CharacterStats({
    super.key,
    required this.player,
    required this.opponent,
    required this.setState,
  });

  final Player player;
  final Player opponent;
  final void Function(void Function()) setState;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(player.name),
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: darkRed,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.green,
                    ),
                    width: constraints.maxWidth *
                        (player.oldHealth / player.maxHealth),
                  );
                },
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: player.health == player.maxHealth
                          ? const BorderRadius.all(Radius.circular(10))
                          : const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10)),
                      color: Colors.red,
                    ),
                    width: constraints.maxWidth *
                        (player.health / player.maxHealth),
                  );
                },
              ),
              Center(child: Text('${player.health}/${player.maxHealth}')),
            ],
          ),
        ),
        if (player.hasAbility)
          Expanded(
            flex: 1,
            child: Tooltip(
              message: player.abilityDescription,
              child: TextButton(
                onPressed: player.abilityProgress == 1
                    ? () {
                        setState(() {
                          player.ability(opponent);
                          Future.delayed(const Duration(milliseconds: 250))
                              .then((value) => setState(() {
                                    player.oldHealth = player.health;
                                    player.oldAbilityProgress =
                                        player.abilityProgress;
                                    opponent.oldHealth = opponent.health;
                                    opponent.oldAbilityProgress =
                                        opponent.abilityProgress;
                                  }));
                        });
                      }
                    : null,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color.fromARGB(255, 101, 91, 0)),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.green,
                          ),
                          width: constraints.maxWidth * player.abilityProgress,
                        );
                      },
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: player.oldAbilityProgress == 1
                                ? const BorderRadius.all(Radius.circular(10))
                                : const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomLeft: Radius.circular(10)),
                            color: const Color.fromARGB(255, 188, 171, 18),
                          ),
                          width:
                              constraints.maxWidth * (player.oldAbilityProgress),
                        );
                      },
                    ),
                    Center(child: Text(player.abilityName)),
                  ],
                ),
              ),
            ),
          ),
        const Expanded(child: SizedBox.expand()),
      ],
    );
  }
}

Widget renderPlayer(Player player) {
  switch (player) {
    case DashBird():
      return Image.asset(
        'dash.png',
      );
    case AngryCow():
      return Image.asset(
        scale: .01,
        'cow.png',
      );
  }
}

Widget renderMachine(
    Player player,
    Machine machine,
    Player opponent,
    void Function(void Function()) setState,
    void Function() endTurn,
    Set<Die> oldDice) {
  if (machine.hidden) return Container();
  switch (machine) {
    case SwordMachine():
      return MachineWidget(
        machine,
        setState: setState,
        player: player,
        opponent: opponent,
        endTurn: endTurn,
        oldDice: oldDice,
        color1: Colors.red,
        color2: darkRed,
      );
    case RerollMachine():
      return MachineWidget(
        machine,
        setState: setState,
        player: player,
        opponent: opponent,
        endTurn: endTurn,
        oldDice: oldDice,
        color1: Colors.grey,
        color2: const Color.fromARGB(255, 64, 63, 63),
      );
    case ChargeMachine():
      return MachineWidget(
        machine,
        setState: setState,
        player: player,
        opponent: opponent,
        endTurn: endTurn,
        oldDice: oldDice,
        color1: Colors.red,
        color2: darkRed,
      );
  }
}

class MachineWidget extends StatefulWidget {
  const MachineWidget(
    this.machine, {
    super.key,
    required this.setState,
    required this.player,
    required this.opponent,
    required this.endTurn,
    required this.oldDice,
    required this.color1,
    required this.color2,
  });

  final Player player;
  final Machine machine;
  final Player opponent;
  final void Function(void Function()) setState;
  final void Function() endTurn;
  final Set<Die> oldDice;
  final Color color1;
  final Color color2;

  @override
  State<MachineWidget> createState() => _MachineWidgetState();
}

class _MachineWidgetState extends State<MachineWidget> {
  Die? hoveringDie;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: widget.color1,
      ),
      child: Column(
        children: [
          Text(widget.machine.name),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: widget.color2,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  children: [
                    for (DieSlot target in widget.machine.dieSlots)
                      DragTarget<Die>(
                        builder: (BuildContext context,
                            List<Die?> candidateData,
                            List<dynamic> rejectedData) {
                          if (widget.machine.standby[
                              widget.machine.dieSlots.indexOf(target)] is Die) {
                            return dieWidget(
                                widget
                                    .machine
                                    .standby[widget.machine.dieSlots
                                        .indexOf(target)]!
                                    .copyWith(visible: true)!,
                                false,
                                80,
                                80);
                          }
                          switch (target) {
                            case NormalDieSlot():
                              return const Icon(
                                DiceIcons.dice0,
                                size: 80,
                              );
                            case CountdownDieSlot():
                              return Stack(
                                children: [
                                  const Icon(
                                    DiceIcons.dice0,
                                    size: 80,
                                  ),
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Center(
                                        child: Text(
                                      target.countdown.toString(),
                                      style: const TextStyle(fontSize: 60),
                                    )),
                                  ),
                                ],
                              );
                          }
                        },
                        onWillAccept: (Die? data) {
                          setState(() {
                            hoveringDie = data;
                          });
                          return data != null;
                        },
                        onAccept: (Die data) {
                          insertDie(
                              data,
                              widget.setState,
                              (a) => a
                                  ? widget.machine.standby[0] = hoveringDie
                                  : widget.machine.standby[0] = hoveringDie = null,
                              widget.player,
                              widget.opponent,
                              widget.oldDice,
                              widget.endTurn,
                              widget.machine);
                        },
                        onLeave: (die) {
                          setState(() {
                            hoveringDie = null;
                          });
                        },
                      ),
                    Text(
                      widget.machine.description.replaceAll(
                        '<> ',
                        hoveringDie != null ? '${hoveringDie?.number} ' : '🎲',
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void insertDie(
    Die data,
    void Function(void Function()) setState,
    void Function(bool) setAcc,
    Player player,
    Player opponent,
    Set<Die> oldDice,
    void Function() endTurn,
    Machine machine) {
  setState(() {
    setAcc(true);
    data.visible = false;
  });
  Future.delayed(const Duration(milliseconds: 250)).then((v) {
    setState(() {
      setAcc(false);
      if (player.activate(data, machine, opponent)) {
        endTurn();
      }
      Future.delayed(const Duration(milliseconds: 250)).then(
        (value) => setState(
          () {
            opponent.oldHealth = opponent.health;
            player.oldHealth = player.health;
            opponent.oldAbilityProgress = opponent.abilityProgress;
            player.oldAbilityProgress = player.abilityProgress;
            oldDice.addAll(player.dice);
            oldDice.addAll(opponent.dice);
          },
        ),
      );
    });
  });
}

Widget dieWidget(Die die, bool newDie, double width, double height) {
  switch (die.number) {
    case 1:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice1,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice1,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    case 2:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice2,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice2,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    case 3:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice3,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice3,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    case 4:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice4,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice4,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    case 5:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice5,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice5,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    case 6:
      return Draggable<Die>(
        data: die,
        feedback: Icon(
          DiceIcons.dice6,
          size: width,
        ),
        childWhenDragging: SizedBox(
          width: width,
          height: height,
        ),
        child: die.usable && die.visible
            ? Icon(
                color: newDie ? Colors.green : null,
                DiceIcons.dice6,
                size: width,
              )
            : SizedBox(
                width: width,
                height: height,
              ),
      );
    default:
      assert(false, 'contract violation');
      throw ();
  }
}

class BoilerplateDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const BoilerplateDialog(
      {super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }
}
