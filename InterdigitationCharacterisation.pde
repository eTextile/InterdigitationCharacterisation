// This program draws virtual pressure sensing strips with interdigitated
// shapes (zigzags for now), and a virtual finger that swipes it.
// To identify each strip, it uses different colors, and to simulate the
// effect of a finger on it, we just count how many pixels it hides.

int zzSpikeCount = 5;          // zig-zag count
int zzTotalWidth = 35;         // zig-zag width
int zzStrokeWidth = 45;        // zig-zag stroke width
float zzSpacingFactor = 2.2;   // zig-zag spacing factor between strips

int fingerSize = 5 * zzTotalWidth;

// The following global variables should not need to be modified

int stripNumber = 7;
int colorRef = stripNumber * 10;

int globalMax = 0;

int[] pressureIndices = new int[stripNumber];
boolean isCharacterizing = true;
int fingerPos = fingerSize/2;
int retrievedPos = 0;
int[] errors;

/////////////////////////////////////////////////////////////////
void setup() {
  colorMode(HSB, colorRef);
  size(600, 330);
  errors = new int[width];

  // run the histogram once to initialize globalMax
  drawBackground();
  strokeWeight(0);
  fill(0, 0, colorRef, 2*colorRef/3);   // finger color
  rect(0, 0, width, fingerSize);        // simulate a wide finger
  histogram();
}

/////////////////////////////////////////////////////////////////
void draw() {
  // draw strips
  drawBackground();

  // draw finger:
  color white = color(0, 0, colorRef);
  drawFinger(fingerPos, fingerSize, white);

  // analyse finger impact on sensor stripes and simulate raw sensor
  int[] niceData = histogram();

  // visualize the estimated finger position using raw sensor data
  retrievedPos = drawRetrievedFinger(niceData);

  if (!isCharacterizing) {
    fingerPos = mouseX;
  } else {
    characterization(fingerPos);
    fingerPos+=1; // TODO: handle faster steps
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
  if (fingerPos >= width - fingerSize/2) {
    // Plot characterization
    drawBackground();

    stroke(0);
    strokeWeight(6);
    for (int i = 1; i < width; i++) {
      line(i-1, height - errors[i-1],
           i,   height - errors[i]);
    }

    // draw finger in the middle as reference:
    color c = color(0, 0, colorRef, colorRef);
    drawFinger(width/2, fingerSize, c);

    String fileName = "characterization_count" + zzSpikeCount +"_width_" + zzTotalWidth + ".png";
    saveFrame(fileName); // TODO: write parameters value in file

    fill(colorRef);
    rect(0,0, width, 80);

    fill(0);
    textSize(21);
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
  drawFinger(int(retrievedPos), fingerSize*4/5, c);

  return int(retrievedPos);
}

/////////////////////////////////////////////////////////////////
void drawFinger(int position, int size, color c) {
  // This functions assumes that the pressure applied by a finger
  // is similar to a disc
  strokeWeight(0);
  fill(c);
  ellipse(position, height/2, size, size);
}

/////////////////////////////////////////////////////////////////
void drawBackground() {
  // This function draws the strips, here they have a zigzag
  // shape but a picture could be loaded with random shapes

  // starting point
  int startPosX = zzTotalWidth*2;
  int startPosY = -zzTotalWidth;

  // end point of the line
  int endPosX = zzTotalWidth*2;
  int endPosY = height+zzTotalWidth;

  background(colorRef);
  strokeJoin(MITER);

  for (int i = 0; i<stripNumber; i++) {
    strokeWeight(zzStrokeWidth);

    // Hue, Saturation, Brightness
    int hue = i*(colorRef/stripNumber) % colorRef;
    stroke(color(hue, colorRef, colorRef));

    drawZigZag(zzSpikeCount, zzTotalWidth,
               startPosX + zzTotalWidth * i * zzSpacingFactor, startPosY,
               endPosX   + zzTotalWidth * i * zzSpacingFactor,   endPosY);
  }
}

/////////////////////////////////////////////////////////////////
void drawZigZag(int segments, float radius, float aX, float aY, float bX, float bY) {

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
