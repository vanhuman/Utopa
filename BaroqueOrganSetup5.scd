(

// MOTU volume -15db

// ------------ Setup environment ------------
// connect with DHCP to server 192.168.0.60

if(~bo.notNil, { ~bo.clearAll() });

~bo = EM(); // functions in an EM always have the environment as first argument

// ~bo.addr = NetAddr.new("192.168.0.1", 1803);
// ~bo.addr = NetAddrMon.new("192.168.0.1", 1803);

~bo.addr = NetAddrMon.new("127.0.0.1", 8000);

~bo.noteOffset = 0;
~bo.chanOffset = 0;
~bo.upperRange = 85; // not sounding from 86 - 92

// setup of the basic functions
(Document.dir ++ "KP6-3.7/Lib/Definitions.scd").load();

// MIDI re-routing and some specific MIDI processing functions
// (Document.dir ++ "KP6-3.7/Lib/MidiSetup.scd").load();

// register board
(Document.dir ++ "KP6-3.7/Lib/Gui.scd").load();

)








// MIDIIn.doNoteOnAction(~bo.iac1ID, 15, 1, 27); // spoof a note on



/*

-1 5bpm 0 245 1 5
~bo.addr.sendMsg("/M1/L1/PulseFreq", 0.92, "on");
~bo.addr.sendMsg("/M1/L1/PulseWidth", 0.35);

~bo.addr.sendMsg("/M1/L1/PulseFreq", 0.92, "off");

~bo.addr.sendMsg("/SP0", 1.0);

b.sendMsg("/M2/createLayer");

// /TremHW or /TremOW

b.sendMsg("/TremOW"); // toggle

b.sendMsg("/TremOW", "on"); // (or "true", if you like)
b.sendMsg("/TremOW", "off"); // (or "false")

b.sendMsg("/TremOW", "200ms"); // frequency
b.sendMsg("/TremOW", "100bpm"); // bpm
b.sendMsg("/TremOW", "68%"); // pulse width
b.sendMsg("/TremOW", 0.68); // pulse width

b.sendMsg("/TremOW", "on", "30%", "100ms");
b.sendMsg("/TremOW", "false", 0.7, "200bpm");


Layer properties are all set with one float 0.0 .. 1.0 plus a String "on" (use any other string to turn them off)
some accept int's as stated.
b.sendMsg("/M2/L1/VelMin", 0.2, "on");
b.sendMsg("/M2/L1/VelMax", 0.2, "on"); //only notes between these velocities will be accepted
b.sendMsg("/M2/L1/Transpose", 12, "on"); // int = semitones
b.sendMsg("/M2/L1/Left", 0.2, "on");
b.sendMsg("/M2/L1/Right", 0.2, "on"); //only notes between these pitches will be accepted
b.sendMsg("/M2/L1/Delay", 2, "on"); // int = milliseconds
b.sendMsg("/M2/L1/Staccato", 25, "on"); // int = milliseconds
b.sendMsg("/M2/L1/Prolong", 0.2, "on"); // int = milliseconds
b.sendMsg("/M2/L1/PulseFreq", 0.0, "on"); // -1.0=5bpm, 1.0=5ms, 0.0=245bpm(mostly the same as 245ms). will change to tremulants behaviour later.
b.sendMsg("/M2/L1/PulseWidth", 0.2, "on");
b.sendMsg("/M2/L1/Sostenuto", 0.2, "on"); // sorry, I lost this one in the classical namespace for now... notes with velocity above this value will clear all, lower will toggle notes
looking for Sustain? see Sostenuto ;-)
b.sendMsg("/M2/L1/Midi", 0, "on"); // int = channel, 0=off
b.sendMsg("/M2/L1/DynWidth", 0.2, "on");//not yet ready, will set the width of the dynamic range (for magnet speed)
b.sendMsg("/M2/L1/DynCenter", 0.2, "on");//not yet ready, will set the center of that range (for magnet speed)
why this? -> set the width to 0.0, and you can "move" active magnets all at once by altering the center value.
b.sendMsg("/M2/createLayer");

b.sendMsg("/panic");

*/

/*
// ------------ Live Coding ------------

~bo.clearAll();
~oscOutMonitor = 1;

/*
channels: 0, 1, 2, 3
notes: 0 - 127
layers: 1 - ... or nil for all layers

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

registers Baroque Organ: 36 - 68

een noot heeft een velocity curve met een attack; bij het nogmaals sturen van de noot met een lagere velocity wordt de attack niet nogmaal uitgevoerd.
*/

// channel(s), layer(s) or nil for all channels
~bo.panic(nil);

// channel, layer, note(s), velocity
~bo.note(2, 2, 85, 127);
~bo.note(2, 2, 85, 0);
~bo.note(0, 1, 60, 0);

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
~bo.divReg(2, 1, 3, [1, 3, 4]);
~bo.divReg(2, 1, 3, [1, 3, 4], false);


// example: setting up manual I
(
// layer 1 with three registers
~bo.reg(2, 1, [36, 40, 49]);

// layer 2 with two registers and a delay of 50ms
~bo.reg(2, 2, [50, 51]);
~bo.delay(2, 2, 50);

// layer 3 with one register and a delay of 70ms
~bo.reg(2, 3, 60);
~bo.delay(2, 3, 70);

// send a note to all layers
~bo.note(2, nil, 60, 127);
)
~bo.note(2, nil, 60, 0); // stop note

*/








