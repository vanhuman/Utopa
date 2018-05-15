
// data containers ------------------------------------

~bo.ped = 0; ~bo.man1 = 1; ~bo.man2 = 2; ~bo.man3 = 3;

~bo.registers = OEM(
	// hauptwerk ----------
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
	// oberwerk ----------
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
	// pedalen ----------
	\principal_16, 62,
	\subbass_16, 63,
	\quint_bass_12, 64,
	\octav_8, 65,
	\posaune_16, 66,
	\posaune_8, 67,
	\clarin_4, 68
);

~bo.registersByNumber = ();
~bo.notesPerRegister = ();
~bo.registers.keysValuesDo { |key, value|
	~bo.registersByNumber[value] = key;
	~bo.notesPerRegister[value] = Array.newClear(127);
};
~bo.layersPerManual = (0: 0, 1: 0, 2: 0, 3: 0);

~bo.regRanges = ( // min, max, exceptions[]
	36: [ 36, ~bo.upperRange ],
	37: [ 36, ~bo.upperRange ],
	38: [ 36, ~bo.upperRange ],
	39: [ 36, ~bo.upperRange ],
	40: [ 36, ~bo.upperRange ],
	41: [ 36, ~bo.upperRange ],
	42: [ 36, ~bo.upperRange ],
	43: [ 36, ~bo.upperRange ],
	44: [ 36, ~bo.upperRange ],
	45: [ 36, ~bo.upperRange ],
	46: [ 59, ~bo.upperRange ],
	47: [ 36, ~bo.upperRange ],
	48: [ 36, ~bo.upperRange ],

	49: [ 36, ~bo.upperRange ],
	50: [ 36, ~bo.upperRange ],
	51: [ 56, ~bo.upperRange ],
	52: [ 36, ~bo.upperRange ],
	53: [ 36, ~bo.upperRange ],
	54: [ 36, ~bo.upperRange ],
	55: [ 36, ~bo.upperRange ],
	56: [ 36, ~bo.upperRange ],
	57: [ 36, ~bo.upperRange ],
	58: [ 36, ~bo.upperRange ],
	59: [ 36, ~bo.upperRange ],
	60: [ 36, ~bo.upperRange ],
	61: [ 36, ~bo.upperRange ],

	62: [ 36, 66 ],
	63: [ 36, 66 ],
	64: [ 36, 66 ],
	65: [ 36, 66 ],
	66: [ 36, 66 ],
	67: [ 36, 66 ],
	68: [ 36, 66 ],
);

~bo.registrationsPerLayer = ();
// 4 channels, max 10 layers per channel
4.do { |chan|
	~bo.registrationsPerLayer[chan] = ();
	(1..10).do { |layer|
		~bo.registrationsPerLayer[chan][layer] = Array.new(~bo.registers.size);
	};
};
~bo.notifyCount = 0;

// functions ------------------------------------

~bo.clearAll = {
	MIDIdef.freeAll;
	NetAddr.disconnectAll;
	~bo = nil;
};

~bo.chanLayer = {
	// this returns the general OSC address
	arg evt, chan, layer;
	var layerPart = if (layer.notNil, { "/L" ++ layer }, { "" });
	"/M" ++ (chan + evt.chanOffset) ++ layerPart
};

~bo.note = {
	// notes: integer or integer[]
	// layer: integer or null (all layers)
	arg evt, chan, layer, notes, val;
	var force = (val / 127).round(0.001);
	// evt.outOfRangeCheck(chan, layer, notes, val);
	// evt.checkMultipleNotesPerRegister(chan, layer, notes, val);
	// to enable the two lines above, also uncomment the line with 'evt.regStore(chan, layer, regs)' in the function ~bo.reg
	notes = notes + ~bo.noteOffset;
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/V", force, *notes);
};

~bo.midinote = {
	// send note to all layers
	arg evt, chan, notes, val;
	evt.note(chan, nil, notes, val);
};

~bo.addLayer = {
	arg evt, chan;
	evt.addr.sendMsg("/M" ++ chan ++ "/createLayer");
};

~bo.reg = {
	// set absolute registers, or relative if clear is false
	// regs: integer or integer[], a negative number meaning 'remove stop'
	arg evt, chan, layer, regs, clear = true;
	if(regs.isNil, { regs = [ ] });
	if(regs.isArray.not, { regs = [regs] });
	if(clear, { regs = [0] ++ regs }); // clear all active registers
	// evt.regStore(chan, layer, regs);
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/S", *regs);
};
~bo.regAdd = {
	arg evt, chan, layer, regs;
	evt.reg(chan, layer, regs, false);
};

~bo.div = {
	// select Sauer division
	arg evt, chan, layer, divs, clear = true;
	if(divs.isArray.not, { divs = [divs] });
	if(clear, { divs = [0] ++ divs }); // clear all active registers
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/D", *divs);
};
~bo.divAdd = {
	arg evt, chan, layer, regs;
	evt.div(chan, layer, regs, false);
};

~bo.divReg = {
	// set register per division
	// set absolute registers, or relative if clear is false
	// regs: integer or integer[], a negative number meaning 'remove stop'
	arg evt, div, regs, clear = true;
	if(regs.isArray.not, { regs = [regs] });
	if(clear, { regs = [0] ++ regs }); // clear all active registers
	evt.addr.sendMsg("/D" ++ div ++ "/S", *regs);
};
~bo.divRegAdd = {
	arg evt, div, regs;
	evt.divReg(div, regs, false);
};

