
class RhythmPlayer {
    setBpm(newBpm) {
        this.bpm = newBpm;
    }

    startMetronome() {
        let interval = 60000 / this.bpm;
        console.log('Starting metronome at BPM:', this.bpm);

        this.metronomeAudio.play().then(() => {
            console.log('Metronome playback started');
        }).catch(error => {
            console.error('Metronome playback failed:', error);
        });

        if (this.metronomeIntervalID) {
            clearInterval(this.metronomeIntervalID);
        }

        this.metronomeIntervalID = setInterval(() => {
            this.metronomeAudio.currentTime = 0;
            this.metronomeAudio.play().catch(error => console.error('Metronome playback failed on interval:', error));
        }, interval);
    }

    stopMetronome() {
        console.log('Stopping metronome');
        if (this.metronomeIntervalID) {
            clearInterval(this.metronomeIntervalID);
        }

        this.metronomeAudio.pause();
        this.metronomeAudio.currentTime = 0;
    }

    adjustMetronome(bpm) {
        if (this.metronomeIntervalID) {
            clearInterval(this.metronomeIntervalID);
            this.setBpm(bpm);
            this.startMetronome();
        }
    }
    
    constructor(audioContext, bpm) {
        // Try to initialize the AudioContext with cross-browser support
        if (window.AudioContext) {
            this.audioContext = new AudioContext();
        } else if (window.webkitAudioContext) { // Fallback for Safari and older browsers
            this.audioContext = new webkitAudioContext();
        } else {
            console.error("AudioContext is not supported in this browser.");
            this.audioContext = null; // Ensure we don't try to use an undefined object
        }

        this.bpm = bpm;
        this.metronomeAudio = new Audio('metronome_click.mp3');
        this.metronomeAudio.volume = 1;
        this.metronomeIntervalID = null;
    }

    getPatternDuration(patternName) {
       const quarterNote = 60000 / this.bpm;
       const patterns = {
           "kwart": [quarterNote],
           "8e noot - 8e noot": [quarterNote / 2, quarterNote / 2],
           "16e noot - 8e noot punt": [quarterNote / 4, quarterNote / 4 * 3],
           "8e noot punt - 16e noot": [quarterNote / 4 * 3, quarterNote / 4],
           "8e rust - 16e noot - 16e noot": [-quarterNote / 2, quarterNote / 4, quarterNote / 4],
           "16e rust - 16e noot - 16e rust - 16e noot": [-quarterNote / 4, quarterNote / 4, -quarterNote / 4, quarterNote / 4],
           "16e rust - 16e noot - 16e noot - 16e rust": [-quarterNote / 4, quarterNote / 4, quarterNote / 4, -quarterNote / 4]
       };
       
       return patterns[patternName] || [];
    }
    
    playPattern(patternName) {
      console.log(`playPattern current AudioContext Time: ${this.audioContext.currentTime.toFixed(3)}s`);
        const patternDurations = this.getPatternDuration(patternName);
        let cumulativeTime = 0; // Initialize cumulative time for the pattern in milliseconds
    
        console.log(`Starting Pattern: ${patternName} at Current Time = ${this.audioContext.currentTime.toFixed(3)}s`);
    
        patternDurations.forEach((duration) => {
            if (duration < 0) { // Properly handle rests
                console.log(`Rest: Duration = ${-duration / 1000}s at Time = ${cumulativeTime / 1000}s`); // Log the rest
                cumulativeTime += -duration; // Advance time by the rest duration (subtract the negative duration)
            } else {
                console.log(`Playing note at cumulative time ${cumulativeTime / 1000}s with duration ${duration / 1000}s`);
                this.playNote(duration, cumulativeTime); // Only call playNote for positive durations
                cumulativeTime += duration; // Advance time by the note's duration
            }
        });
    }
    
