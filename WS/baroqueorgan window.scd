~bo = ~bo ? EM();

(

~bo.makeWin = { |evt|
	var width = 16, csize, ctrl;
	if( evt.win.notNil && { evt.win.isClosed.not } ) { evt.win.close; };
	
	width = 16;
	csize = ((width * 13) + 4) @ ((width * 3) + 4);
	
	evt.win = Window( "BO", Rect( 128, 128, ((csize.x + 4) * (evt.numLayers ? 4)) + 30,  ((csize.y + 4) * (evt.numManuals ? 4)) + 20 ) ).front;
	evt.win.addFlowLayout( 2@2, 2@2 );
	StaticText( evt.win, 28 @ 18 );
	evt.numLayers.do({ |layer|
		StaticText( evt.win, ((width * 13) +  4) @ 18  )
			.string_( " L%".format( layer + 1 ) );
	});
	evt.views = evt.numManuals.collect({ |manual|
		StaticText( evt.win, 28 @ 28 )
			.string_( "  M%".format( (evt.numManuals - 1) - manual ) );
		evt.numLayers.collect({ |layer|
			var vws = ();
			vws[ \composite ] = CompositeView( evt.win, ((width * 13) +  4) @ ((width * 3) +  4) )
				.background_( Color.white );
			vws[ \composite ].addFlowLayout( 2@2, 2@2 );
			vws[ \buttons ] = 33.collect({ |i|
				SmoothButton( vws[ \composite ], (width - 2) @ (width - 2) )
					.border_( 1 )
					.radius_( 2 )
					.label_( (i+36).asString.dup )
					.font_( Font( Font.defaultSansFace, 9 ) )
					.hiliteColor_( Color.green )
					.action_({ |vw|
						evt.regAdd( (evt.numManuals - 1) - manual, layer+1, (i+36) * [-1,1][ vw.value.asInt ] );
					});
			});
			vws[ \closeButton ] = SmoothButton( vws[ \composite ],  (width - 2) @ (width - 2) )
				.label_( 'x' )
				.action_({ evt.reg( (evt.numManuals - 1) - manual, layer+1, [] ) });
			vws;
		});
	});
	ctrl = SimpleController( evt ).put( \regDict, { |obj, chan, layer| evt.updateWin( chan, layer ); });
	evt.win.onClose_( { ctrl.remove } );
	evt.updateWin;
};

~bo.updateWin = { |evt, chan, layer|
	if( evt.win.notNil && { evt.win.isClosed.not }) {
		evt.regDict.do({ |layers, manual|
				layers.do({ |regs, i|
					var views;
					regs = regs ? [];
					evt.views[ (evt.numManuals - 1) - manual ][ i ].buttons.do({ |vw, i|
						var value;
						value = regs.includes( (i+36).asInt ).binaryValue;
						if( vw.value != value ) { vw.value = value };
					});
				});
		});
	};
};

~bo.makeWin;

)