(

// ------------ Setup environment ------------
// connect with DHCP to server 192.168.0.60

~testMode = true;

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
~bo.showSCdelayButton = true;

// setup of the basic functions
(Document.dir ++ "KP6-3.7/Lib/Definitions.scd").load();

// MIDI re-routing and some specific MIDI processing functions
(Document.dir ++ "KP6-3.7/Lib/MidiSetup.scd").load();

// register board
(Document.dir ++ "KP6-3.7/Lib/Gui.scd").load();

)








// MIDIIn.doNoteOnAction(~bo.iac1ID, 15, 1, 27); // spoof a note on

// ----------------------------- Testing -----------------------------

// OSC monitor on/off
~oscOutMonitor = 2;
~oscOutMonitor = 1;
~oscOutMonitor = 0;

// tuning
{SinOsc.ar(60.midicps)!2}.play;

// Manuals are counted from 0, so pedals is 0, manuals 1, 2, 3 are numbers 1, 2, 3. Layers per manual are counted from 1.
// Often, if the layer is omitted, parameters are set for all layers on that manual

// panic: stop all notes, remove all registers, delete all extra layers
~bo.panic();

// trigger a note
// channel, layer, note(s), velocity
~bo.note(2, 2, 85, 127);
~bo.note(2, 2, 85, 0);
~bo.note(0, 1, 60, 0);

// 3 notes to all channels
~bo.note(1, nil, [60, 62, 76], 64);
// shortcut
~bo.midinote(1, [60, 62, 76], 64);

// add registers to Utopa
// chan, layer, register(s)
~bo.reg(0, 1, [37,40]); // set only 37 and 40, remove all others
~bo.regAdd(0, 1, 51); // add register 51
~bo.regAdd(0, 1, [-40, 42]); // remove register 40 and add register 42

// add registers to Sauer in two steps: Divisions and Registers

// chan, layer, division
~bo.div(1, 1, [2, 3]); // set only divisions green (2) and white (3), remove all others
~bo.divAdd(1, 1, 1); // add division grey (1)

// chan, layer, div, register(s), clear
~bo.divReg(3, 1); // set only register 1 to division white (3), remove all other stops
~bo.divReg(3, [1, 3, 4]);
~bo.divRegAdd(3, [1, 3, 4]); // add registers 1, 3, 4 to division white (3)

// channel, layer, delay-time in milliseconds
~bo.delay(1, 1, 100);
~bo.delay(1, 1, 0); // 0 msec = delay off

// add a layer to a channel
~bo.addLayer(1);

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
~bo.reg(1, 1, [36, 40, 51]);

// layer 2 with two registers and a delay of 100ms
~bo.reg(1, 2, [41, 42]);
~bo.delay(1, 2, 100);

// layer 3 with one register and a delay of 200ms
~bo.reg(1, 3, 62);
~bo.delay(1, 3, 200);

// layer 4 with two registers and a delay of 300ms
~bo.reg(1, 4, [53, 54]);
~bo.delay(1, 4, 300);

// add a layer
~bo.addLayer(1);

// layer 5 with two registers and a delay of 400ms
~bo.reg(1, 4, [37, 38]);
~bo.delay(1, 4, 400);

)

// send a note to all layers
~bo.note(1, nil, 60, 127);

// stop note
~bo.note(1, nil, 60, 0);

// transposing
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
~bo.pulsefreq(1, 1, 0.5, \off)
~bo.pulsewidth(1, 1, 0.5)
~bo.pulsewidth(1, 1, 0.5, \off)

~bo.trem('OW', 100, 0.6);
~bo.trem('OW', 100, 0.6, \off);
~bo.trem('HW', 250, 0.6);

~bo.sostenuto(1, 1, 0.9);
~bo.sostenuto(1, 1, 0.7, \off);

~bo.sustain(1, 1, 0.9);
~bo.sustain(1, 1, 0.7, \off);

// schwell pedal 0 is Utopa air and schwell pedal 2 is the Sauer schwellchest
~bo.sp(0, 0);
~bo.sp(0, 127);
~bo.sp(2, 0);
~bo.sp(2, 127);

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

// not working
~bo.mute(1, 1);
~bo.mute(1, 1, \off);









