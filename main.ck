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
OSCin.event("/myXY,ff") @=> OscEvent XY_event; 

//setting up some global variables that can store the values from OSC messages
int sliderVal;
float X;
float Y;

spork~ receiveSlider();
spork~ receiveXY();

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
            
            myString.changeFilter(sliderVal);
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
            // getFloat fetches the expected floats (as indicated by "ff")
            XY_event.getFloat() => X;
            XY_event.getFloat() => Y;
            // print
            <<< "got XY (via OSC):", X, " ", Y >>>;   
            
            myString.changeFilter(Y);
            spork~ myString.playNote(X, 1::week);        
        }
    }
}

