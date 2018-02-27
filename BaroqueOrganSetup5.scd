(

// ------------ Setup environment ------------
// connect with DHCP to server 192.168.0.60

if(~bo.notNil, { ~bo.clearAll() });

~bo = EM(); // functions in an EM always have the environment as first argument

// ~bo.addr = NetAddrMon.new("192.168.0.1", 1803);
~bo.addr = NetAddrMon.new("127.0.0.1", 8000);
~bo.noteOffset = 0;
~bo.chanOffset = 0;

// setup of the basic functions
(Document.current.dir ++ "/Lib/Definitions.scd").load();

// MIDI re-routing and some specific MIDI processing functions
(Document.current.dir ++ "/Lib/MidiSetup.scd").load();

// register board
(Document.current.dir ++ "/Lib/Gui.scd").load();

)








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










