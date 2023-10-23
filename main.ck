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
OscIn oin;
// create our OSC message
OscMsg msg;
// use port 12345
12345 => oin.port;
// create an address in the receiver, expect an int and a float
oin.addAddress( "/freq, f" );
oin.addAddress( "/filter, f" );


while(true)
{
    oin => now;
    <<<"got message">>>;
    
    while( oin.recv(msg) )
    {
        if (msg.address == "/freq")
        {
            float pitch;
            int length;
            msg.getFloat(0) => pitch;
            500 => length;
            spork~ myString.playNote(pitch, length::ms);
        }
        if (msg.address == "/filter")
        {
            float filt;
            msg.getFloat(0) => filt;
            myString.changeFilter(filt);
            <<< "gotfilt" >>>;
        }
    }
}
