(

// ------------ Setup environment ------------

~bo = EM(); // functions in an EM always have the environment as first argument

~bo.addr = NetAddr.new("192.168.0.1", 8000);
~bo.chanOffset = 0;
~bo.noteOffset = 2; // note 69 == A440

~bo.checkNotes = true;
~bo.postOSC = false;

~bo.numManuals = 4;
~bo.numLayers = 4;

~bo.regDict = { nil ! ~bo.numLayers } ! ~bo.numManuals;

~bo.noteDict = { nil ! ~bo.numLayers } ! ~bo.numManuals;

~bo.chanLayer = { // this returns the general OSC address
	arg evt, chan, layer;
	var layerPart = if (layer.notNil, { "/L" ++ layer }, { "" });
	if( chan.notNil ) {
		"/M" ++ (chan + evt.chanOffset) ++ layerPart
	} {
		layerPart
	}
};

~bo.note = {
	arg evt, chan, layer, notes, val, duration;
	var force = ((val ? 127) / 127).round(0.001);
	var msg, regs, range;
	if( notes.size == 0 ) { notes = [ notes ] };
	notes = notes.collect(_.asInt);
	msg = [ evt.chanLayer(chan, layer) ++ "/V", force ] ++ (notes + evt.noteOffset);
	if( evt.postOSC ) { msg.postln };
	if( evt.checkNotes ) {
		regs = evt.regDict[ chan ][ layer-1 ];
		if( regs.size > 0 ) {
			regs.asArray.do({ |reg|
				var item;
				item = evt.regRanges[ reg ];
				if( item.notNil ) {
					item = item - evt.noteOffset;
					notes.do({ |note|
						if( (note < item[0]) or: (note > item[1]) ) {
							"note M% L% %; out of range for register %\n".postf( chan, layer, note, reg )
						};
					});
				};
			});
		} {
			"note M% L% %; no registers on\n".postf( chan, layer, notes );
		};
	};
	evt.addr.sendMsg(*msg);
	if( duration.notNil ) {
		{
			duration.wait;
			evt.note( chan, layer, notes, 0 );
		}.fork;
	};
};

~bo.allNotesOff = {
	arg evt, chan, layer;
	if( chan.notNil ) {
		if( layer.notNil ) {
			evt.note( chan, layer, (..127), 0 );
		} {
			evt.numLayers.do({ |layer|
				evt.note( chan, layer+1, (..127), 0 );
			});
		};
	} {
		evt.numManuals.do({ |item|
			evt.numLayers.do({ |layer|
				evt.note( item, layer+1, (..127), 0 );
			});
		});
	};
};

~bo.midinote = { // send notes to all layers at once
	arg evt, chan, notes, val;
	evt.note(chan, nil, notes, val);
};

~bo.reg = { // set absolute registers, or relative if clear is false
	arg evt, chan, layer, regs, clear = true;
	var msg, current;
	if(regs.isArray.not, { regs = [regs] });
	//if (clear, { regs = [0] ++ regs });
	msg = [ evt.chanLayer(chan, layer) ++ "/S" ] ++ if( clear ) { [0] ++ regs } { regs };
	if( evt.postOSC ) { msg.postln };
	if( clear ) { 
		evt.regDict[ chan ][ layer-1 ] = regs !? _.sort; evt.changed( \regDict, chan, layer ) 
	} {
		current = evt.regDict[ chan ][ layer-1 ].as(Set);
		regs.asArray.do({ |item|
			if( item.isNegative ) {
				current.remove( item.abs )
			} {
				current.add( item );
			};
		});
		evt.regDict[ chan ][ layer-1 ] = current.asArray.sort;
		evt.changed( \regDict, chan, layer ) 
	};
	evt.addr.sendMsg(*msg);
};

~bo.regAdd = { // set relative registers (a negative number meaning remove register)
	arg evt, chan, layer, regs;
	evt.reg(chan, layer, regs, false);
};

~bo.regClear = { |evt, chan, layer|
	evt.reg( chan, layer );
};

~bo.delay = { // switching delay on or off (when on is false)
	arg evt, chan, layer, amount, on = true;
	var onOff = if(on, { '"on"' }, { '"off"' });
	evt.addr.sendMsg(
		evt.chanLayer(chan, layer) ++
		"/delay",
		amount.asString +
		onOff
	);
};

~bo.delayOff = {
	arg evt, chan, layer;
	evt.delay(chan, layer, 0, false);
};

~bo.transpose = {
	arg evt, chan, layer, semitones;
	evt.addr.sendMsg(
		evt.chanLayer(chan, layer) ++
		"/transpose",
		semitones
	);
};

(
~bo.regTransps = (
);

[   16, 8, 8, 8, 4, 4, 2, \f2, \f5, \f3, \f4, 16, 8, 
	8, 8, 8, 4, 4, 3, 2, 2, '8/5', '3/2', 1, 'f4', 8, 
	16, 16, 12, 8, 16, 8, 4
].do({ |item, i|
	~bo.regTransps[ item ] = (~bo.regTransps[ item ] ? [])  ++ (i+36);
});

~bo.getTransposition = { |evt, reg = 36|
	var key, factors;
	evt.regTransps.keysValuesDo({ |k, value|
		if( value.includes( reg ) ) { key = k };
	});
	if( key.notNil ) {
		if( key.isKindOf( Symbol ) ) {
			factors = key.asString.split( $/ );
			if( factors.size == 2 ) {
				(8 / (factors[0].interpret / factors[1].interpret)).ratiomidi.round(1);
			} {
				// "%: multi-fach (%); transposition not found".format( reg, key ).postln;
				nil;
			};
		} {
			(8 / key).ratiomidi.round(1);
		};
	} {
		"%: unknown; transposition not found".format( reg ).postln;
		nil;
	};
};
);

(
~bo.regRanges = (	
	36: [ 36, 92 ],
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
	
	// problem with black notes if motor fails:
	49: [ 36, 92 ], 
	50: [ 36, 92 ], 
	51: [ 56, 92 ], 
	52: [ 36, 92 ], 
	53: [ 36, 92 ], 
	54: [ 36, 92 ], 
	55: [ 36, 92 ], 
	56: [ 36, 92 ], 
	57: [ 36, 90 ], // really to 90?
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
	67: [ 36, 66 ],
	68: [ 36, 66 ],
).collect(_+2);
);

(
~bo.regNames = [ 
"Burdun", "Principal", "Rohrflott", "Quintathen", "Octav", "Gemshorn", "Weit Pfeiffe", "Sexquint altra", "Mixtur", "Cymbel", "Cornett", "Fagott", "Trumpet",

"Gedackt", "Violdi-gamba", "Unda maris", "Principal", "Rohrflott", "Octav", "Waldflott", "Tertia", "Quinta", "Sufflott", "Sharf", "Vox humana", 

"Principal", "Subbass", "Quint Bass", "Octav", "Posaune", "Posaune", "Clarin"
];
);

)

/*
// manual 3, layer 1, note 69 (A440)
~bo.note( 3, 1, 69, 127, 0.1 ); // 0.1s

~bo.note( 3, 1,  69, 127 ); // infinite duration

~bo.note( 3, 1,  69, 0 ); // end

// all notes off manual 3, layer 1
~bo.note( 3, 1, (..127), 0 );

// registers
~bo.reg(3, 1, (36..68).scramble[..5] );


// all notes off manual 3, layer 1
~bo.note( 3, 1, (..127), 0 );

// registers
~bo.reg(3, 1, (36..68).scramble[..5] );

{ SinOsc.ar( 2200 ) }.play;

~bo.getTransposition( 58 );

*/