int count = 6;   // zig-zag count (how many segments on the X axis)
int size = 35;    // zig-zag height
int STROKE = 45;
float factor = 2.2; // zig-zag vertical spacing factor between strips

int fingerSize = size * 5;
int fingerOffset = 0;

int colorRef = 70;

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
  for (int i = 0; i<height/size - 1; i++) {
    stroke(i*10, colorRef, colorRef);
    drawZigZag(count,     size,
               startPosX, startPosY + size * i * factor,
               endPosX,   endPosY   + size * i * factor);
  }

  // draw finger:
  strokeWeight(0);
  fill(0, 0, colorRef, colorRef/2);
  ellipse(width/2, -fingerSize/2+fingerOffset, fingerSize, fingerSize);

  fingerOffset = (fingerOffset < height+fingerSize)? fingerOffset+5 : 0;
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
  float oldX = aX + normalX;
  float oldY = aY + normalY;

  // Render the zig-zag line
  for (int n = 1; n < segments; n++) {
    float newX = aX + n * segmentX + ((n & 1) == 0 ? normalX : -normalX);
    float newY = aY + n * segmentY + ((n & 1) == 0 ? normalY : -normalY);
    strokeJoin(ROUND);
    strokeWeight(STROKE);
    stroke(255);
    line(oldX, oldY, newX, newY);
    oldX = newX;
    oldY = newY;
  }

  // Render last line
  line(oldX, oldY, bX + ((segments & 1) == 0 ? normalX : -normalX), bY + ((segments & 1) == 0 ? normalY : -normalY));
}