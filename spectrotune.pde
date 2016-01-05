import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import rwmidi.*;
import controlP5.*;
import java.lang.reflect.InvocationTargetException;

//int bufferSize = 32768;
//int bufferSize = 16384;
//int bufferSize = 8192;
//int bufferSize = 4096;
int bufferSize = 2048;
int sampleRate = 44100;
//int bufferSize = 1024;
//int bufferSize = 512;

// since we are dealing with small buffer sizes (1024) but are trying to detect peaks at low frequency ranges
// octaves 0 .. 2 for example, zero padding is nessessary to improve the interpolation resolution of the FFT
// otherwise FFT bins will be quite large making it impossible to distinguish between low octave notes which
// are seperated by only a few Hz in these ranges.

int PEAK_THRESHOLD = 50; // default peak threshold

//float framesPerSecond = 25.0;

// MIDI notes span from 0 - 128, octaves -1 -> 9. Specify start and end for piano
int keyboardStart = 12; // 12 is octave C0
int keyboardEnd = 108;

Minim minim;
AudioInput in;
Sampler sampler;
ControlP5 ui;
Window window;
Smooth smoother;

Tab tabDefault;
Tab tabWindowing;
Tab tabSmoothing;
Tab tabMIDI;
Tab tabFFT;

Toggle toggleLinearEQ;
Toggle togglePCP;
Toggle toggleMIDI;
Toggle toggleHarmonics;

Slider sliderBalance;
Slider sliderThreshold;

Textlabel labelThreshold;

FFT fft;

MidiOutput midiOut;

PImage bg;
PImage whiteKey;
PImage blackKey;
PImage octaveBtn;

int fftBufferSize = bufferSize;
int fftSize = fftBufferSize/2;

float[] buffer = new float[fftBufferSize];
float[] spectrum = new float[fftSize];
int[] peak = new int[fftSize];

int[] fftBinStart = new int[8]; 
int[] fftBinEnd = new int[8];
float[] scaleProfile = new float[12];

float linearEQIntercept = 1f; // default no eq boost
float linearEQSlope = 0f; // default no slope boost

// Toggles and their defaults
boolean LINEAR_EQ_TOGGLE = false;
boolean PCP_TOGGLE = true;
boolean HARMONICS_TOGGLE = true;
boolean MIDI_TOGGLE = true;
boolean SMOOTH_TOGGLE = true;
int SMOOTH_POINTS = 3;

boolean UNIFORM_TOGGLE = true;
boolean DISCRETE_TOGGLE = false;
boolean LINEAR_TOGGLE = false;
boolean QUADRATIC_TOGGLE = false;
boolean EXPONENTIAL_TOGGLE = false;

boolean TRACK_LOADED = false;

boolean[] OCTAVE_TOGGLE = {false, true, true, true, true, true, true, true};
int[] OCTAVE_CHANNEL = {0,0,0,0,0,0,0,0}; // set all octaves to channel 0 (0-indexed channel 1)

//public static final int NONE = 0;

public static final int PEAK = 1;
public static final int VALLEY = 2;
public static final int HARMONIC = 3;
public static final int SLOPEUP = 4;
public static final int SLOPEDOWN = 5;

