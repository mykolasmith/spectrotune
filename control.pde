void keyPressed() {
  switch(key) {
    case ' ': // pause/play toggle
      break;
      
    case 'm': // mute audio toggle
      break;
      
    case 'n': // mute midi toggle
      MIDI_TOGGLE = !MIDI_TOGGLE;
      toggleMIDI.setState(MIDI_TOGGLE);
      break;
    
    case 'e': // turn equalizer on/off
      LINEAR_EQ_TOGGLE = !LINEAR_EQ_TOGGLE;
      toggleLinearEQ.setState(LINEAR_EQ_TOGGLE);
      break;
    
    case 'p': // turn PCP on/off
      PCP_TOGGLE = !PCP_TOGGLE;
      togglePCP.setState(PCP_TOGGLE);
      break;
      
    case 'h': // turn Harmonic filter on/off
      HARMONICS_TOGGLE = !HARMONICS_TOGGLE;
      toggleHarmonics.setState(HARMONICS_TOGGLE);
      break;
    
    // Octave Toggles
    case '0':
      OCTAVE_TOGGLE[0] = !OCTAVE_TOGGLE[0];
      break;
    case '1':
      OCTAVE_TOGGLE[1] = !OCTAVE_TOGGLE[1];
      break;
    case '2':
      OCTAVE_TOGGLE[2] = !OCTAVE_TOGGLE[2];
      break;
    case '3':
      OCTAVE_TOGGLE[3] = !OCTAVE_TOGGLE[3];
      break;
    case '4':
      OCTAVE_TOGGLE[4] = !OCTAVE_TOGGLE[4];
      break;
    case '5':
      OCTAVE_TOGGLE[5] = !OCTAVE_TOGGLE[5];
      break;
    case '6':
      OCTAVE_TOGGLE[6] = !OCTAVE_TOGGLE[6];
      break;
    case '7':
      OCTAVE_TOGGLE[7] = !OCTAVE_TOGGLE[7];
      break;
  }
  
  switch(keyCode) {
    case RIGHT:
      PEAK_THRESHOLD += 5;
      sliderThreshold.setValue(PEAK_THRESHOLD);
      break;
      
    case LEFT:
      PEAK_THRESHOLD -= 5;
      sliderThreshold.setValue(PEAK_THRESHOLD);
      break;
  }
}

// ControlP5 events
void controlEvent(ControlEvent event) {
  if ( event.isController() ) {
    switch(event.getController().getId()) {
      case(1):
        PEAK_THRESHOLD = (int)(event.getController().getValue());
        break;
      case(2):
        break;
      case(3): // Progress Slider
        break;
    }
  }
}

void radioWeight(int type) {
  WEIGHT_TYPE = type;
}

void radioMidiDevice(int device) {
  midiOut = RWMidi.getOutputDevices()[device].createOutput();
}

void radioWindow(int mode) {
  window.setMode(mode);
}

void radioSmooth(int mode) {
  smoother.setMode(mode, SMOOTH_POINTS);
}

void togglePCP(boolean flag) {
  PCP_TOGGLE = flag;
}

void toggleMIDI(boolean flag) {
  MIDI_TOGGLE = flag;
  if ( ! MIDI_TOGGLE ) {
    closeMIDINotes();
  }
}

void toggleLinearEQ(boolean flag) {
  LINEAR_EQ_TOGGLE = flag;
}

void toggleHarmonics(boolean flag) {
  HARMONICS_TOGGLE = flag;
}

void oct0(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[0] = channel -1;
  }
}
void oct1(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[1] = channel -1;
  }
}
void oct2(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[2] = channel -1;
  }
}
void oct3(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[3] = channel -1;
  }
}
void oct4(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[4] = channel -1;
  }
}
void oct5(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[5] = channel -1;
  }
}
void oct6(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[6] = channel -1;
  }
}
void oct7(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[7] = channel -1;
  }
}

void balance(int value) {
  sliderBalance.setValueLabel(value + "%");
  if ( value == 0 ) {
    sliderBalance.setValueLabel("  CENTER");
  } else if ( value < 0 ) {
    sliderBalance.setValueLabel(value * -1 + "% LEFT");
  } else if ( value > 0 ) {
    sliderBalance.setValueLabel(value + "% RIGHT");
  }
}