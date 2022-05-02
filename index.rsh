"reach 0.1";

const [isWinner, DRAW, A_WINS, B_WINS, C_WINS] = makeEnum(4);

const getWinner = (handAlice, handBob, handChris, guessAlice, guessBob, guessChris) => {
  const total = handAlice + handBob + handChris
  if ((total == guessAlice && total == guessBob) || (total == guessAlice && total == guessChris) || (total == guessBob && total == guessChris)) {
    return 0
  } else if (total == guessAlice) {
    return 1
  }  else if (total == guessBob) {
    return 2
  } else if (total == guessChris) {
    return 3
  }else {
    return 0
  }
}

const Player = {
  ...hasRandom,
  getHand: Fun([], UInt),
  getGuess: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant("Alice", {
    ...Player,
    wager: UInt,
    deadline: UInt,
  });

  const Bob = Participant("Bob", {
    ...Player,
    acceptWager: Fun([UInt], Null)
  });

  const Chris = Participant("Chris", {
    ...Player,
    acceptWager: Fun([UInt], Null)
  });

  init();

  const informTimeout = () => {
    each([Alice, Bob, Chris], () => {
      interact.informTimeout();
    })
  }

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline)
  })


  Alice.publish(wager, deadline)
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager);
  })

  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

  commit();

  Chris.only(() => {
    interact.acceptWager(wager);
  })

  Chris.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

  var winner = DRAW;
  invariant( balance() == 3*wager && isWinner(winner))
  while (winner == DRAW) {
    commit();

    Alice.only(() => {
      const _handAlice = interact.getHand();
      const _guessAlice = interact.getGuess();
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
      const [_guessCommitAlice, _guessSaltAlice] = makeCommitment(interact, _guessAlice);
      const commitAlice = declassify(_commitAlice);
      const guessCommitAlice = declassify(_guessCommitAlice);
    })

    Alice.publish(commitAlice, guessCommitAlice).timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));

    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice));
    unknowable(Bob, Alice(_guessAlice, _guessSaltAlice));

    unknowable(Chris, Alice(_handAlice, _saltAlice));
    unknowable(Chris, Alice(_guessAlice, _guessSaltAlice));

    Bob.only(() => {
      const _handBob = interact.getHand();
      const _guessBob = interact.getGuess();
      const [_commitBob, _saltBob] = makeCommitment(interact, _handBob);
      const [_guessCommitBob, _guessSaltBob] = makeCommitment(interact, _guessBob);
      const commitBob = declassify(_commitBob);
      const guessCommitBob = declassify(_guessCommitBob);
    })

    Bob.publish(commitBob, guessCommitBob).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

    commit();

    unknowable(Chris, Bob(_handBob, _saltBob));
    unknowable(Chris, Bob(_guessBob, _guessSaltBob));

    Chris.only(() => {
      const handChris = declassify(interact.getHand());
      const guessChris = declassify(interact.getGuess());
    });

    Chris.publish(handChris, guessChris).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

    commit();

    Alice.only(() => {
      const saltAlice = declassify(_saltAlice);
      const handAlice = declassify(_handAlice);
      const guessSaltAlice = declassify(_guessSaltAlice);
      const guessAlice = declassify(_guessAlice);
    })

    Alice.publish(saltAlice, handAlice, guessSaltAlice, guessAlice)
    checkCommitment(commitAlice, saltAlice, handAlice);
    checkCommitment(guessCommitAlice, guessSaltAlice, guessAlice);

    commit();

    Bob.only(() => {
      const saltBob = declassify(_saltBob);
      const handBob = declassify(_handBob);
      const guessSaltBob = declassify(_guessSaltBob);
      const guessBob = declassify(_guessBob);
    });

    Bob.publish(saltBob, handBob, guessSaltBob, guessBob);
    checkCommitment(commitBob, saltBob, handBob);
    checkCommitment(guessCommitBob, guessSaltBob, guessBob);

    winner = getWinner(handAlice, handBob, handChris, guessAlice, guessBob, guessChris);
    continue
  }

  assert(winner == A_WINS || winner == B_WINS || winner == C_WINS);
  transfer(3*wager).to(winner == A_WINS ? Alice : winner == B_WINS ? Bob : Chris);
  commit();

  each([Alice, Bob, Chris], () => {
    interact.seeOutcome(winner);
  });
});
