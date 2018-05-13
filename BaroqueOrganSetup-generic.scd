(

/*
BUGS
* Stops Sauer  "/M1/L1/S, 1" show on the screen, but don't sound; "/M1/L1/D3/S, 1" doesn't even show on the screen
* Adding layers via console nothing sounded anymore, only in edit mode, but only the first 4 layers
* swell pedals '/SP0, value' Utopa, 'SP2, value' Sauer, range 0-127
* tremolo zonder manual layer data
* mute werkt niet

email Christina over hulp na 4 juni
*/

// ----------------------------- Setup environment -----------------------------
// connect with DHCP to server 192.168.0.60

~testMode = true;
~showGui = true;

if(~bo.notNil, { ~bo.clearAll() });
~bo = EM(); // functions in an EM always have the environment as first argument

if (~testMode) {
	~bo.addr = NetAddrMon.new("127.0.0.1", 8000);
} {
	~bo.addr = NetAddrMon.new("192.168.0.1", 1803);
};
~bo.noteOffset = 0;
~bo.chanOffset = 0;
~bo.upperRange = 85; // not sounding from 86 - 92
~bo.currentDir = Document.current.dir;

// setup of the basic functions
(Document.dir ++ "KP6-3.7/Lib/Definitions.scd").load();

// register board
if (~showGui) {
	(Document.dir ++ "KP6-3.7/Lib/Gui.scd").load();
}

)

// ----------------------------- Testing -----------------------------

// OSC monitor on/off
~oscOutMonitor = 1;
~oscOutMonitor = 0;

// Manuals are counted from 0, so pedals is 0, manuals 1, 2, 3 are numbers 1, 2, 3. Layers per manual are counted from 1.

// channel(s), layer(s) or nil for all channels
~bo.panic(nil);

// channel, layer, note(s), velocity
~bo.note(2, 2, 85, 127);
~bo.note(2, 2, 85, 0);
~bo.note(0, 1, 60, 0);

// tuning
{SinOsc.ar(60.midicps)!2}.play;

~bo.note(1, nil, [60, 62, 76], 64);
~bo.midinote(1, [60, 62, 76], 64);

// chan, layer, register(s), clear
~bo.reg(0, 1, [47,49]); // channel, layer, register
~bo.regAdd(0, 1, 48); // add register 48
~bo.regAdd(0, 1, [-47, 50]); // remove register 47

// channel, layer, delay-time / 0-1 is % of 5000ms, 1-.. is absolute in ms
~bo.delay(1, 1, 10);
~bo.delay(1, 1, 0); // delay off

// channel, layer, semitones
~bo.transpose(2, nil, 5);
~bo.transpose(2, 3, 5);

// chan, layer, division, clear
~bo.div(1, 1, 3); // manual I layer 1 division wit
~bo.div(1, 1, 5, false);

// chan, layer, div, register(s), clear
~bo.divReg(1, 1, 3, 1, false);
~bo.divReg(1, 1, 3, [1, 3, 4]);
~bo.divReg(1, 1, 3, [1, 3, 4], false);


// example: looping notes

(
~duration = 0.02;
~pause = 0.01;
~play = {
	var note = 35;
	var sign = -1;
	inf.do { arg index;
		if (index%31 == 0) {
			sign = sign.neg;
		};
		note = max(36, note + sign);
		// note = rrand(36, 66);
		~bo.note(0, 1, note, 127);
		~duration.wait;
		~bo.note(0, 1, note, 0);
		~pause.wait;
	}
}.fork;
)
~play.stop;

// example: setting up manual I
(
// layer 1 with three registers
~bo.reg(1, 1, [36, 40, 49]);

// layer 2 with two registers and a delay of 50ms
~bo.reg(1, 2, [50, 51]);
~bo.delay(1, 2, 100);

// layer 3 with one register and a delay of 70ms
~bo.reg(1, 3, 60);
~bo.delay(1, 3, 170);

// layer 4 with two registers and a delay of 170ms
~bo.reg(1, 4, 42);
~bo.reg(1, 4, 43);
~bo.delay(1, 4, 170);

// add a layer
~bo.addLayer(1);

// layer 5 with two registers and a delay of 500ms
~bo.reg(1, 4, 37);
~bo.reg(1, 4, 38);
~bo.delay(1, 4, 500);

)

// send a note to all layers
~bo.note(1, nil, 60, 127);

// stop note
~bo.note(1, nil, 60, 0);

~bo.delay(0, 1, 30);
~bo.delay(0, 1, 0);

~bo.transpose(1, 2, 9);
~bo.transpose(0, 1, 0);
(
~pause = 0.1;
~transpose = {
	var semitones = 0;
	var sign = -1;
	inf.do { arg index;
		if ( index%24 == 0 ) {
			sign = sign.neg;
		};
		semitones = semitones + sign;
		~bo.transpose(1, 1, semitones);
		~pause.wait;
	};
}.fork;
)
~transpose.stop;

~bo.staccato(1, 1, 10);
~bo.staccato(1, 1, 0);

~bo.prolong(1, 1, 600);
~bo.prolong(0, 1, 0);

~bo.pulsefreq(1, 1, 0.5)
~bo.pulsefreq(1, 1, 0.5, false)
~bo.pulsewidth(1, 1, 0.5)
~bo.pulsewidth(1, 1, 0.5, false)

~bo.sp(0, 0);
~bo.sp(0, 127);
~bo.sp(1, 0);
~bo.sp(1, 127);

(
~pedal = 0;
~pause = 0.1;
~step = 1;
~sp = {
	var value = 0;
	var sign = ~step.neg;
	inf.do { arg index;
		if ( index%127 == 0 ) {
			sign = sign.neg;
		};
		value = value + sign;
		value = min(127, max(0, value));
		~bo.sp(~pedal, value);
		~pause.wait;
	};
}.fork;
)
~sp.stop;

~bo.trem('OW', 100, 0.6, true);
~bo.trem('HW', 250, 0.6, true);

~bo.sostenuto(1, 1, 0.9);
~bo.sostenuto(1, 1, 0.7, false);

// werkt niet
~bo.mute(1, 1);
~bo.mute(1, 1, false);







