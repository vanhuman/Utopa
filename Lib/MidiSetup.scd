// ------------ Send incoming MIDI from Nuendo out as OSC, sometimes processed ------------

"### Initializing MIDI".postln;
MIDIIn.connectAll;

~midiOutDevice = \MUL;
~bo.midiOut = MIDIout.new().getIDs;
~bo.iac1ID = ~bo.midiOut[0];
~bo.extID = ~bo.midiOut[4];

// ------------ incoming channels 1, 2, 3 to channels 1, 2, 3 layer 1 ------------

MIDIdef.noteOn(\secondLawNON123, {
	arg val, num, chan, src;
	// ["NON123", chan, num, val].postln;
	~bo.note(chan, 1, num, val);
	if(chan == 0, { // remember pedal note so we can retrigger it with lower velocities
		~bo.pedalNote = num;
	});
}, chan: [0, 1, 2], srcID: ~bo.iac1ID
).fix;
MIDIdef.noteOff(\secondLawNOF123, {
	arg val, num, chan, src;
	// ["NOF123", chan, num, val].postln;
	~bo.note(chan, 1, num, 0);
	if(chan == 0 and: { ~bo.pedalNote == num }, { // forget pedal note
		~bo.pedalNote = nil;
	});
}, chan: [0, 1, 2], srcID: ~bo.iac1ID
).fix;
// MIDI from iCon: retrigger pedal notes
MIDIdef.cc(\secondLawCC1icon, { // fader to retrigger one specific note with different velocities on the pedals
	arg val, num, chan, src;
	// ["CC1 icon", chan, num, val].postln;
	// retrigger pedal note with lower velocities
	if(~bo.pedalNote.notNil, {
		~bo.note(~bo.ped, 1, ~bo.pedalNote, val.linlin(0, 127, 1, 64));
	});
}, ccNum: 1, chan: 0, srcID: ~bo.extID
).fix;

// ------------ incoming channel 4 to Manual III all layers for delay ------------

~bo.delayOnTimes = [0.1, 0.1, 0.1];
~bo.delayOffTimes = [0.1, 0.1, 0.1];
~bo.delayMan = ~bo.man3;
MIDIdef.noteOn(\secondLawNON4, {
	arg val, num, chan, src;
	var task;
	// ["NON4", chan, num, val].postln;
	task = Task({
		~bo.note(~bo.delayMan, 1, num, val);
		~bo.delayOnTimes[0].wait;
		~bo.note(~bo.delayMan, 2, num, val);
		~bo.delayOnTimes[1].wait;
		~bo.note(~bo.delayMan, 3, num, val);
		~bo.delayOnTimes[2].wait;
		~bo.note(~bo.delayMan, 4, num, val);
	});
	task.start;
}, chan: [3], srcID: ~bo.iac1ID
).fix;
MIDIdef.noteOff(\secondLawNOF4, {
	arg val, num, chan, src;
	var task;
	// ["NOF4", chan, num, val].postln;
	task = Task({
		~bo.note(~bo.delayMan, 1, num, 0);
		~bo.delayOffTimes[0].wait;
		~bo.note(~bo.delayMan, 2, num, 0);
		~bo.delayOffTimes[1].wait;
		~bo.note(~bo.delayMan, 3, num, 0);
		~bo.delayOffTimes[2].wait;
		~bo.note(~bo.delayMan, 4, num, 0);
	});
	task.start;
}, chan: [3], srcID: ~bo.iac1ID
).fix;

// ------------ incoming channel 5 to Manual II layer 2 for other registers ------------

MIDIdef.noteOn(\secondLawNON5, {
	arg val, num, chan, src;
	// ["NON5", chan, num, val].postln;
	~bo.note(~bo.man2, 2, num, val);
}, chan: [4], srcID: ~bo.iac1ID
).fix;
MIDIdef.noteOff(\secondLawNOF5, {
	arg val, num, chan, src;
	// ["NOF5", chan, num, val].postln;
	~bo.note(~bo.man2, 2, num, 0);
}, chan: [4], srcID: ~bo.iac1ID
).fix;

