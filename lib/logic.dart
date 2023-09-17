import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

sealed class Player {
  String get name;
  late int health = maxHealth;
  late int oldHealth = health;
  int maxHealth;
  int diceCount;
  int rollDie();
  final List<Die> dice = [];
  final List<List<Machine>> machines;

  /// all caps
  String get abilityName;
  String get abilityDescription;
  bool get hasAbility;
  double abilityProgress = 0;
  late double oldAbilityProgress = abilityProgress;
  // returns false if the currently working machine should finish its action
  final bool Function() deadCallback;
  final void Function() updated;

  bool turnHappening = false;

  void startTurn() {
    assert(!turnHappening, 'contract violation');
    int i = 0;
    while (i < diceCount) {
      newDie();
      i++;
    }
    turnHappening = true;
  }

  void newDie() {
    dice.add(Die(rollDie()));
  }

  // returns true if there is nothing left to do
  bool activate(Die die, Machine machine, Player opponent) {
    assert(turnHappening, 'contract violation');
    assert(die.usable, 'contract violation');
    assert(dice.contains(die), 'contract violation');
    assert(machines.any((element) => element.contains(machine)),
        'contract violation');
    if (machine.activate(die, this, opponent)) {
      machine.hidden = true;
    }
    die.usable = false;
    Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (t) {
      die.size -= 0.016;
      if (die.size < 0) {
        die.size = 0;
        t.cancel();
      }

      updated();
    });
    return machines.every(
            (element) => element.every((element) => element.hidden == true)) ||
        dice.every((element) => !element.usable);
  }
  
  @mustCallSuper
  void ability(Player opponent) {
    assert(abilityProgress == 1, 'contract violation');
    abilityProgress = 0;
  }

  // returns true if this dies and deadCallback returns true
  bool reduceHealth(int number, Player? attacker) {
    oldHealth = health;
    oldAbilityProgress = abilityProgress;
    health -= number;
    abilityProgress += .1 * number;
    if (abilityProgress >= 1) {
      abilityProgress = 1;
    }
    if (health <= 0) {
      health = 0;
      return deadCallback();
    }
    return false;
  }

  void endTurn() {
    assert(turnHappening, 'contract violation');
    dice.clear();
    assert(machines.length <= 3);
    for (List<Machine> cols in machines) {
      assert(cols.length <= 2);
      for (Machine machine in cols) {
        machine.reset();
      }
    }
    turnHappening = false;
  }

  Player(this.maxHealth, this.diceCount, this.machines, this.deadCallback,
      this.updated);
}

class DashBird extends Player {
  DashBird(super.maxHealth, super.diceCount, super.machines, super.deadCallback,
      super.updated);

  final Random random = Random();

  @override
  int rollDie() {
    return random.nextInt(6) + 1;
  }

  @override
  String get name => 'Dash';

  @override
  String get abilityName => 'AERIAL POKE';
  @override
  String get abilityDescription => 'Does 6 damage.';

  @override
  bool get hasAbility => true;

  @override
  void ability(Player opponent) {
    super.ability(opponent);
    opponent.reduceHealth(6, this);
  }
}

class AngryCow extends Player {
  AngryCow(super.maxHealth, super.diceCount, super.machines, super.deadCallback,
      super.updated);

  final Random random = Random();

  @override
  int rollDie() {
    return random.nextInt(6) + 1;
  }

  @override
  String get name => 'Angry Cow';

  @override
  String get abilityName => '__Test__';
  @override
  String get abilityDescription => '__tesst__';
  @override
  bool get hasAbility => false;
}

class Die {
  int number;
  double size = 1;
  bool usable = true;
  bool visible = true;

  Die(this.number);

  copyWith({bool? visible}) {
    return Die(number)..visible = visible ?? this.visible;
  }
}

sealed class DieSlot {}

class NormalDieSlot extends DieSlot {}

class CountdownDieSlot extends DieSlot {
  late int countdown = maxCountdown;
  final int maxCountdown;
  CountdownDieSlot(this.maxCountdown);
}

sealed class Machine {
  /// all caps
  String get name;
  String get description;
  bool get tall;
  bool hidden = false;
  List<DieSlot> get dieSlots;
  late final List<Die?> standby = dieSlots.map<Die?>((e) => null).toList();

  Machine();

  bool activate(Die die, Player player, Player opponent);

  @mustCallSuper
  void reset() {
    hidden = false;
  }
}

class SwordMachine extends Machine {
  SwordMachine();

  @override
  bool activate(Die die, Player player, Player opponent) {
    return !opponent.reduceHealth(die.number, player);
  }

  @override
  bool get tall => false;

  @override
  String get description => "Do <> damage.";

  @override
  String get name => 'SWORD';

  @override
  final List<DieSlot> dieSlots = [NormalDieSlot()];
}

class RerollMachine extends Machine {
  RerollMachine();

  int uses = 3;

  @override
  bool activate(Die die, Player player, Player opponent) {
    uses--;
    player.newDie();
    return uses == 0;
  }

  @override
  void reset() {
    super.reset();
    uses = 3;
  }

  @override
  bool get tall => false;

  @override
  String get description => "Rerolls a die. ($uses uses left)";

  @override
  String get name => 'REROLL';

  @override
  final List<DieSlot> dieSlots = [NormalDieSlot()];
}

class ChargeMachine extends Machine {
  @override
  bool activate(Die die, Player player, Player opponent) {
    CountdownDieSlot dieSlot = dieSlots.single as CountdownDieSlot;
    dieSlot.countdown -= die.number;
    if (dieSlot.countdown <= 0) {
      dieSlot.countdown = dieSlot.maxCountdown;
      opponent.reduceHealth(10, player);
      return true;
    }
    return false;
  }

  @override
  String get description => 'Do 10 damage.';

  @override
  final List<DieSlot> dieSlots = [CountdownDieSlot(20)];

  @override
  String get name => 'CHARGE';

  @override
  bool get tall => true;
}