    playNote(duration, startTime) {
      console.log(`playNote current AudioContext Time: ${this.audioContext.currentTime.toFixed(3)}s`);
        const actualStartTime = this.audioContext.currentTime + (startTime / 1000); // startTime is in ms, convert to seconds for Audio API
        const noteEffectiveDuration = duration / 1000 * 0.8; // Shorten the note duration slightly for a clear stop
        const actualStopTime = actualStartTime + noteEffectiveDuration;
    
        const oscillator = this.audioContext.createOscillator();
        oscillator.type = 'square';
        oscillator.frequency.setValueAtTime(261.6256, actualStartTime);
    
        const envelope = this.audioContext.createGain();
        oscillator.connect(envelope);
        envelope.connect(this.audioContext.destination);
    
        // Adjust the volume
        envelope.gain.setValueAtTime(0, actualStartTime);
        envelope.gain.linearRampToValueAtTime(0.1, actualStartTime + 0.01); // Volume adjusted here
        envelope.gain.setValueAtTime(0.1, actualStopTime - 0.01);
        envelope.gain.linearRampToValueAtTime(0, actualStopTime);
    
        oscillator.start(actualStartTime);
        oscillator.stop(actualStopTime);
    
        console.log(`Playing note: Start = ${actualStartTime.toFixed(3)}, Duration = ${noteEffectiveDuration.toFixed(3)}, Stop = ${actualStopTime.toFixed(3)}`);
    }
    
    
    calculateTotalDuration(patternName) {
        const durations = this.getPatternDuration(patternName);
        return durations.reduce((total, num) => total + Math.abs(num), 0);
    }
    
    playRhythmFromPattern(pattern) {
        this.startMetronome(); // Start the metronome
        this.isPlaying = true; // Flag to control the loop
    
        const measureDuration = (60000 / this.bpm) * 4; // Total duration of one measure
    
        const playEntirePattern = () => {
            let delay = 0; // Start immediately on first call
            pattern.forEach((patternName) => {
                setTimeout(() => {
                    if (!this.isPlaying) return; // Check if still playing
                    console.log("Playing rhythm for pattern:", patternName);
                    this.playPattern(patternName);
                }, delay);
                delay += this.calculateTotalDuration(patternName); // Increment delay for the next pattern part
            });
    
            setTimeout(() => {
                if (this.isPlaying) playEntirePattern(); // Loop the rhythm
            }, measureDuration);
        };
    
        playEntirePattern(); // Start the loop
    }
    
    stopRhythm() {
        this.isPlaying = false; // Set the flag to false to stop the playRhythmFromPattern() loop
        this.stopMetronome();
    }
}

window.RhythmPlayer = RhythmPlayer;

document.addEventListener('DOMContentLoaded', function() {
    // Check if AudioContext is supported
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    
    if (AudioContext) {
        // Create a new audio context
        const audioContext = new AudioContext();
        // Create a new RhythmPlayer instance
        window.rhythmPlayer = new RhythmPlayer(audioContext, 80); // Default BPM set to 80
    } else {
        console.error("AudioContext is not supported in this browser.");
    }
});

Shiny.addCustomMessageHandler('startRhythm', function(message) {
    if (window.rhythmPlayer && message) {
        console.log("Received pattern:", message);
        window.rhythmPlayer.playRhythmFromPattern(message);
    }
});

Shiny.addCustomMessageHandler('stopRhythm', function(message) {
    if (window.rhythmPlayer && message) {
        console.log("Received rhythm stopping request:", message);
        window.rhythmPlayer.stopRhythm(message);
    }
});

Shiny.addCustomMessageHandler('startMetronome', function(message) {
    if (window.rhythmPlayer) {
        window.rhythmPlayer.setBpm(message.bpm);
        window.rhythmPlayer.startMetronome();
    }
});

Shiny.addCustomMessageHandler('stopMetronome', function(message) {
    if (window.rhythmPlayer) {
        window.rhythmPlayer.stopMetronome();
    }
});

Shiny.addCustomMessageHandler('adjustMetronome', function(message) {
    if (window.rhythmPlayer) {
        window.rhythmPlayer.adjustMetronome(message.bpm);
    }
});