// ------------ incoming channel 6 to Manual II layer 3 for other registers ------------

MIDIdef.noteOn(\secondLawNON6, {
	arg val, num, chan, src;
	// ["NON6", chan, num, val].postln;
	~bo.note(~bo.man2, 3, num, val);
}, chan: [5], srcID: ~bo.iac1ID
).fix;

MIDIdef.noteOff(\secondLawNOF6, {
	arg val, num, chan, src;
	// ["NOF6", chan, num, val].postln;
	~bo.note(~bo.man2, 3, num, 0);
}, chan: [5], srcID: ~bo.iac1ID
).fix;

// ------------ incoming channel 7 to Manual II layer 4 for other registers ------------

MIDIdef.noteOn(\secondLawNON7, {
	arg val, num, chan, src;
	// ["NON7", chan, num, val].postln;
	~bo.note(~bo.man2, 4, num, val);
}, chan: [6], srcID: ~bo.iac1ID
).fix;
MIDIdef.noteOff(\secondLawNOF7, {
	arg val, num, chan, src;
	// ["NOF7", chan, num, val].postln;
	~bo.note(~bo.man2, 4, num, 0);
}, chan: [6], srcID: ~bo.iac1ID
).fix;

// ------------ MIDI from iCon: repeating notes Manual II layer 2 ------------

~bo.repNotes = [69, 81, 67, 79];
~bo.repTaskOn = [false, false, false, false];
~bo.repVel = [127, 127, 127, 127];
~bo.repTask = [nil, nil, nil, nil];
~bo.repNote = {
	arg evt, chan, layer, note, index;
	var task = Task {
		inf.do {
			evt.note(chan, layer, note, evt.repVel[index] + rrand(0, min(20, 127 - evt.repVel[index])));
			0.01.wait;
			evt.note(chan, layer, note, 0);
			0.04.wait;
		};
	};
	task.start;
	task
};
MIDIdef.noteOn(\secondLawNON4952icon, { // start repeating notes
	arg val, num, chan, src;
	var index = num - 49;
	// ["NON49-52 icon", chan, num, val].postln;
	if(~bo.repTaskOn[index], {
		~bo.repTask[index].stop;
		~bo.regAdd(~bo.man2, 2, -61);
		{ ~bo.note(~bo.man2, 2, ~bo.repNotes[index], 0) }.defer(0.05);
	}, {
		~bo.regAdd(~bo.man2, 2, 61);
		~bo.repTask[index] = ~bo.repNote(~bo.man2, 2, ~bo.repNotes[index], index);
	});
	~bo.repTaskOn[index] = ~bo.repTaskOn[index].not;
}, srcID: ~bo.extID, noteNum: [49, 50, 51, 52]
).fix;

MIDIdef.cc(\secondLawCC25icon, { // fader to set velocity of repeating notes
	arg val, num, chan, src;
	var index = num - 2;
	// ["CC2-5 icon", chan, num, val].postln;
	~bo.repVel[index] = val;
}, ccNum: [2, 3, 4, 5], chan: 0, srcID: ~bo.extID
).fix;

// ------------ incoming channel 16 for control messages ------------
MIDIdef.noteOn(\secondLawNON16, {
	// midi notes 0 - 9 for preset selection
	arg val, num, chan, src;
	// ["NON16", chan, num, val].postln;
	if(num < 10, {
		~bo.presetButton[num].valueAction_(1);
	});
	if( [0, 1].indexOf(num).notNil, {
		"Delay switched ON".warn;
		~bo.delayOnTimes = [0.1, 0.1, 0.1];
		~bo.delayOffTimes = [0.1, 0.1, 0.1];
	});
	if( (2..9).indexOf(num).notNil, {
		"Delay switched OFF".warn;
		~bo.delayOnTimes = [0, 0, 0];
		~bo.delayOffTimes = [0, 0, 0];
	});
	if(num == 12, {
		~bo.panic();
	});
}, chan: [15], srcID: ~bo.iac1ID
).fix;

"### Done initializing MIDI".postln;