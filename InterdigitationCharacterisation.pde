// This program draws virtual pressure sensing strips with interdigitated
// shapes (zigzags for now), and a virtual finger that swipes it.
// To identify each strip, it uses different colors, and to simulate the
// effect of a finger on it, we just count how many pixels it hides.

int zzSpikeCount = 1;           // zig-zag count
float zzSpacingRatio = 0.1;     // space between strips
float fingerRatio = 1.25;        // unit = distance between 2 strip centers

// The following global variables (in pixels) are calculated in setup()
int zzUnitWidth;                // stripe + spacing width
int zzStrokeWidth;              // stripe width - depends on screen size
int zzSpacingWidth;
int fingerWidth;

// The following global variables should not need to be modified
int stripNumber = 7;
int interStep = 10;
int colorRef = stripNumber * interStep;

int globalMax = 0;

int[] pressureIndices = new int[stripNumber];
boolean isCharacterizing = true;
float fingerPos, originalFingerPos, finalFingerPos;
float measureStep;
int retrievedPos = 0;
int[] errors;

/////////////////////////////////////////////////////////////////
void setup() {
  colorMode(HSB, colorRef);
  size(1900, 250);

  zzUnitWidth = Math.round(width / stripNumber);
  zzSpacingWidth = Math.round(zzUnitWidth * zzSpacingRatio);
  zzStrokeWidth = zzUnitWidth - zzSpacingWidth;

  // TODO: use trigonometry to calculate zzStrokeWidth well!!!

  // We want 71 data points across 3.5 stripes:
  originalFingerPos = 2 * zzUnitWidth;
  finalFingerPos = (3.5 + originalFingerPos);
  measureStep = ((finalFingerPos - originalFingerPos) / 71);
  println("measureStep");
  println(measureStep);

  fingerWidth = Math.round(fingerRatio * zzStrokeWidth);
  fingerPos = fingerWidth;

  errors = new int[width];

  // run the histogram once to initialize globalMax
  drawBackground();
  strokeWeight(0);
  fill(0, 0, colorRef, 2*colorRef/3);   // finger color
  rect(0, 0, width, fingerWidth);        // simulate a wide finger
  histogram();
}

/////////////////////////////////////////////////////////////////
void draw() {
  // draw strips
  drawBackground();

  // draw finger:
  color white = color(0, 0, colorRef);
  drawFinger(fingerPos, fingerWidth, white);

  // analyse finger impact on sensor stripes and simulate raw sensor
  int[] niceData = histogram();

  // visualize the estimated finger position using raw sensor data
  retrievedPos = drawCubicRetrievedFinger(niceData);

  if (!isCharacterizing) {
    fingerPos = mouseX;
  } else {
    characterization(fingerPos);
    fingerPos += measureStep;
  }
}

/////////////////////////////////////////////////////////////////
void characterization(int fingerPos) {
  // Save characterization data to graph is later
  if (retrievedPos > 0) {
      // compute the error:
      errors[fingerPos] = abs(fingerPos - retrievedPos);
  }

  // is the simulation finished?
  if (fingerPos >= width - fingerWidth) {
    // Plot characterization
    drawBackground();

    stroke(0);
    strokeCap(SQUARE);
    strokeWeight(6);
    for (int i = 1; i < width; i++) {
      line(i-1, height - errors[i-1],
           i,   height - errors[i]);
    }

    // draw finger in the middle as reference:
    color c = color(0, 0, colorRef, 2*colorRef/3);
    drawFinger(width/2, fingerWidth, c);

    String fileName = "charact_count" + zzSpikeCount +
                      "_spacing" + zzSpacingRatio*100 + "percent.png";
    saveFrame(fileName); // TODO: write parameters value in file

    fill(colorRef);
    rect(0,0, width, 80);

    fill(0);
    textSize(18);
    text("Graph saved as: " + fileName, 20, 30);
    text("Press any key = toggle mouse control", 20, 60);

    noLoop();
  }
}

/////////////////////////////////////////////////////////////////
void keyPressed() {
  if (isCharacterizing) {
    isCharacterizing = false;
    loop();
  } else {
    isCharacterizing = true;
    fingerPos = 0;
  }
}

