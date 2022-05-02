import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
console.log("WE ARE GETTING HERE AT LEAST")
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
const accChris = await stdlib.newTestAccount(startingBalance);

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);
const beforeChris = await getBalance(accChris);
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());
const ctcChris = accChris.contract(backend, ctcAlice.getInfo());

const showBalance = async (acc) => console.log(`Your balance is ${await stdlib.balanceOf(acc)}`)
console.log(`The consensus network we are using is ${stdlib.connector}`)

const OUTCOME = ['Draw', 'Alice wins', 'Bob wins', 'Chris wins'];
const Player = (Who) => ({
  ...stdlib.hasRandom,
  getHand: () => {
    const hand = Math.floor(Math.random() * 5);
    console.log(`${Who} played ${hand}`);
    return hand;
  },
  getGuess: () => {
    const guess = Math.floor(Math.random() * 10);
    console.log(`${Who} guessed ${guess}`)
    return guess;
  },
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
  },
  informTimeout: () => {
    console.log("There has been a timeout - this should never happen")
  }
});

await Promise.all([
  ctcAlice.p.Alice({
    ...Player('Alice'),
    wager: stdlib.parseCurrency(5),
    deadline: 10
  }),
  ctcBob.p.Bob({
    ...Player('Bob'),
    acceptWager: (amt) => {
      console.log(`Bob accepts the wager of ${fmt(amt)}.`);
    },
  }),
  ctcChris.p.Chris({
    ...Player('Chris'),
    acceptWager: (amt) => {
      console.log(`Chris accepts the wager of ${fmt(amt)}`)
    }
  })
]);

const afterAlice = stdlib.parseCurrency(await getBalance(accAlice));
const afterBob = await getBalance(accBob);
const afterChris = await getBalance(accChris);

console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went from ${beforeBob} to ${afterBob}.`);
console.log(`Chris went from ${beforeChris} to ${afterChris}`)