~bo.delay = {
	arg evt, chan, layer, msec;
	var onOff = if(msec > 0, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Delay", msec, onOff);
};

~bo.transpose = {
	arg evt, chan, layer, semitones;
	var onOff = if(semitones > 0, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Transpose", semitones, onOff);
};

~bo.staccato = {
	arg evt, chan, layer, msec;
	var onOff = if(msec > 0, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Staccato", msec, onOff);
};

~bo.prolong = {
	arg evt, chan, layer, msec;
	var onOff = if(msec > 0, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Prolong", msec, onOff);
};

~bo.pulsefreq = {
	// value 0.0 - 1.0 linear from 245ms to 5ms, -1.0 - 0.0 linear from 5bpm to 245bpm
	arg evt, chan, layer, value, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/PulseFreq", value, onOff);
};

~bo.pulsewidth = {
	// fraction 0.0 - 1.0
	arg evt, chan, layer, fraction, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/PulseWidth", fraction, onOff);
};

// schwell pedal 0 is Utopa air and schwell pedal 2 is the Sauer schwellchest
~bo.sp = {
	arg evt, pedal, value;
	evt.addr.sendMsg("/SP" ++ pedal.asString, value);
};

~bo.trem = {
	// werk = 'OW' or 'HW', pulsewidth = 0.0 - 1.0
	arg evt, werk = 'OW', msec, pulsewidth = 0.5, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg("/Trem" ++ werk, onOff, pulsewidth, '"' ++ msec.asString ++ 'ms"');
};

~bo.mute = {
	arg evt, chan, layer, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Mute", onOff);
};

~bo.sostenuto = {
	arg evt, chan, layer, boundary, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Sostenuto", boundary, onOff);
};

~bo.sustain = {
	arg evt, chan, layer, boundary, on = \on;
	var onOff = if(on == \on, { "on" }, { "off" });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/Sustain", boundary, onOff);
};

~bo.panic = {
	arg evt;
	evt.addr.sendMsg("/panic");
};

~bo.stopAllNotes = {
	arg evt, chans, layers;
	if(chans.isNil, { chans = [evt.ped, evt.man1, evt.man2, evt.man3] });
	if(chans.isArray.not, { chans = [chans] });
	if(layers.notNil and: { layers.isArray.not }, { layers = [layers] });
	chans.do { |chan|
		var layersTemp = if(layers.notNil, { layers }, { Array.series(evt.layersPerManual[chan], 1, 1) });
		if(layersTemp.size == 0, { layersTemp = (1..4) });
		("Stopping all notes on manual" + chan + ", layer(s)" + layersTemp.toString).warn;
		layersTemp.do { |layer|
			127.do { |note|
				evt.note(chan, layer, note, 0);
			};
		};
	};
};

~bo.clearAllRegs = {
	arg evt;
	var chans = [evt.ped, evt.man1, evt.man2, evt.man3];
	var layers;
	chans.do { |chan|
		layers = Array.series(evt.layersPerManual[chan], 1, 1);
		if(layers.size == 0, { layers = (1..4) });
		layers.do { |layer|
			evt.reg(chan, layer);
		};
	};
};

~bo.notify = {
	arg evt, msg;
	evt.notifyCount = evt.notifyCount + 1;
	if(evt.notifyCount > 700, {
		msg.warn;
		evt.notifyCount = 0;
	});
};

~bo.checkMultipleNotesPerRegister = {
	// check whether notes are played more than once simultaneously
	arg evt, chan, layer, notes, val;
	evt.notify("Multiple Notes Per Register Check is ON");
	if(notes.isArray.not, { notes = [notes] });
	evt.registrationsPerLayer[chan][layer].do { |reg|
		notes.do { |note|
			if(val > 0, {
				if(evt.notesPerRegister[reg][note] == 1, {
					format("Note % plays more than once on M %, L %, S %", note, chan, layer, reg).warn;
				});
				evt.notesPerRegister[reg][note] = 1;
				// format("Note % plays on M %, L %, S %", note, chan, layer, reg).postln;
			}, {
				evt.notesPerRegister[reg][note] = nil;
				// format("Note % stopped on M %, L %, S %", note, chan, layer, reg).postln;
			});
		};
	};
};

~bo.outOfRangeCheck = {
	// check if the notes are within range for each of the registers on this layer
	arg evt, chan, layer, notes, val;
	evt.notify("Out of Range Check is ON");
	if(val > 0, {
		~bo.registrationsPerLayer[chan][layer].do { |reg|
			var from = ~bo.regRanges[reg][0];
			var to = ~bo.regRanges[reg][1];
			var except = if(~bo.regRanges[reg].size > 2, { ~bo.regRanges[reg][2] }, { [ ] });
			var notesArray = if(notes.isArray, { notes }, { [notes] });
			notesArray.do { |note|
				if( (note < from) || (note > to), {
					format("/M%/L%/S% (%), note % out of range (% - %)", chan, layer, reg, ~bo.registersByNumber[reg], note, from, to).postln;
				});
				if( except.indexOf(note).notNil, {
					format("/M%/L%/S% (%), note % out of range exception (% - %)", chan, layer, reg, ~bo.registersByNumber[reg], note, from, to).postln;
				});
			};
		};
	});
};

~bo.regStore = {
	// store registers per layer to check for out of range or multiple notes on a register when triggering a note
	arg evt, chan, layer, regs;
	evt.notify("Store Registers is ON");
	regs.do { |reg|
		var index = ~bo.registrationsPerLayer[chan][layer].indexOf(reg.abs);
		if(reg == 0, {
			~bo.registrationsPerLayer[chan][layer] = [ ];
		});
		if(reg > 0, {
			if(index.isNil, { ~bo.registrationsPerLayer[chan][layer].add(reg) });
		});
		if(reg < 0, {
			if(index.notNil, { ~bo.registrationsPerLayer[chan][layer].removeAt(index) });
		});
	};
};

/*
Divisions and stops Sauer:

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
