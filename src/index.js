import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

const storageKey = 'post-app-save'
const storedState = localStorage.getItem(storageKey);
console.log("Retrieved state: ", storedState);
const startingState = storedState ? storedState : null;

var app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: startingState
});

app.ports.storeEvents.subscribe(value => {
  console.log('hit storeEvents in js');
  localStorage.setItem(storageKey, value);
})


// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
