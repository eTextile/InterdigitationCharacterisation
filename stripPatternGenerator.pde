int count = 6;   // zig-zag count (how many segments on the X axis)
int size = 35;    // zig-zag height
int STROKE = 45;
float factor = 2.2; // zig-zag vertical spacing factor between strips

int fingerSize = size * 5;
int fingerOffset = 0;
int speed = 8;

int colorRef = 70;
int globalMax = 11561; // XXX TODO FIXME

void setup() {
  colorMode(HSB, colorRef);
  size(330, 600);
}

void draw() {
  // starting point
  int startPosX = -size;
  int startPosY = size*2;

  // end point of the line
  int endPosX = width+size;
  int endPosY = size*2; // height

  background(colorRef);
  strokeJoin(MITER);

  for (int i = 0; i<height/size - 1; i++) {
    strokeWeight(STROKE);
    stroke(i*(colorRef/7) % colorRef, // Hue
           colorRef,                  // Saturation
           colorRef,                  // Brightness
           colorRef-1);               // alpha = to mark common colors
    drawZigZag(count,     size,
               startPosX, startPosY + size * i * factor,
               endPosX,   endPosY   + size * i * factor);
  }

  // draw finger:
  strokeWeight(0);
  fill(0, 0, colorRef, 2*colorRef/3);
  ellipse(width/2, -fingerSize/2+fingerOffset, fingerSize, fingerSize);

  if (fingerOffset < height+fingerSize)
    fingerOffset += speed;
//  else
//    noLoop();

  histogram();

//  saveFrame("gif/line-##.png");
}

void histogram() {
  int[] hist = new int[colorRef];
  // Calculate the histogram
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      int hue = int(hue(get(i, j)));

      // XXX TODO FIXME !!!
      if ( get(i, j) != color(0)        ||         // remove white
           get(i, j) != color(colorRef) ||         // remove black
           int(alpha(get(i, j))) != colorRef-1 ) { // remove common colors marked above
        hist[hue]++;
      }
    }
  }

 // XXX TODO FIXME
 int noise[] = {0, 9, 20, 29, 40, 49, 60};
  for (int i = 0; i < noise.length; i++)
    hist[noise[i]] = 0;

  // Find the largest value in the histogram
  int histMax = max(hist);
  globalMax = max(histMax, globalMax);
  //println(globalMax);

  // Draw the histogram
  for (int i = 0; i < width; i ++) {
    // Map i (from 0..width) to a location in the histogram (0..colorRef)
    int which = int(map(i, 0, width, 0, colorRef));
    //println(which, hist[which]);

    // Convert the histogram value to a location between
    // the bottom and the top of the picture
    int y = int(map(hist[which],
                    0, globalMax,
                    height, 0));
    stroke(0);
    strokeWeight(5);
    line(i, height, i, y);
  }
}

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
  endShape();
}

