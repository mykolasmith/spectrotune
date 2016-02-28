void keyPressed() {
  switch(keyCode) {
    case RIGHT:
      PEAK_THRESHOLD += 5;
      ui.getController("Threshold").setValue(PEAK_THRESHOLD);
      break;
      
    case LEFT:
      PEAK_THRESHOLD -= 5;
      ui.getController("Threshold").setValue(PEAK_THRESHOLD);
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