/////////////////////////////////////////////////////////////////
int[] histogram() {
  // This function measures the effect of a finger on a strip.
  // It counts the pixels with a color that changed.

  int[] rawData = new int[colorRef];
  // Calculate the histogram
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      // Only focus on the strips colors (discard white finger & bacground)
      color c = get(i, j);
      if (c != color(0, 0, colorRef)) {
        int hue = int(hue(c));
        rawData[hue]++;
      }
    }
  }

  // Extract from histogram and normalize
  int[] niceData = preprocess(rawData);

  // Visualization
  drawHistogram(niceData); // simulated raw sensor data

  return niceData;
}

/////////////////////////////////////////////////////////////////
int[] preprocess(int[] rawData) {
  // Create an array only for the simulated pressure sensor data
  int[] niceData = new int[stripNumber];

  // Find the largest value in the histogram
  int histMax = max(rawData);
  globalMax = max(histMax, globalMax);

  // Pressure positions counter
  int indexCpt = 0;

  // Remove irrelevant values
  for (int i = 0; i < rawData.length; i++) {
    if (rawData[i] < 0.06*globalMax) { // 0.6% is considered noise
      rawData[i] = 0;
    } else {
      //  Trick to initialize this array only once:
      if (pressureIndices[pressureIndices.length-1] == 0) {
        // get the index of the useful values
        pressureIndices[indexCpt++] = i;
      }
    }
  }

  // Extract pressure sensor data and normalize:
  for (int i = 0; i < stripNumber; i++) {
    // count how many pixels are hidden by the finger
    rawData[pressureIndices[i]] = globalMax - rawData[pressureIndices[i]];

    // populate the array with normalized value
    niceData[i] = colorRef * rawData[pressureIndices[i]] / globalMax;
  }
  return niceData;
}

/////////////////////////////////////////////////////////////////
void drawHistogram(int[] niceData) {
  // Draw the histogram
  for (int i = 0; i < niceData.length; i++) {

    // Compute where lines should be traced
    int x = int(map(i, 0,niceData.length+0.8,    // TODO generic
                       0,width));
    // shift to allign with stripe
    x += 0.75 * width / niceData.length;         // TODO generic

    // Convert the histogram value to a location between
    // the bottom and the top of the picture
    int y = int(map(niceData[i],
                    0, colorRef,
                    height, 0));
    //y *= globalMax/XXX; // TODO adapt!

    stroke(0);
    strokeWeight(5);
    line(x,height, x,y);
  }
}

/////////////////////////////////////////////////////////////////
int drawRetrievedFinger(int[] niceData) {
  // This function aims to retrieve finger position

  float retrievedPos = -1;

  // Find max index
  int maxArray = max(niceData);
  int maxIndex = 0;
  for (int i = 0; i < niceData.length; i++) {
    if (maxArray == niceData[i]) {
      maxIndex = i;
      break;
    }
  }

  // Retrieval method from Microchip TB3064 white paper (p12):
  // microchip.com/stellent/groups/techpub_sg/documents/devicedoc/en550192.pdf
  // Position is calculated as the centroid of 2 adjacent values:

  int prev = (maxIndex==0)?
             0 : niceData[maxIndex-1];

  int next = (maxIndex>=niceData.length-1)?
             0 : niceData[maxIndex+1];

  retrievedPos = maxIndex + 0.5 * (next - prev) / niceData[maxIndex];

  // Offset TODO?
  retrievedPos += 0.5;
  retrievedPos *= width / stripNumber;

  // Draw finger at estimated position
  color c = color(0, 0, 0, 2*colorRef/3);
  drawFinger(int(retrievedPos), fingerWidth*4/5, c);

  return int(retrievedPos);
}

/////////////////////////////////////////////////////////////////
int drawCubicRetrievedFinger(int[] niceData) {
  // This function aims to retrieve finger position

  int interFactor = interStep*2; // improves error smoothness
  float retrievedPos = -1;
  float[] y = new float[stripNumber*interFactor];

  float scaling = float(width) / y.length;
  strokeWeight(3);

  // interpolate
  for (int s = 0; s < stripNumber; s++) { // sensor strips
    // avoid overflows
    int s0 = (s-1 < 0)? -1 : s-1;
    int s1 = s;
    int s2 = (s+1 >= stripNumber)? s : s+1;
    int s3 = (s+2 >= stripNumber)? s : s+2;

    for (int i = 0; i < interFactor; i++) { // interpolation steps
      y[i+s*interFactor] = CubicInterpolate(s0<0? 0 : niceData[s0],
                                            niceData[s1],
                                            niceData[s2],
                                            niceData[s3],
                                            float(i)/interFactor);
    }
  }

  // Find max index
  float maxArray = max(y);

  for (int i = 0; i < y.length; i++) {
    if (maxArray == y[i]) {
      retrievedPos = i;
      break;
    }
  }

  retrievedPos *= scaling; // normalize to display
  retrievedPos += zzUnitWidth/2;

  // Draw finger at estimated position
  color c = color(0, 0, 0, 2*colorRef/3);
  drawFinger(int(retrievedPos), fingerWidth*4/5, c);

  return int(retrievedPos);
}

