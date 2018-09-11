// ------------ GUI ------------
(
~bo.presetButton = Array.newClear(10);

~bo.makeWindow = { |evt|
	var win, fView, cView, buttonStop, buttonOSC, fSaveRegistration, fLoadRegistration, selectedPreset = 0;
	var buttonClearRegs, buttonClearRegsClock, buttonStopClock, buttonSaveRegs;
	var numberOfLayers = 8;
	var cellWidth = 135, cellHeight = 14, winHeight = 755, winWidth = (cellWidth + 13) * numberOfLayers, buttonWidth = cellWidth* 1.05;
	var font = Font("Courier", 11), bigFont = Font("Courier", 13);
	var titleColor = Color.blue(1, 0.1), buttonColor = Color.blue, manualColor = Color.blue(1,0.3);

	evt.w = win = Window( "Utopa Register Board", Rect(0, 1000, winWidth, winHeight), scroll: true).background_(Color.grey).front;
	win.addFlowLayout;
	cView = CompositeView(evt.w, (winWidth - 10) @ 50).background_(Color.white);
	cView.addFlowLayout;

	// Panic: stop all notes and close all registers
	buttonStop = SmoothButton(cView, buttonWidth @ (cellHeight*2))
	.radius_(2).border_(1).canFocus_(false).font_(font)
	.states_( [ ["PANIC (notes&stops)", Color.red, Color.white], ["PANIC (notes&stops)", Color.white, Color.red] ] )
	.action_({ |bt|
		if(bt.value == 1, {
			"PANIC".warn;
			evt.panic();
			buttonStopClock = AppClock.sched(1, {
				bt.value = 0;
				// "Create extra layers".postln;
				// Task.new({
				// 	evt.addLayer(0);
				// 	0.01.wait;
				// 	evt.addLayer(1);
				// 	0.01.wait;
				// 	evt.addLayer(2);
				// 	0.01.wait;
				// 	evt.addLayer(3);
				// }).start;
				nil
			});
		});
	});

	// Clear all registers
	buttonClearRegs = SmoothButton(cView, buttonWidth @ (cellHeight*2))
	.radius_(2).border_(1).canFocus_(false).font_(font)
	.states_( [ ["Clear all registers", Color.black, Color.white], ["Clear all registers", Color.white, buttonColor] ] )
	.action_({ |bt|
		if(bt.value == 1, {
			evt.buttons.keysValuesDo({
				arg man, buttons;
				evt.buttons[man].keysValuesDo({
					arg index, button;
					button.valueAction_(0);
				});
			});
			buttonClearRegsClock = AppClock.sched(0.1, { bt.value = 0; nil });
		});
	});

	// Save registration
	buttonSaveRegs = SmoothButton(cView, buttonWidth @ (cellHeight*2))
	.radius_(2).border_(1).canFocus_(false).font_(font)
	.states_( [ ["Save registration", Color.black, Color.white], ["Save registration", Color.white, buttonColor] ] )
	.action_({ |bt|
		if(bt.value == 1, {
			fSaveRegistration.value(selectedPreset);
			fLoadRegistration.value(selectedPreset, true);
			{ bt.value = 0 }.defer(0.1);
		});
	});

	// OSC monitor
	buttonOSC = SmoothButton(cView, buttonWidth @ (cellHeight*2))
	.radius_(2).border_(1).canFocus_(false).font_(font)
	.states_( [ ["OSC Monitor OFF", Color.black, Color.white], ["OSC monitor ON", Color.white, buttonColor] ] )
	.action_({ |bt|
		~oscOutMonitor = bt.value;
		("OSC Out Monitor is" + if(~oscOutMonitor == 1, { "ON" }, { "OFF" })).postln;
	});
	buttonOSC.value = ~oscOutMonitor ? 0;

	// SCdelay
	if (~bo.showSCdelayButton.notNil) {
		evt.buttonScDelay = SmoothButton(cView, buttonWidth @ (cellHeight*2))
		.radius_(2).border_(1).canFocus_(false).font_(font)
		.states_( [ ["SC delay OFF", Color.black, Color.white], ["SC delay ON", Color.white, buttonColor] ] )
		.action_({ |bt|
			if(bt.value == 1, {
				evt.scDelay(true);
				"Delay switched ON".warn;
			}, {
				evt.scDelay(false);
				"Delay switched OFF".warn;
			});
			evt.delayOnTimes.postln;
		});
		evt.buttonScDelay.value = if(evt.scDelayOn, { 1 }, { 0 });
	};

	// Empty row
	StaticText(cView, (buttonWidth*0.2) @ (cellHeight*2)).string_("").font_(bigFont).align_(\center);

	// registration preset buttons
	10.do { |index|
		evt.presetButton[index] = SmoothButton(cView, (cellHeight*2) @ (cellHeight*2))
		.radius_(2).border_(1).canFocus_(false).font_(font)
		.states_( [ [(index+1).asString, Color.black, Color.white], [(index+1).asString, Color.white, buttonColor] ] )
		.action_({ |button|
			button.value = 1;
			selectedPreset = index;
			// switch off all other buttons
			evt.presetButton.do { |b, i|
				if(i !== index, { b.value = 0 });
			};
			fLoadRegistration.value(index);
		});
	};

	// function to generate layere lanes
	fView = {
		arg title, chan, layer, color = titleColor, delay = false, notesButtons = Array.newClear(7);
		var cView, buttons = OEM(), halfWidth = cellWidth;
		evt.layersPerManual[chan] = evt.layersPerManual[chan] + 1;
		cView = CompositeView(evt.w, (cellWidth + 8) @ (winHeight - 62)).background_(Color.white);
		cView.addFlowLayout;
		// Title
		if(delay, { halfWidth = cellWidth * 0.45 });
		StaticText(cView, halfWidth @ cellHeight).string_(title).align_(\center).font_(font).background_(color);
		if(delay, {
			StaticText(cView, (halfWidth * 0.6) @ cellHeight).string_("delay").align_(\center).font_(font);
			NumberBox(cView, (halfWidth * 0.5) @ cellHeight).align_(\center).value_(0).font_(font)
			.action_({ |nb|
				evt.delay(chan, layer, nb.value);
			});
		});
		// Empty row
		StaticText(cView, cellWidth @ (cellHeight * 0.3)).string_("").align_(\center).font_(font).background_(Color.white);
		// trigger notes
		[37, 45, 60, 67, 75, 84, 89].do { |note, i|
			notesButtons[i] = SmoothButton(cView, (cellHeight+1) @ cellHeight)
			.radius_(2).border_(1).canFocus_(false).font_(font)
			.states_( [ [note.asString, buttonColor, Color.white], [note.asString, Color.white, buttonColor] ] )
			.action_({ |bt|
				evt.note(chan, layer, note, 127 * bt.value);
			});
		};
		// Stop all notes
		SmoothButton(cView, cellWidth @ cellHeight)
		.radius_(2).border_(1).canFocus_(false).font_(font)
		.states_( [ ["Stop all notes", buttonColor, Color.white], ["Stop all notes", Color.white, buttonColor] ] )
		.action_({ |bt|
			if(bt.value == 1, {
				evt.stopAllNotes(chan, layer);
				7.do { |i|
					notesButtons[i].value = 0;
				};
				{ bt.value = 0 }.defer(0.1);
			});
		});
		// Clear all registers
		SmoothButton(cView, cellWidth @ cellHeight)
		.radius_(2).border_(1).canFocus_(false).font_(font)
		.states_( [ ["Clear registers", buttonColor, Color.white], ["Clear registers", Color.white, buttonColor] ] )
		.action_({ |bt|
			if(bt.value == 1, {
				buttons.keysValuesDo {
					arg index, button;
					button.valueAction_(0);
				};
				{ bt.value = 0 }.defer(0.1);
			});
		});
		// Empty row
		StaticText(cView, cellWidth @ (cellHeight * 0.3)).string_("").align_(\center).font_(font).background_(Color.white);
		// Register buttons
		evt.registers.keysValuesDo({ |key, value|
			buttons[value] = (SmoothButton(cView, cellWidth @ cellHeight)
				.radius_(2).border_(1).canFocus_(false).font_(font)
				.states_( [ [key.asString, Color.black, Color.white], [key.asString, Color.white, buttonColor] ] )
				.action_({ |bt|
					switch( bt.value,
						1, { evt.regAdd(chan, layer, value) },
						0, { evt.regAdd(chan, layer, value.neg ) }
					);
				});
			);
		});
		buttons
	};

	// layer lanes
	evt.buttons = OEM();
	evt.buttons.p1 = fView.value("Pedals - Layer 1", evt.ped, 1, manualColor);
	evt.buttons.p2 = fView.value("Layer 2", evt.ped, 2, delay: true);
	evt.buttons.m11 = fView.value("Manual I - Layer 1", evt.man1, 1, manualColor);
	evt.buttons.m12 = fView.value("Layer 2", evt.man1, 2, delay: true);
	evt.buttons.m21 = fView.value("Manual II - Layer 1", evt.man2, 1, manualColor);
	evt.buttons.m22 = fView.value("Layer 2", evt.man2, 2, delay: true);
	evt.buttons.m31 = fView.value("Manual III - Layer 1", evt.man3, 1, manualColor);
	evt.buttons.m32 = fView.value("Layer 2", evt.man3, 2, delay: true);

	// Function to save the registration into a preset
	fSaveRegistration = {
		arg preset;
		var registrationsFile, registrationPresets, path, manualCounter = 0, newRegistration;
		path = ~bo.currentDir ++ "/Registrations.scd";
		registrationPresets = path.load;
		newRegistration = []!evt.buttons.size;
		registrationPresets[preset].size.do { |index|
			if(index < newRegistration.size) {
				newRegistration[index] = registrationPresets[preset][index];
			}
		};
		evt.buttons.keysValuesDo({
			arg manual, buttons;
			newRegistration[manualCounter] = Array.new(evt.registers.size);
			evt.buttons[manual].keysValuesDo({
				arg index, button;
				newRegistration[manualCounter].add(button.value);
			});
			manualCounter = manualCounter + 1;
		});
		registrationPresets[preset] = newRegistration;
		registrationsFile = File(path,"w");
		registrationsFile.write(registrationPresets.asCompileString);
		registrationsFile.close;
	};

	// function to load the registration
	fLoadRegistration = {
		arg preset, emptyCheckOnly = false;
		var registrationPresets, registrationsFile, path, manualCounter = 0, registrationEmpty = true;
		path = ~bo.currentDir ++ "/Registrations.scd";
		if(File.exists(path).not, {
			registrationsFile = File(path,"w");
			registrationsFile.write("[ [], [], [], [], [], [], [], [], [], [] ]");
			registrationsFile.close;
		});
		registrationPresets = path.load;
		registrationPresets[preset].do { |manual|
			manual.do { |registration|
				if(registration !== 0, { registrationEmpty = false });
			};
		};
		if(registrationEmpty, { evt.presetButton[preset].border_(1) }, { evt.presetButton[preset].border_(2) });
		if(registrationEmpty.not && emptyCheckOnly.not, {
			evt.buttons.keysValuesDo({
				arg manual, buttons;
				var buttonCounter = 0;
				if(registrationPresets[preset].size > manualCounter, {
					evt.buttons[manual].keysValuesDo({
						arg index, button;
						button.valueAction = registrationPresets[preset][manualCounter][buttonCounter];
						buttonCounter = buttonCounter + 1;
					});
				});
				manualCounter = manualCounter + 1;
			});
		});
	};

	win.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode;
		var numberKeys = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29], numberPressed;
		// keycode.postln;
		// Esc stops all notes
		if(keycode == 53, {
			buttonStop.valueAction_(1);
			buttonClearRegs.valueAction_(1);
		});
		// Alt-O toggles OSC out monitor
		if(keycode == 31 && modifiers.isAlt, {
			buttonOSC.valueAction_((buttonOSC.value + 1)%2);
		});
		// Alt-S saves preset
		if(keycode == 1 && modifiers.isAlt, {
			buttonSaveRegs.valueAction_(1);
		});
		// Alt-C clears preset
		if(keycode == 8 && modifiers.isAlt, {
			buttonClearRegs.valueAction_(1);
		});
		// Alt-D switched SuperCollider delay on/off
		if(keycode == 2 && modifiers.isAlt, {
			evt.buttonScDelay.valueAction_((evt.buttonScDelay.value + 1)%2);
		});
		// Number keys select presets
		numberPressed = numberKeys.indexOf(keycode);
		if(numberPressed.notNil, {
			evt.presetButton[numberPressed].value_(0);
			evt.presetButton[numberPressed].valueAction_(1);
		})
	});

	win.onClose = {
		// buttonStop.valueAction_(1);
		// buttonStopClock.clear;
	};
	// win.alwaysOnTop = true;

	// initialize
	10.do { |i|
		fLoadRegistration.value(i, true); // just set the state of the preset buttons
	};
	// evt.presetButton[0].valueAction_(1); // select the first preset
	// buttonStop.valueAction_(1);
	cView.focus(true);
	win;
};
~bo.makeWindow;
)