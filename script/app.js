var phrases = [], elements = document.querySelectorAll('.block__lyrics span');

for (var i = 0, span; span = elements[i]; i++) {
  var time = parseFloat(span.getAttribute('data-time'));
  if (isNaN(time)) break;

  phrases.push({
    start: time,
    end: 10000,
    element: span
  });
  if (i > 0) phrases[i - 1].end = time;
}

function highlightPhrase(time) {
  for (var i = 0, span; span = elements[i]; i++) {
    span.classList.remove('highlighted');
  }

  for (var ii = 0, phrase; phrase = phrases[ii]; ii++) {
    if (phrase.start < time && phrase.end > time) {
      phrase.element.classList.add('highlighted');
    }
  }
}

function shakeOnTime(time) {
  for (var i = 0; i < shakeTimes.length; i++) {
    var shakeTime = shakeTimes[i];
    console.log(shakeTime);
    if (shakeTime > time && shakeTime < time + 0.5) {
      shake();
    }
  }
}


var shakeTimes = [10.4], lastShake = 0;
var introElement = document.querySelector('.intro');
function shake() {
  if (new Date().getTime() < lastShake + 1000) return;

  lastShake = new Date().getTime();
  var _shake = function (reset) {
    var x, y;
    if (reset) {
      x = 0;
      y = 0;
    }
    else {
      x = Math.random() * 2;
      y = Math.random() * 8;
    }
    introElement.style.transform = 'translate(' + x + 'px, ' + y + 'px)';
  };
  var delay = 30;
  for (var i = 0; i < 8; i++) {
    setTimeout(_shake, i * delay);
  }
  setTimeout(function () {
    _shake(true);
  }, i * delay);
}

// 2. This code loads the IFrame Player API code asynchronously.
var tag = document.createElement('script');

tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

// 3. This function creates an <iframe> (and YouTube player)
//    after the API code downloads.
var player;

function onYouTubeIframeAPIReady() {
  player = new YT.Player('player', {
    height: '565',
    width: '1000',
    videoId: 'ph1C-dtR8aM',
    playerVars: {
      modestbranding: 1,
      showinfo: 0,
      controls: 1,
      rel: 0
    },
    events: {
      'onReady': onPlayerReady,
      'onStateChange': onPlayerStateChange
    }
  });
}

// 4. The API will call this function when the video player is ready.
function onPlayerReady(event) {
  //event.target.playVideo();
}

// 5. The API calls this function when the player's state changes.
function onPlayerStateChange(event) {
  if (event.data == YT.PlayerState.PLAYING) {
    startFollowingTime();
  }
  else if (event.data == YT.PlayerState.PAUSED || event.data == YT.PlayerState.ENDED) {
    stopFollowingTime();
  }
}

var intervalId, intervalDelay = 25;


function startFollowingTime() {
  if (!intervalId) {
    intervalId = setInterval(_updateTime, intervalDelay);
  }
}

var lastCurrentTime = -1, exactTime;
function _updateTime() {
  var currentTime = player.getCurrentTime();
  if (currentTime != lastCurrentTime) {
    lastCurrentTime = exactTime = currentTime;
  }
  else {
    exactTime += intervalDelay / 1000;
  }
  highlightPhrase(exactTime);
  shakeOnTime(exactTime);
}

function stopFollowingTime() {
  clearInterval(intervalId);
  intervalId = null;
}

function stopVideo() {
  player.stopVideo();
}