/////////////////////////////////////////////////////////////////
float CubicInterpolate(float y0, float y1,
                       float y2, float y3, float mu) {
  /* @article{bourke1999interpolation,
         title={Interpolation methods},
         author={Bourke, Paul},
         journal={paulbourke.net/miscellaneous/interpolation},
         year={1999} } */

  float a0, a1, a2, a3, mu2;
  mu2 = mu*mu;

  // Breeuwsma approach:
  a0 = -0.5*y0 + 1.5*y1 - 1.5*y2 + 0.5*y3;
  a1 = y0 - 2.5*y1 + 2*y2 - 0.5*y3;
  a2 = -0.5*y0 + 0.5*y2;
  a3 = y1;

  return (a0*mu*mu2 + a1*mu2 + a2*mu + a3);
}

/////////////////////////////////////////////////////////////////
float LinearInterpolate(float y1, float y2, float mu) {
  return(y1*(1-mu)+y2*mu);
}

/////////////////////////////////////////////////////////////////
void drawFinger(int position, int size, color c) {
  // This functions assumes that the pressure applied by a finger
  // is similar to a disc
  noStroke();
  fill(c);
  ellipse(position, height/2, size, size);
}

/////////////////////////////////////////////////////////////////
void drawBackground() {
  // This function draws the strips, here they have a zigzag
  // shape but a picture could be loaded with random shapes

  // starting point
  int startPosX =  Math.round((zzStrokeWidth + zzSpacingRatio) / 2);
  int startPosY = -zzStrokeWidth / 2;

  // end point of the line
  int endPosX = startPosX;
  int endPosY = height-startPosY;

  background(colorRef);
  strokeJoin(MITER);

  for (int i = 0; i<stripNumber; i++) {
    strokeWeight(zzStrokeWidth);

    // Hue, Saturation, Brightness
    int hue = i*(colorRef/stripNumber) % colorRef;
    stroke(color(hue, colorRef, colorRef));

    drawZigZag(zzSpikeCount, zzStrokeWidth,
               startPosX + zzUnitWidth * i, startPosY,
               endPosX   + zzUnitWidth * i,   endPosY);
  }
}

/////////////////////////////////////////////////////////////////
void drawZigZag(int segments, float radius, float aX, float aY, float bX, float bY) {

  if (segments <= 1) {
    beginShape();
    vertex(aX, aY);
    vertex(bX, bY);
    endShape();
    return;
  }

  // Calculate vector from start to end point
  float distX = bX - aX;
  float distY = bY - aY;

  // Calculate length of the above mentioned vector
  float segmentLength = sqrt(distX * distX + distY * distY) / segments;

  // Calculate segment vector
  float segmentX = distX / segments;
  float segmentY = distY / segments;

  // Calculate normal of the segment vector and multiply it with the given radius
  float normalX = -segmentY / segmentLength * radius;
  float normalY = segmentX / segmentLength * radius;

  // Calculate start position of the zig-zag line
  float StartX = aX + normalX;
  float StartY = aY + normalY;

  beginShape();
  vertex(StartX, StartY);

  // Render the zig-zag line
  for (int n = 1; n < segments; n++) {
    float newX = aX + n * segmentX + ((n & 1) == 0 ? normalX : -normalX);
    float newY = aY + n * segmentY + ((n & 1) == 0 ? normalY : -normalY);
    vertex(newX, newY);
  }

  // Render last line
  vertex(bX + ((segments & 1) == 0 ? normalX : -normalX),
         bY + ((segments & 1) == 0 ? normalY : -normalY));

  // roll back to close the shape
  for (int n = segments-1; n >= 1; n--) {
    float newX = aX + n * segmentX + ((n & 1) == 0 ? normalX : -normalX);
    float newY = aY + n * segmentY + ((n & 1) == 0 ? normalY : -normalY);
    vertex(newX, newY);
  }

  endShape();
}
