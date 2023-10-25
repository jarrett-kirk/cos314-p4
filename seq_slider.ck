// ideas: 
// ui for multiple notes at once: both notes can be changed, one raw note can be changed, the other note is changed based on a ratio
// ui for modulation: dial or something to change the modulating frequency
// ui for arpeggiation/rhythm changing: can change speeds/arpegiate the sound
// ui for basic waveform change: sin, tri, sqr, etc.

class PluckedString
{
    BlitSaw s => ADSR e => LPF f=> dac;
    
    0.5 => s.gain;
    500.0 => f.freq;
    10::ms => e.attackTime;
    1000::ms => e.decayTime;
    0.2 => e.sustainLevel;
    100::ms => e.releaseTime;
    
    fun void playNote(int MIDInote, dur noteDur)
    {
        Std.mtof(MIDInote) => s.freq;
        
        e.keyOn();
        noteDur => now;
        e.keyOff();
        e.releaseTime() => now;
    }
    
}


PluckedString myString;

// create our OSC receiver
OscRecv OSCin;
// create our OSC message
OscMsg msg;
// use port 1235 (why not?? just has to match the port of the sender (set in the Max patch))
1235 => OSCin.port;
//start listening to OSC messages
OSCin.listen();

// here are the addresses we're listing to.
// we create an "OscEvent" for each address, and assign it a name
OSCin.event("/mynote,i") @=> OscEvent note_event; 

//setting up some global variables that can store the values from OSC messages
int freq;

spork~ receiveNote();

while(true)
{
    //just passing time in the higher level while the sporked functions run
    1::second => now;
}

fun void receiveNote()
{
    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        note_event => now;
        
        //grab the next message from the queue
        while ( note_event.nextMsg()  != 0 )
        { 
            // getFloat fetches the expected floats (as indicated by "ffffff")
            note_event.getInt() => freq;
            
            myString.playNote(freq, 500::ms);  
        }
    }
}
