(

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
~bo.div(2, 1, 3); // manual I layer 1 division wit
~bo.div(2, 1, 3, false);

// chan, layer, div, register(s), clear
~bo.divReg(2, 1, 3, 1, false);
~bo.divReg(2, 1, 3, [1, 3, 4]);
~bo.divReg(2, 1, 3, [1, 3, 4], false);


// example: looping notes

(
~bo.reg(0, 1, 36); // stop 36 on pedals, layer 1
~duration = 0.1;
~pause = 0.05;
~play = {
	var note;
	inf.do { arg index;
		note = 36 + (index%31);
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
~bo.delay(1, 2, 50);

// layer 3 with one register and a delay of 70ms
~bo.reg(1, 3, 60);
~bo.delay(1, 3, 70);

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




/* ----------------------------- OSC Documentation Utopa Baroque Organ -----------------------------

The console has a DHCP server with IP 192.168.0.60. Just connect an ethernet cable, set your computer to work with DHCP in the network settings, and it should receive an IP from the console. Then send your OSC to IP 192.168.0.1 on port 1803.

General:
	Manuals are counted from 0, so pedals is 0, manuals 1, 2, 3 are numbers 1, 2, 3. Layers per manual are counted from 1.
	OSC messages are comma separated lists, starting with the OSC tag and then the arguments. For example /M2/L4/V, 1, 60

Notes:
	Starting note 60 on pedals, layer 1:
		/M0/L1/V, 1, 60
		(tag, velocity from 0-1, note number)
	Stopping a note is sending velocity 0:
		/M0/L1/V, 0, 60
	Starting multiple notes:
		/M0/L1/V, 1, 60, 61, 75, 98
		(the velocity is the same for all notes)
	Omitting the layer information will trigger the note on all layers on that manual:
		/M0/V, 1, 60

Stops for Utopa (registers) (a list of stop numbers and ranges below):
	Adding stop 36 to manual 2, layer 4:
		/M2/L4/S, 36
	Removing stop 36 from manual 2, layer 4:
		/M2/L4/S, -36
	Adding multiple stops:
		 /M0/L1/S, 40, 43
	Clearing all stops and adding multiple:
		 /M0/L1/S, 0, 40, 43

Stops for Sauer (not tested by me) (Sauer works in divisions: grey, green, white, etc and stops within those divisions, details below):
	First enable a division for a manual/layer (division 2 in this case):
		/M0/L1/D, 2
	Then add registers 12 and 13 to this division:
		/M0/L1/D2/S, 12, 13
	First clearing out all divisions/stops can be done again by adding a 0:
		/M0/L1/D, 0, 2
		and
		/M0/L1/D2/S, 0, 12, 13

Panic (stopping all notes and clearing out all stops):
	/panic

Adding a layer to a manual (there are 4 layers by default; if you want to use more, you first have to add them before you can set a stop):
	Adding 2 layers to manual 3, you have you add a layer twice:
		/M3/createLayer
		/M3/createLayer

The following messages are confirmed by Wouter to work:

	/M2/L1/Transpose, 12, "on"
	(the number is in semitones)

	/M2/L1/Delay, 2, "on"
	(the integer is in milliseconds)

	/M2/L1/Staccato, 25, "on"
	(the integer is in milliseconds)

	/M2/L1/Prolong, 0.2, "on"
	(the integer is in milliseconds)

	/M2/L1/PulseFreq, 0.0, "on"
		mapping: 0.0 - 1.0 linear from 245ms to 5ms, -1.0 - 0.0 linear from 5bpm to 245bpm

	/M2/L1/PulseWidth, 0.2, "on"

The following messages I have barely tested (the info is raw, from the developers from Sinua):

The pedals (not the pedals manual, but the 4 big pedals):
/SP0, 1.0

Tremolo, there are two:
/TremHW and /TremOW

/TremOW, "on"
/TremOW, "off"
/TremOW, "200ms" // frequency
/TremOW, "100bpm" // bpm
/TremOW, "68%" // pulse width
/TremOW, 0.68 // pulse width
/TremOW, "on", "30%", "100ms"
/TremOW, "false", 0.7, "200bpm"

/M2/L1/VelMin, 0.2, "on"
/M2/L1/VelMax, 0.2, "on" // only notes between these velocities will be accepted
/M2/L1/Left, 0.2, "on"
/M2/L1/Right, 0.2, "on" // only notes between these pitches will be accepted
/M2/L1/Sostenuto, 0.2, "on" // notes with velocity above this value will clear all, lower will toggle notes
/M2/L1/Midi, 0, "on" // int = channel, 0=off
/M2/L1/DynWidth, 0.2, "on" // not yet ready, will set the width of the dynamic range (for magnet speed)
/M2/L1/DynCenter, 0.2, "on" // not yet ready, will set the center of that range (for magnet speed)
why this? -> set the width to 0.0, and you can "move" active magnets all at once by altering the center value.

Stops Utopa:
// Hauptwerk
	\burdun_16, 36,
	\principal_8, 37,
	\rohrflott_8, 38,
	\quintathen_8, 39,
	\octav_4, 40,
	\gemshorn_4, 41,
	\weit_pfeiffe_2, 42,
	\sexquint_altra_2fach, 43,
	\mixtur_5fach, 44,
	\cymbel_3fach, 45,
	\cornett_4fach, 46,
	\fagott_16, 47,
	\trompet_8, 48,
// Oberwerk
	\gedackt_8, 49,
	\violdi_gamba_8, 50,
	\unda_maris_8, 51,
	\principal_4, 52,
	\rohrflott_4, 53,
	\nassat_3, 54,
	\octav_2, 55,
	\waldflott_2, 56,
	\tertia_1, 57,
	\quinta_1, 58,
	\sufflott_1, 59,
	\scharff_4fach, 60,
	\vox_humana_8, 61,
// Pedals
	\principal_16, 62,
	\subbass_16, 63,
	\quint_bass_12, 64,
	\octav_8, 65,
	\posaune_16, 66,
	\posaune_8, 67,
	\clarin_4, 68

Ranges Utopa per register (upper range is 85, but will be 92, don't know when):

	36: [ 36, (upper range) ],
	37: [ 36, (upper range) ],
	38: [ 36, (upper range) ],
	39: [ 36, (upper range) ],
	40: [ 36, (upper range) ],
	41: [ 36, (upper range) ],
	42: [ 36, (upper range) ],
	43: [ 36, (upper range) ],
	44: [ 36, (upper range) ],
	45: [ 36, (upper range) ],
	46: [ 59, (upper range) ],
	47: [ 36, (upper range) ],
	48: [ 36, (upper range) ],

	49: [ 36, (upper range) ],
	50: [ 36, (upper range) ],
	51: [ 56, (upper range) ],
	52: [ 36, (upper range) ],
	53: [ 36, (upper range) ],
	54: [ 36, (upper range) ],
	55: [ 36, (upper range) ],
	56: [ 36, (upper range) ],
	57: [ 36, (upper range) ],
	58: [ 36, (upper range) ],
	59: [ 36, (upper range) ],
	60: [ 36, (upper range) ],
	61: [ 36, (upper range) ],

	62: [ 36, 66 ],
	63: [ 36, 66 ],
	64: [ 36, 66 ],
	65: [ 36, 66 ],
	66: [ 36, 66 ],
	67: [ 36, 66 ],
	68: [ 36, 66 ],

divisions Sauer:

	1 grijs
		13 15 16 17
	2 groen
		12 14 18 19 20
	3 wit
		1 3 4 7 8 11 21 (motor)
	4 paars
		2 5 6 9 10
	5 geel
		22 23 24 25 26 27 28 29 (tremulant)
	6 roze
		30 31 32 33 34 35

*/

/* ----------------------------- Random notes -----------------------------

White buttons beneath Sauer Division buttons:
8' should be on all the time
4' adds an octave above
16' adds an octave below

*/


/* ----------------------------- MIDI Documentation Utopa Baroque Organ -----------------------------

Pedals respond to MIDI notes on channel 1, Manuals 1, 2, 3 correspond to MIDI channels 2, 3, 4.

MIDI channels 14, 15, and 16 are meant for control data.
See the console_inputs MIDI.pdf document for the mapping. Notes for that document:
	MIDI note numbers are in the left column, but you have to subtract 1
		(so for example you can switch on stop Dulciana on the Sauer with MIDI note 0 on channel 14)
	The numbers 1-128 are for MIDI channel 14, the numbers 129-256 are for MIDI channel 15
	It is as yet unclear how to reach numbers 257-383 (channel 16 seems logical, but not working)






*/












