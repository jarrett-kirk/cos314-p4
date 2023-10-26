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
    
    fun void playNote(float MIDInote, dur noteDur)
    {
        Std.mtof(MIDInote) => s.freq;
        
        e.keyOn();
        noteDur => now;
        e.keyOff();
        e.releaseTime() => now;
    }
    
    fun void changeFilter(float filterFreq)
    {
        filterFreq => f.freq;
    }
}


PluckedString myStrings[5];
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
OSCin.event("/mySlider,i") @=> OscEvent slider_event; 
OSCin.event("/myXY,ffffff") @=> OscEvent XY_event; 
OSCin.event("/myFreq,i") @=> OscEvent freq_event; 
OSCin.event("/high_sequence,i") @=> OscEvent high_seq_event;
OSCin.event("/low_sequence,i") @=> OscEvent low_seq_event;

//setting up some global variables that can store the values from OSC messages
int sliderVal;
float X;
float Y;
float X1;
float X2;
float X3;
float X4;
int freq0;
int freq1;
int freq2;
int freq3;
int high; // higher sequence
int low; // lower sequence

spork~ receiveSlider();
spork~ receiveXY();
spork~ receiveFreq();
spork~ receiveHighSequence();
spork~ receiveLowSequence();

while(true)
{
    //just passing time in the higher level while the sporked functions run
    1::second => now;
}

fun void receiveSlider()
{
    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        slider_event => now;        
        // grab the next message from the queue. 
        while ( slider_event.nextMsg() != 0 )
        { 
            // getInt fetches the expected int (as indicated by "i")
            slider_event.getInt() => sliderVal;
            // print
            <<< "got Slider (via OSC):", sliderVal >>>;
            
            for (0 => int i; i < myStrings.cap(); i++) {
                myStrings[i].changeFilter(sliderVal);
            }
        }
    }
}

fun void receiveXY()
{
    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        XY_event => now;
        
        //grab the next message from the queue
        while ( XY_event.nextMsg()  != 0 )
        { 
            // getFloat fetches the expected floats (as indicated by "ffffff")
            XY_event.getFloat() => X;
            XY_event.getFloat() => Y;
            XY_event.getFloat() => X1;
            XY_event.getFloat() => X2;
            XY_event.getFloat() => X3;
            XY_event.getFloat() => X4;
            // print
            <<< "got XY (via OSC):", X, " ", Y >>>;   
            
            [X, X1, X2, X3, X4] @=> float notes[];
            for (0 => int i; i < myStrings.cap(); i++) {
                myStrings[i].changeFilter(Y);
                spork~ myStrings[i].playNote(notes[i], 1::week);
            }   
        }
    }
}

fun void receiveFreq()
{
    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        freq_event => now;       
        // grab the next message from the queue. 
        while ( freq_event.nextMsg() != 0 )
        { 
            // getInt fetches the expected int (as indicated by "i")
            freq_event.getInt() => freq0;
            if (freq0 != 0) { spork~ myString.playNote(freq0, 10::ms); }          
        }
    }
}

fun void receiveHighSequence() 
{
    while ( true )
    {
        // wait for event to arrive
        high_seq_event => now;
        
        //grab the next message from the queue
        while ( high_seq_event.nextMsg()  != 0 )
        { 
            high_seq_event.getInt() => high;
            
            spork~ myString.playNote(high, 200::ms);
        }
    }
}

fun void receiveLowSequence() 
{
    while ( true )
    {
        // wait for event to arrive
        low_seq_event => now;
        
        //grab the next message from the queue
        while ( low_seq_event.nextMsg()  != 0 )
        { 
            low_seq_event.getInt() => low;
            
            spork~ myString.playNote(low, 200::ms);
        }
    }
}
