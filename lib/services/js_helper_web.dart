import 'dart:js' as js;

void playWebCoinSound() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        function playCoin(delay, freq, dur, vol) {
          var osc = audioCtx.createOscillator();
          var gain = audioCtx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(freq, audioCtx.currentTime + delay);
          osc.frequency.exponentialRampToValueAtTime(freq * 1.5, audioCtx.currentTime + delay + dur * 0.3);
          gain.gain.setValueAtTime(vol, audioCtx.currentTime + delay);
          gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + delay + dur);
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start(audioCtx.currentTime + delay);
          osc.stop(audioCtx.currentTime + delay + dur);
        }
        playCoin(0.00, 1046, 0.12, 0.4);
        playCoin(0.10, 1318, 0.10, 0.35);
        playCoin(0.18, 1568, 0.08, 0.30);
        playCoin(0.25, 2093, 0.15, 0.45);
      })();
      '''
    ]);
  } catch (e) {
    // Fail silently in release or log
  }
}
