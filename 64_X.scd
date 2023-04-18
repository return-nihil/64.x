//64.X v.4.2

//INIZIALIZZAZIONE SERVER:
(
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2; //quad
s.reboot;
s.meter;
)

Server.default.options.outDevice_("Soundflower (2ch)"); //Soundflower (2ch) //Built-in Output

//UTILITIES:

NetAddr.localAddr
FreqScope.new;

{SinOsc.ar(440)}.play


(

MIDIClient.init;
MIDIIn.connectAll;

Server.default.options.outDevice_("Built-in Output"); //Soundflower (2ch)


////////////////////////////////////////////////////////////////////////////////////////////////////
//MOTORE DI SINTESI


//VARIABILI GLOBALI:

~piecesleft = 32;
~pieceamp = 0.35;

~root = 36;
~rootz = ~root.midicps;

// ~scale = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24, 26]; //major
~scale = [0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24, 26]; //minor
//~scale = [0, 2, 3, 5, 7, 8, 11, 12, 14, 15, 17, 19, 20, 23, 24, 26]; //harm minor
//~scale = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]; //chromatic

~notes = Array2D.fromArray(8, 8, [~scale[0], ~scale[1], ~scale[2], ~scale[3], ~scale[3], ~scale[2], ~scale[1], ~scale[0], ~scale[4], ~scale[5], ~scale[6], ~scale[7], ~scale[7], ~scale[6], ~scale[5],~scale[4], ~scale[8], ~scale[9], ~scale[10], ~scale[11], ~scale[11], ~scale[10], ~scale[9], ~scale[8], ~scale[12], ~scale[13], ~scale[14], ~scale[15], ~scale[15], ~scale[14], ~scale[13], ~scale[12], ~scale[12], ~scale[13], ~scale[14], ~scale[15], ~scale[15], ~scale[14], ~scale[13], ~scale[12], ~scale[8],~scale[9],~scale[10], ~scale[11], ~scale[11], ~scale[10], ~scale[9], ~scale[8], ~scale[4], ~scale[5], ~scale[6], ~scale[7],~scale[7], ~scale[6], ~scale[5], ~scale[4], ~scale[0], ~scale[1], ~scale[2], ~scale[3], ~scale[3], ~scale[2], ~scale[1], ~scale[0]]);

/* disposizione case:
0, 1, 2, 3, 3, 2, 1, 0,
4, 5, 6, 7, 7, 6, 5, 4,
8, 9, 10, 11, 11, 10, 9, 8,
12, 13, 14, 15, 15, 14, 13, 12,
12, 13, 14, 15, 15, 14, 13, 12,
8, 9, 10, 11, 11, 10, 9, 8,
4, 5, 6, 7, 7, 6, 5, 4,
0, 1, 2, 3, 3, 2, 1, 0,
*/


//MASTER

//Globale:
s.volume = 0;    // db


///////////////////////////////////////////////////////////////////////////////////////////////////////
//SYNTH PEZZI:

~br1 = Buffer.alloc(s, 2048, bufnum: 0);   //doppio buffer
~br2 = Buffer.alloc(s, 2048, bufnum: 1);
~bb1 = Buffer.alloc(s, 2048, bufnum: 2);
~bb2 = Buffer.alloc(s, 2048, bufnum: 3);
~bn1 = Buffer.alloc(s, 2048, bufnum: 4);
~bn2 = Buffer.alloc(s, 2048, bufnum: 5);
~bq1 = Buffer.alloc(s, 2048, bufnum: 6);
~bq2 = Buffer.alloc(s, 2048, bufnum: 7);

~p2 = rrand(0.01, 0.89);   //ampiezza parziali
~p3 = rrand(0.01, 0.79);
~p4 = rrand(0.01, 0.69);
~p5 = rrand(0.01, 0.69);
~p6 = rrand(0.01, 0.59);
~p7 = rrand(0.01, 0.59);
~p8 = rrand(0.01, 0.49);
~p9 = rrand(0.01, 0.49);
~pi2 = rrand(0.01, 0.89);
~pi3 = rrand(0.01, 0.79);
~pi4 = rrand(0.01, 0.69);
~pi5 = rrand(0.01, 0.69);
~pi6 = rrand(0.01, 0.59);
~pi7 = rrand(0.01, 0.59);
~pi8 = rrand(0.01, 0.49);
~pi9 = rrand(0.01, 0.49);


~bb1.sine3([1, 2, 4], [1, ~p2, ~p3], 0!3, asWavetable:true);   //wavetable
~bn1.sine3([1, 3, 5], [1, ~p2, ~p3], 0!3, asWavetable:true);
~br1.sine3((1..5), [1, ~p2, ~p3, ~p4, ~p5], 0!5, asWavetable: true);
~bq1.sine3((1..9), [1, ~p2, ~p3, ~p4, ~p5, ~p6, ~p7, ~p8, ~p9], 0!9, asWavetable:true);
~bb2.sine3([1, 2, 4], [1, ~pi2, ~pi3], 0!3, asWavetable:true);
~bn2.sine3([1, 3, 5], [1, ~pi2, ~pi3], 0!3, asWavetable:true);
~br2.sine3((1..5), [1, ~pi2, ~pi3, ~pi4, ~pi5], 0!5, asWavetable: true);
~bq2.sine3((1..9), [1, ~pi2, ~pi3, ~pi4, ~pi5, ~pi6, ~pi7, ~pi8, ~pi9], 0!9, asWavetable:true);


//GRUPPO SINTETIZZATORI PEZZI:

( //PEDONI
SynthDef.new(\pawn, {
	arg wpan = 0,
	     master_vol = 0,
	     global_lfo = 0.5;
	var sig, env, susenv, susgen, vol_lfo;

	susenv = Env([1, 1.35, 1], [0.3, 2.7]);
	susgen = EnvGen.kr(susenv, \trig.tr);
	env = EnvGen.kr(Env.adsr(3, 1, 0.2, 5, curve: -2), \wgate.kr(0), doneAction: 2);
	vol_lfo = LFNoise1.kr(global_lfo, 0.5, 0.5);
	sig = SinOsc.ar(\wfreq.kr(10, lag: 3) + Rand(-1, 1)) * env * susgen;
	sig = sig * (~pieceamp + 0.2) * vol_lfo * master_vol;

	Out.ar(0, Pan2.ar(sig, wpan.lag(3)));

}).add;
);

( //CAVALLI
SynthDef.new(\knight, {
	arg out = 0,
	     buf = 0,
	     lagtime = 3,
	     npan = 0,
	     master_vol = 0,
	     global_lfo = 0.5;
	var sig, env, bufpos, detune, susenv, susgen, vol_lfo;

	susenv = Env([1, 1.3, 1], [0.3, 2.7]);
	susgen = EnvGen.kr(susenv, \trig.tr);
	env = EnvGen.kr(Env.adsr(3, 1, 0.1, 5, curve: -2), \ngate.kr(0), doneAction: 2);
	detune = LFNoise1.kr(0.2!4).bipolar(0.2).midiratio;
	bufpos = LFNoise1.kr(0.5).range(0, 1);
	vol_lfo = LFNoise1.kr(global_lfo, 0.5, 0.5);
	sig = VOsc.ar(bufpos, \nfreq.kr(~rootz).lag(lagtime) * detune, mul: ~pieceamp) * vol_lfo * env * susgen;

	sig = Mix.new(sig) * master_vol;
	Out.ar(out, Pan2.ar(sig, npan.lag(3)));

}).add;
);

( //ALFIERI
SynthDef.new(\bishop, {
	arg out = 0,
	     buf = 0,
	     lagtime = 3,
	     bpan = 0,
	     master_vol = 0,
	     global_lfo = 0.5;
	var sig, env, bufpos, detune, susenv, susgen, vol_lfo;

	susenv = Env([1, 1.3, 1], [0.3, 2.7]);
	susgen = EnvGen.kr(susenv, \trig.tr);
	env = EnvGen.kr(Env.adsr(3, 1, 0.1, 5, curve: -2), \bgate.kr(0), doneAction: 2);
	detune = LFNoise1.kr(0.2!4).bipolar(0.2).midiratio;
	bufpos = LFNoise1.kr(0.5).range(2, 3);
	vol_lfo = LFNoise1.kr(global_lfo, 0.5, 0.5);
	sig = VOsc.ar(bufpos, \bfreq.kr(~rootz).lag(lagtime) * detune, mul: ~pieceamp) * vol_lfo * env * susgen;

	sig = Mix.new(sig) * master_vol;
	Out.ar(out, Pan2.ar(sig, bpan.lag(3)));

}).add;
);

( //TORRI
SynthDef.new(\rook, {
	arg out = 0,
	     buf = 0,
	     lagtime = 3,
	     rpan = 0,
	     master_vol = 0,
	     global_lfo = 0.5;
	var sig, env, bufpos, detune, susenv, susgen, vol_lfo;

	susenv = Env([1, 1.3, 1], [0.3, 2.7]);
	susgen = EnvGen.kr(susenv, \trig.tr);
	env = EnvGen.kr(Env.adsr(3, 1, 0.1, 5, curve: -2), \rgate.kr(0), doneAction: 2);
	detune = LFNoise1.kr(0.2!4).bipolar(0.2).midiratio;
	bufpos = LFNoise1.kr(0.5).range(4, 5);
	vol_lfo = LFNoise1.kr(global_lfo, 0.5, 0.5);
	sig = VOsc.ar(bufpos, \rfreq.kr(~rootz).lag(lagtime) * detune, mul: ~pieceamp) * vol_lfo * env * susgen;

	sig = Mix.new(sig) * master_vol;
	Out.ar(out, Pan2.ar(sig, rpan.lag(3)));

}).add;
);

( //REGINE
SynthDef.new(\queen, {
	arg out = 0,
	     buf = 0,
	     lagtime = 3,
	     qpan = 0,
	     master_vol = 0,
	     global_lfo = 0.5;
	var sig, env, bufpos, detune, susgen, susenv, vol_lfo;

	susenv = Env([1, 1.3, 1], [0.3, 2.7]);
	susgen = EnvGen.kr(susenv, \trig.tr);
	env = EnvGen.kr(Env.adsr(3, 1, 0.1, 5, curve: -2), \qgate.kr(0), doneAction: 2);
	detune = LFNoise1.kr(0.2!4).bipolar(0.2).midiratio;
	bufpos = LFNoise1.kr(0.5).range(6, 7);
	vol_lfo = LFNoise1.kr(global_lfo, 0.5, 0.5);
	sig = VOsc.ar(bufpos, \qfreq.kr(~rootz).lag(lagtime) * detune, mul: ~pieceamp) * vol_lfo * env * susgen;

	sig = Mix.new(sig) * master_vol;
	Out.ar(out, Pan2.ar(sig, qpan.lag(3)));

}).add;
);

( //RE
SynthDef.new(\king, {
	arg kpan;
	var klinea,
	     env,
	     sig;

	klinea = Env.linen(1.2, 0.2, 1.6, 0.9, \welch);
	env = EnvGen.kr(klinea, doneAction: 2);
	sig = PinkNoise.ar(mul: ~pieceamp) * env * 0.8;

	Out.ar(0, Pan2.ar(sig, kpan, 0.8));

}).add
);


///////////////////////////////////////////////////////////////////////////////////////////////////////
//SYNTH PER CONDIZIONI SPECIALI:

( //SCACCO
	SynthDef(\check, {
	arg freq = 100,
	     mRatio = 1.01,
	     index = 1.01,
	     iScale = 1.01,
	     cAtk = 0.05,
	     cRel = -2,
	     out=0;
		var car,
	         mod,
	         env,
	         iEnv;

		iEnv = EnvGen.kr(Env([index, index * iScale, index], [0.1, 2], [cAtk, cRel]));
		env = EnvGen.kr(Env.perc(0.1, 5, curve: -4), doneAction:2);
		mod = SinOsc.ar(freq * mRatio, mul: freq * mRatio * iEnv);
		car = SinOsc.ar(freq + mod) * env * 0.3;

		Out.ar(out, Pan2.ar(car, 0));

	}).add;
);

 ( //PRESA
SynthDef.new(\capture, {
	arg out = 0;
	var senv,
		 sbzz;
	~freq = 1000;
	~num = 10;

	senv = EnvGen.kr(Env.perc(attackTime: 0.01, releaseTime: 5.0, level: 1.0, curve: 4.0), doneAction: 2);
	sbzz = Pan2.ar(Mix.fill(~num, { |i| Resonz.ar(Dust2.ar(2), ~freq * ( i + 2), 0.001, 300)}) * ~num.reciprocal*7);

	Out.ar(out, sbzz * senv * 0.5);

}).add;
);

( //PROMOZIONE
SynthDef(\promotion, {
	var sig,
	     env;

	env = EnvGen.kr(Env([0, 1, 0], [1, 4]), doneAction: 2);
	sig = Saw.ar(Rand(35, 50)) * SinOsc.kr(3);
	sig= BPF.ar(sig, Rand(400, 1000), 0.9);
	sig = (sig * env);

	Out.ar(0, Pan2.ar(sig, 0, 1));

}).add;
);

 ( //MATTO
SynthDef.new(\mate, {
		arg freq = 10,
		     mRatio = 1.4251,
		     index = 1.34,
		     cAtk = 0.5,
		     cRel = (-2),
		     amp = 0.2,
		     atk = 2,
		     rel = 8,
		     pan = 0,
		     out = 0;
		var car,
		     mod,
		     env,
		     iEnv,
		     block;

3.do( {
		iEnv = EnvGen.kr(Env([index, index * rrand(0.5, 1.5), index], [atk, rel], [cAtk, cRel]));
		env = EnvGen.kr(Env.perc(atk, rel, curve: [cAtk, cRel]), doneAction:2);
		mod = SinOsc.ar(freq * mRatio, iEnv);
		car = SinOsc.ar((freq * ~piecesleft + mod) * rrand(0.9, 1.1)) * env * 0.10;

		Out.ar(out, Pan2.ar(car, pan));
		});

}).add;
);

 ( //PATTA/STALLO
SynthDef.new(\draw, {
					arg freq = 10,
		     mRatio = 1.4251,
		     index = 1.34,
		     cAtk = 0.5,
		     cRel = (-2),
		     amp = 0.2,
		     atk = 2,
		     rel = 8,
		     pan = 0,
		     out = 0;
		var car,
		     mod,
		     env,
		     iEnv,
		     block;

			iEnv = EnvGen.kr(Env([index, index * rrand(1.5, 3.5), index], [atk, rel], [cAtk, cRel]));
		env = EnvGen.kr(Env.perc(atk, rel, curve: [cAtk, cRel]), doneAction:2);
		mod = SinOsc.ar(freq * mRatio, iEnv);
		car = SinOsc.ar((freq * ~piecesleft + mod) * rrand(0.9, 1.1)) * env * 0.5;

				Out.ar(out, Pan2.ar(car, pan));

}).add;
);

///////////////////////////////////////////////////////////////////////////////////////////////////////
//MESSAGGI OSC:

//ARRAYS
~pawns = Array.fill (16, {Synth.new(\pawn)});
~rooks = Array.fill (8, {Synth.new(\rook)});
~bishops = Array.fill (8, {Synth.new(\bishop)});
~knights = Array.fill (8, {Synth.new(\knight)});
~queens = Array.fill (8, {Synth.new(\queen)});


//CONTROL BUSSES
~master_vol = Bus.control(s);
~global_lfo = Bus.control(s);


//MIDI INPUT

MIDIFunc.cc({arg ...args;
	~master_vol.value = args[0] * - 0.01;
}, ccNum: 0, chan: 0);

MIDIFunc.cc({arg ...args;
	~global_lfo.value = args[0] / 12.7;
}, ccNum: 1, chan: 0);


//OSC
(
OSCdef('ww', {
	arg wmsg;
	var num = wmsg[1],
	     yy = wmsg[2],
	     xx = wmsg[3],
	     gate = wmsg[4];
	[wmsg].postln;

	~pawns[num].set(
		\wfreq, (~notes[yy, xx] + ~root).midicps,
		\wpan, yy.linlin(0, 7, -1, 1),
		\wgate, gate,
		\trig, 1);
	~pawns[num].map(\master_vol, ~master_vol);
	~pawns[num].map(\global_lfo, ~global_lfo);
}, "/pedone" );
);

(
OSCdef('rr', {
	arg wmsg;
	var num = wmsg[1],
	     yy = wmsg[2],
	     xx = wmsg[3],
	     gate = wmsg[4];
	[wmsg].postln;

	~rooks[num].set(
		\rfreq, (~notes[yy, xx] + ~root).midicps,
		\rpan, yy.linlin(0, 7, -1, 1),
		\rgate, gate,
		\trig, 1);
	~rooks[num].map(\master_vol, ~master_vol);
	~rooks[num].map(\global_lfo, ~global_lfo);
}, "/torre" );
);

(
OSCdef('bb', {
	arg wmsg;
	var num = wmsg[1],
	     yy = wmsg[2],
	     xx = wmsg[3],
	     gate = wmsg[4];
	[wmsg].postln;

	~bishops[num].set(
		\bfreq, (~notes[yy, xx] + ~root).midicps,
		\bpan, yy.linlin(0, 7, -1, 1),
		\bgate, gate,
		\trig, 1);
	~bishops[num].map(\master_vol, ~master_vol);
	~bishops[num].map(\global_lfo, ~global_lfo);
}, "/alfiere" );
);

(
OSCdef('nn', {
	arg wmsg;
	var num = wmsg[1],
	     yy = wmsg[2],
	     xx = wmsg[3],
	     gate = wmsg[4];
	[wmsg].postln;

	~knights[num].set(
		\nfreq, (~notes[yy, xx] + ~root).midicps,
		\npan, yy.linlin(0, 7, -1, 1),
		\ngate, gate,
		\trig, 1);
	~knights[num].map(\master_vol, ~master_vol);
	~knights[num].map(\global_lfo, ~global_lfo);
}, "/cavallo" );
);

(
OSCdef('qq', {
	arg wmsg;
	var num = wmsg[1],
	     yy = wmsg[2],
	     xx = wmsg[3],
	     gate = wmsg[4];
	[wmsg].postln;

	~queens[num].set(
		\qfreq, (~notes[yy, xx] + ~root).midicps,
		\qpan, yy.linlin(0, 7, -1, 1),
		\qgate, gate,
		\trig, 1);
	~queens[num].map(\master_vol, ~master_vol);
	~queens[num].map(\global_lfo, ~global_lfo);
}, "/regina" );
);

(
OSCdef('kk', {
	arg wmsg;
	var pan = wmsg[1];
	[wmsg].postln;

	k = Synth.new(\king, [\kpan, pan.linlin(0, 7, -1, 1)]);
	k.map(\master_vol, ~master_vol);
}, "/re" );
);

(
OSCdef('ck', {
	arg wmsg;
	[wmsg].postln;

	c = Synth.new(\check, [
		 \freq, rrand(350.1, 400),
	     \mRatio, rrand(1.01, 1.49),
	     \index, rrand(1.01, 1.5),
	     \iScale, rrand(1.01, 1.5),
	     \cAtk, rrand(0.05, 0.2),
		 \cRel, rrand(-2, -3)]);
	c.map(\master_vol, ~master_vol);
}, "/scacco" );
);

(
OSCdef('cap', {
	arg wmsg;
	[wmsg].postln;

	x = Synth.new(\capture);
	x.map(\master_vol, ~master_vol);
	~piecesleft = ~piecesleft - 1;
}, "/presa" );
);

(
OSCdef('pro', {
	arg wmsg;
	[wmsg].postln;

	p = Synth.new(\promotion);
	p.map(\master_vol, ~master_vol);
}, "/promozione" );
);

(
OSCdef('mt', {
	arg wmsg;
	[wmsg].postln;

	m = Synth.new(\mate);
	m.map(\master_vol, ~master_vol);
	~pawns.do(_.set(\lagtime, 20, \wfreq, 50));
	~rooks.do(_.set(\lagtime, 20, \rfreq, 50));
	~knights.do(_.set(\lagtime, 20, \nfreq, 50));
	~bishops.do(_.set(\lagtime, 20, \bfreq, 50));
	~queens.do(_.set(\lagtime, 20, \qfreq, 50));
}, "/matto" );
);

(
OSCdef('dw', {
	arg wmsg;
	var pan = wmsg[1];
	[wmsg].postln;

	Synth.new(\draw, [\kpan, pan]);
}, "/patta" );
);

)

///////////////////////////////////////////////////////////////////////////////////////////


// try
Synth.new(\pawn)

