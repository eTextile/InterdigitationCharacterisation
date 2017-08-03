// This program draws virtual pressure sensing strips with interdigitated
// shapes (zigzags for now), and a virtual finger that swipes it.
// To identify each strip, it uses different colors, and to simulate the
// effect of a finger on it, an alpha value is used.
import blobDetection.*;

int zzSpikeCount = 5;          // zig-zag count
int zzTotalWidth = 35;         // zig-zag width
int zzStrokeWidth = 45;        // zig-zag stroke width
float zzSpacingFactor = 2.2;   // zig-zag spacing factor between strips

int fingerSize = 5 * zzTotalWidth;
float blobThreshold = 0.6;

// The following global variables should not need to be modified

int stripNumber = 7;
int colorRef = stripNumber * 10;

int globalMax = 0;
color[] baseColors = new color[colorRef];

int[] pressureIndices = new int[stripNumber];
boolean isCharacterizing = true;
int fingerPos = 0;
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
  histograms();
}

/////////////////////////////////////////////////////////////////
void draw() {
  // draw strips
  drawBackground();

  // draw transparent finger:
  color c = color(0, 0, colorRef, 2*colorRef/3);
  drawFinger(fingerPos, fingerSize, c);

  // analyse finger impact on sensor stripes and simulate raw sensor
  PImage data = histograms();

  // visualize the estimated finger position using raw sensor data
  retrievedPos = drawRetrievedFinger(data);

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
  if (fingerPos >= width) {
    // Plot characterization
    drawBackground();

    stroke(0);
    strokeWeight(6);
    for (int i = 1; i < width; i++) {
      line(i-1, height - errors[i-1],
           i,   height - errors[i]);
    }

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
PImage histograms() {
  // This function measures the effect of a finger on a strip.
  // It counts the pixels with a color that changed.

  int[] rawData = new int[colorRef];
  // Calculate the histogram
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      // Only focus on the "finger colors"
      if ( !isBaseColor( get(i, j) ) ) {
        int hue = int(hue(get(i, j)));
        rawData[hue]++;
      }
    }
  }

  // Create an array only for the simulated pressure sensor data
  PImage niceData = createImage(stripNumber, 1, ALPHA);

  // Extract from histogram, normalize, and interpolate
  preprocess(rawData, niceData);

  // Visualizations
  classicHistogram(rawData);       // simulated raw sensor data
  interpolatedHistogram(niceData); // increased resolution

  return niceData;
}

/////////////////////////////////////////////////////////////////
void preprocess(int[] rawData, PImage niceData) {
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

  // Extract pressure sensor data, normalize, and interpolate (using image functions):
  niceData.loadPixels();
  for (int i = 0; i < stripNumber; i++) {
    // populate the 1 dimensional image with normalized value
    int level = colorRef * rawData[pressureIndices[i]] / globalMax;
    niceData.pixels[i] = color(level);
  }
  niceData.updatePixels();

  niceData.resize(colorRef, 1); // interpolation
}

/////////////////////////////////////////////////////////////////
void classicHistogram(int[] rawData) {
  // Draw the histogram
  for (int i = 0; i < width; i++) {
    // Map i (from 0..width) to a location in the histogram (0..colorRef)
    int which = int(map(i, 0, width, 0, colorRef));

    // Convert the histogram value to a location between
    // the bottom and the top of the picture
    int y = int(map(rawData[which],
                    0, globalMax,
                    height, 0));
    stroke(0);
    strokeWeight(5);
    line(i, height, i, y);
  }

}

/////////////////////////////////////////////////////////////////
void interpolatedHistogram(PImage niceData) {
  niceData.loadPixels();
  // Draw the interpolated histogram
  for (int i = 0; i < width; i+=8) {
    // Map i (from 0..width) to a location in the histogram (0..colorRef)
    int which = int(map(i, 0, width, 0, niceData.pixels.length));

    // Convert the histogram value to a location between
    // the bottom and the top of the picture
    int y = int(map(brightness(niceData.pixels[which]), 0, colorRef, height, 0));
    stroke(0);
    strokeWeight(2);
    line(i, height, i, y);
  }
  niceData.updatePixels();
}

/////////////////////////////////////////////////////////////////
int drawRetrievedFinger(PImage niceData) {
  // This function aims to retrieve finger position

  int retrievedPos = -1;
  niceData.resize(colorRef, 3); // interpolation
  niceData.loadPixels();

  // The blob detection needs different lines around the real data
  for (int i = 0; i < niceData.width; i++) {
      niceData.pixels[i] = 0;                    // 1st line
      niceData.pixels[i + 2*niceData.width] = 0; // 3rd line
  }

  BlobDetection blobDetect;
  blobDetect = new BlobDetection(niceData.width, niceData.height);
  blobDetect.setThreshold(blobThreshold);
  blobDetect.setPosDiscrimination(false);
  blobDetect.computeBlobs(niceData.pixels);

  niceData.updatePixels();

  if (blobDetect.getBlobNb() > 0) {
    Blob b = blobDetect.getBlob(0); // there should only be one
    if (b != null) {
      // Draw finger at estimated position
      retrievedPos = int(b.x * width);
      color c = color(0, 0, 0, 2*colorRef/3);
      drawFinger(retrievedPos, fingerSize*4/5, c);
    }
  }

  return retrievedPos;
}

/////////////////////////////////////////////////////////////////
boolean isBaseColor(color c) {
  // This function looks for the most common colors, those that
  // we don't want to see in our histogram.

  // 1st, test white:
  if (c == color(0, 0, colorRef)) {
    return true;
  }

  // then test the strip colors:
  for (int i = 0; i < baseColors.length; i++)
    if (c == baseColors[i])
      return true;

  return false;
}

/////////////////////////////////////////////////////////////////
void drawFinger(int position, int size, color c) {
  // This functions assumes that the pressure applied by a finger
  // is similar to a disc, later it will use a different model
  // such as half a sphere, flattened or not.
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

    // Hue, Saturation, Brightness, Alpha
    baseColors[i] = color(i*(colorRef/stripNumber) % colorRef,
                          colorRef, colorRef, colorRef);

    stroke(baseColors[i]);
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