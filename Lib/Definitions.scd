
// data containers ------------------------------------

~bo.ped = 0;
~bo.man1 = 1;
~bo.man2 = 2;
~bo.man3 = 3;

~bo.registers = OEM(
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

	\principal_16, 62,
	\subbass_16, 63,
	\quint_bass_12, 64,
	\octav_8, 65,
	\posaune_16, 66,
	\posaune_8, 67,
	\clarin_4, 68
);

~bo.registersByNumber = ();
~bo.registers.keysValuesDo { |key, value|
	~bo.registersByNumber[value] = key;
};

~bo.regRanges = ( // min, max, exceptions[]
	// not sounding from 86 - 92
	36: [ 36, 92, [ ] ],
	37: [ 36, 92 ],
	38: [ 36, 92 ],
	39: [ 36, 92 ], // 92 one note too high!
	40: [ 36, 92 ],
	41: [ 36, 92 ],
	42: [ 36, 92 ],
	43: [ 36, 92 ],
	44: [ 36, 92 ],
	45: [ 36, 92 ], // 88-92 not sounding
	46: [ 59, 92 ],
	47: [ 36, 92 ],
	48: [ 36, 92 ], // 92 not sounding

	49: [ 36, 92 ],
	50: [ 36, 92 ],
	51: [ 56, 92 ],
	52: [ 36, 92 ],
	53: [ 36, 92 ],
	54: [ 36, 92 ],
	55: [ 36, 92 ],
	56: [ 36, 92 ],
	57: [ 36, 92 ], // really to 90?
	58: [ 36, 92 ],
	59: [ 36, 92 ],
	60: [ 36, 92 ],
	61: [ 36, 92 ],

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
	HID.closeAll;
	~bo = EM();
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
	evt.outOfRangeCheck(chan, layer, notes, val);
	notes = notes + ~bo.noteOffset;
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/V", force, *notes);
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

~bo.midinote = {
	// send note to all layers
	arg evt, chan, notes, val;
	evt.note(chan, nil, notes, val);
};

~bo.reg = {
	// set absolute registers, or relative if clear is false
	// regs: integer or integer[], a negative number meaning 'remove stop'
	arg evt, chan, layer, regs, clear = true;
	if(regs.isArray.not, { regs = [regs] });
	if(clear, { regs = [0] ++ regs }); // clear all active registers
	evt.regStore(chan, layer, regs);
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/S", *regs);
};

~bo.regStore = {
	// store registers per layer to check for out of range when triggering a note
	arg evt, chan, layer, regs;
	evt.notify("Store Registers is ON");
	regs.do { |reg|
		if(reg == 0, {
			~bo.registrationsPerLayer[chan][layer] = [ ];
		});
		if(reg > 0, {
			~bo.registrationsPerLayer[chan][layer].add(reg);
		});
		if(reg < 0, {
			var index = ~bo.registrationsPerLayer[chan][layer].indexOf(reg.abs);
			if(index.notNil, { ~bo.registrationsPerLayer[chan][layer].removeAt(index) });
		});
	};
};

~bo.regAdd = {
	// set relative register
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

~bo.divReg = {
	// set register per division
	// set absolute registers, or relative if clear is false
	// regs: integer or integer[], a negative number meaning 'remove stop'
	arg evt, chan, layer, div, regs, clear = true;
	if(regs.isArray.not, { regs = [regs] });
	if(clear, { regs = [0] ++ regs }); // clear all active registers
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/D" ++ div ++ "/S", *regs);
};

~bo.delay = {
	// switching delay on or off
	arg evt, chan, layer, amount;
	var onOff = if(amount > 0, { '"on"' }, { '"off"' });
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/delay", amount.asString, onOff);
};

~bo.transpose = {
	arg evt, chan, layer, semitones;
	evt.addr.sendMsg(evt.chanLayer(chan, layer) ++ "/transpose", semitones);
};

~bo.panic = {
	arg evt, chans, layers;
	if(chans.isNil, { chans = [~bo.ped, ~bo.man1, ~bo.man2, ~bo.man3] });
	if(chans.isArray.not, { chans = [chans] });
	if(layers.isNil, {
		chans.do { |chan|
			127.do { |note|
				~bo.note(chan, nil, note, 0);
			};
		};
	}, {
		if(layers.isArray.not, { layers = [layers] });
		chans.do { |chan|
			layers.do { |layer|
				127.do { |note|
					~bo.note(chan, layer, note, 0);
				};
			}
		};
	});
};

~bo.notify = {
	arg evt, msg;
	evt.notifyCount = evt.notifyCount + 1;
	if(evt.notifyCount > 40, {
		msg.warn;
		evt.notifyCount = 0;
	});
};