class Sampler implements AudioListener
{
  
  Sampler() {}
  
  synchronized void samples(float[] samples) {
    process(samples);
  }
  
  synchronized void samples(float[] left, float[] right) {}
  
  void process(float[] samples) {
    window.transform(samples); // add window to samples
    arrayCopy(samples, 0, buffer, 0, samples.length);
    analyze();
    outputMIDINotes();      
  }
  
  void analyze() {
    fft.forward(buffer); // run fft on the buffer
    
    //smoother.apply(fft); // run the smoother on the fft spectra
    
    float[] binDistance = new float[bufferSize];
    float[] freq = new float[bufferSize];
    
    float[] pcp = new float[bufferSize];
    notes = new Note[128];
    
    float freqLowRange = octaveLowRange(0);
    float freqHighRange = octaveHighRange(7);
    
    for (int k = 0; k < fftSize; k++) {
      freq[k] = k / (float)fftBufferSize * in.sampleRate();
      
      // skip FFT bins that lay outside of octaves 0-9 
      if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
   
      // Calculate fft bin distance and apply weighting to spectrum
      float closestFreq = pitchToFreq(freqToPitch(freq[k])); // Rounds FFT frequency to closest semitone frequency
      boolean filterFreq = false;
  
      // Filter out frequncies from disabled octaves    
      for ( int i = 0; i < 8; i ++ ) {
        if ( !OCTAVE_TOGGLE[i] ) {
          if ( closestFreq >= octaveLowRange(i) && closestFreq <= octaveHighRange(i) ) {
            filterFreq = true;
          }
        }
      }
      
      // Set spectrum 
      if ( !filterFreq ) {
        binDistance[k] = 2 * abs((12 * log(freq[k]/440.0) / log(2)) - (12 * log(closestFreq/440.0) / log(2)));
        
        spectrum[k] = fft.getBand(k) * binWeight(WEIGHT_TYPE, binDistance[k]);
        
        if ( LINEAR_EQ_TOGGLE ) {
          spectrum[k] *= (linearEQIntercept + k * linearEQSlope);
        }
        
        // Sum PCP bins
        pcp[freqToPitch(freq[k]) % 12] += pow(fft.getBand(k), 2) * binWeight(WEIGHT_TYPE, binDistance[k]);
      }
    }
    
    normalizePCP();
    
    if ( PCP_TOGGLE ) {
      for ( int k = 0; k < fftSize; k++ ) {
        if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
        spectrum[k] *= pcp[freqToPitch(freq[k]) % 12];  
       }
     }
    
    float sprev = 0;
    float scurr = 0;
    float snext = 0;
    
    float[] foundPeak = new float[0];
    float[] foundLevel = new float[0];
    
    // find the peaks and valleys
    for (int k = 1; k < fftSize -1; k++) {
      if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
      
      sprev = spectrum[k-1];
      scurr = spectrum[k];
      snext = spectrum[k+1];
        
      if ( scurr > sprev && scurr > snext && (scurr > PEAK_THRESHOLD) ) { // peak
        // Parobolic Peak Interpolation to estimate the real peak frequency and magnitude
        float ym1 = sprev;
        float y0 = scurr;
        float yp1 = snext;
        
        float p = (yp1 - ym1) / (2 * ( 2 * y0 - yp1 - ym1));
        float interpolatedAmplitude = y0 - 0.25 * (ym1 - yp1) * p;
        float a = 0.5 * (ym1 - 2 * y0 + yp1);  
        
        float interpolatedFrequency = (k + p) * in.sampleRate() / fftBufferSize;
        
        if ( freqToPitch(interpolatedFrequency) != freqToPitch(freq[k]) ) {
          freq[k] = interpolatedFrequency;
          spectrum[k] = interpolatedAmplitude;
        }
        
        boolean isHarmonic = false;
        
        // filter harmonics from peaks
        if ( HARMONICS_TOGGLE ) {
          for ( int f = 0; f < foundPeak.length; f++ ) {
            //TODO: Cant remember why this is here
            if (foundPeak.length > 2 ) {
              isHarmonic = true;
              break;
            }
            // If the current frequencies note has already peaked in a lower octave check to see if its level is lower probably a harmonic
            if ( freqToPitch(freq[k]) % 12 == freqToPitch(foundPeak[f]) % 12 && spectrum[k] < foundLevel[f] ) {
              isHarmonic = true;
              break;
            }
          }
        }
  
        if ( isHarmonic ) {        
          peak[k] = HARMONIC;
        } else {
          peak[k] = PEAK;
          
          Note note = new Note(freq[k], spectrum[k]);
          notes = (Note[])append(notes, note);
          //midiOut.sendNoteOn(note.channel, note.pitch, note.velocity);
          
          // Track Peaks and Levels in this pass so we can detect harmonics 
          foundPeak = append(foundPeak, freq[k]);
          foundLevel = append(foundLevel, spectrum[k]);    
        }
      }
    }
  }
  
  // draw routine needs to be synchronized otherwise it will run while buffers are being populated
  synchronized void draw() { 
    render();
  }
}