void setup() {
  size(510, 288);
  
  //frameRate(framesPerSecond); // lock framerate
  
  // Create MIDI output interface - select the first found device by default
  midiOut = RWMidi.getOutputDevices()[0].createOutput();

  // Initialize Minim
  minim = new Minim(this);
  
  sampler = new Sampler();
  in = minim.getLineIn(Minim.MONO, bufferSize, sampleRate);
  in.addListener(sampler);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  
  window = new Window();
  smoother = new Smooth();
  
  // Equalizer settings. Need a tab for this.
  linearEQIntercept = 1f;
  linearEQSlope = 0.01f;
  
  // UI Images
  bg = loadImage("background.png");
  whiteKey = loadImage("whitekey.png");
  blackKey = loadImage("blackkey.png");
  octaveBtn = loadImage("octavebutton.png");
   
  // ui UI
  ui = new ControlP5(this);
  
  tabDefault = ui.addTab("default").activateEvent(true);
  tabFFT = ui.addTab("FFT").activateEvent(true);
  tabWindowing = ui.addTab("windowing").activateEvent(true);
  tabSmoothing = ui.addTab("smoothing").activateEvent(true);
  tabMIDI = ui.addTab("midi").activateEvent(true);

  // GENERAL TAB
  tabDefault.setLabel("GENERAL");
  ui.addTextlabel("labelGeneral", "GENERAL", 380, 10).moveTo("default");
  
  // Pitch class profile toggle
  ui.addToggle("togglePCP", PCP_TOGGLE)
    .setPosition(380, 30)
    .setSize(10,10)
    .setLabel("Pitch Class Profile")
    .setColorForeground(0x8000ffc8)
    .setColorActive(0xff00ffc8);
  
   // Pitch class profile toggle
  ui.addToggle("toggleLinearEQ", LINEAR_EQ_TOGGLE)
    .setPosition(380,60)
    .setSize(10,10)
    .setLabel("Linear EQ")
    .setColorForeground(0x8000ffc8)
    .setColorActive(0xff00ffc8);
  
  ui.addToggle("toggleHarmonics", HARMONICS_TOGGLE)
    .setPosition(380, 90)
    .setSize(10, 10)
    .setLabel("Harmonics Filter")
    .setColorForeground(0x9000ffc8)
    .setColorActive(0xff00ffc8);
  
  ui.addSlider("balance", -100, 100, 0, 380, 120, 50, 10)
    .setValueLabel(" CENTER");
    
  // Peak detect threshold slider
  ui.addSlider("Threshold", 0, 255, PEAK_THRESHOLD, 380, 140, 75, 10)
    .setId(1);
  
  // MIDI TAB
  ui.addTextlabel("labelMIDI", "MIDI", 380, 10).moveTo(tabMIDI);
  
  // MIDI output toggle
  ui.addToggle("toggleMIDI", MIDI_TOGGLE)
    .setPosition(380, 30)
    .setSize(10,10)
    .setLabel("MIDI OUTPUT")
    .moveTo(tabMIDI);
  
  Numberbox oct0 = ui.addNumberbox("oct0", 1, 380, 60, 20, 14);
  Numberbox oct1 = ui.addNumberbox("oct1", 1, 410, 60, 20, 14); 
  Numberbox oct2 = ui.addNumberbox("oct2", 1, 440, 60, 20, 14);
  Numberbox oct3 = ui.addNumberbox("oct3", 1, 470, 60, 20, 14);
  
  Numberbox oct4 = ui.addNumberbox("oct4", 1, 380, 90, 20, 14);
  Numberbox oct5 = ui.addNumberbox("oct5", 1, 410, 90, 20, 14); 
  Numberbox oct6 = ui.addNumberbox("oct6", 1, 440, 90, 20, 14);
  Numberbox oct7 = ui.addNumberbox("oct7", 1, 470, 90, 20, 14);
  
  // move MIDI Channels to midi tab
  oct0.moveTo(tabMIDI);
  oct1.moveTo(tabMIDI);
  oct2.moveTo(tabMIDI);
  oct3.moveTo(tabMIDI);
  oct4.moveTo(tabMIDI);
  oct5.moveTo(tabMIDI);
  oct6.moveTo(tabMIDI);
  oct7.moveTo(tabMIDI);
  
  RadioButton radioMidiDevice = ui.addRadioButton("radioMidiDevice", 36, 30);
  for(int i = 0; i < RWMidi.getOutputDevices().length; i++) {
    radioMidiDevice.addItem(RWMidi.getOutputDevices()[i] + "", i);
  }
  radioMidiDevice.moveTo(tabMIDI);
  radioMidiDevice.activate(0);
  
  // WINDOWING TAB
  ui.addTextlabel("labelWindowing", "WINDOWING", 380, 10).moveTo(tabWindowing);

  ui.addRadioButton("radioWindow", 380, 30)
    .addItem("RECTANGULAR", Window.RECTANGULAR)
    .addItem("HAMMING", Window.HAMMING)
    .addItem("HANN", Window.HANN)
    .addItem("COSINE", Window.COSINE)
    .addItem("TRIANGULAR", Window.TRIANGULAR)
    .addItem("BLACKMAN", Window.BLACKMAN)
    .addItem("GAUSS", Window.GAUSS)
    .moveTo(tabWindowing);
  
  ui.addTextlabel("labelSmoothing", "SMOOTHING", 380, 10)
    .moveTo(tabSmoothing);
  
  ui.addRadioButton("radioSmooth", 380, 30)
    .addItem("NONE", Smooth.NONE)
    .addItem("RECTANGLE", Smooth.RECTANGLE)
    .addItem("TRIANGLE", Smooth.TRIANGLE)
    .addItem("AJACENT AVERAGE", Smooth.ADJAVG)
    .moveTo(tabSmoothing);
  
  // Smoothing points slider
  ui.addSlider("Points", 1, 10, SMOOTH_POINTS, 380, 100, 75, 10)
    .setId(2)
    .moveTo(tabSmoothing);

  // FILE TAB -- think about adding sDrop support.. may be better

  
  ui.addTextlabel("labelFFT", "FFT", 380, 10).moveTo(tabFFT);
  
  // FFT bin distance weighting radios
  //ui.addTextlabel("labelWeight", "FFT WEIGHT", 380, 30);
  ui.addRadioButton("radioWeight", 380, 30)
    .addItem("UNIFORM (OFF)", UNIFORM) // default
    .addItem("DISCRETE", DISCRETE)
    .addItem("LINERAR", LINEAR)
    .addItem("QUADRATIC", QUADRATIC)
    .addItem("EXPONENTIAL", EXPONENTIAL)
    .moveTo(tabFFT);
  
  ui.addTextlabel("labelThreshold", "THRESHOLD", PEAK_THRESHOLD + 26, 60)
    .moveTo(tabFFT);
  
  // GLOBAL UI  
  textFont(createFont("Arial", 10, true));
  rectMode(CORNERS);
  smooth();
}

void draw() {
  sampler.draw(); // synchronized
}

void stop() {
  closeMIDINotes(); // close any open MIDI notes
  minim.stop();
  super.stop();
}