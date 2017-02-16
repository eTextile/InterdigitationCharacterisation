import processing.pdf.*;

// zig-zag count, height and vertical spacing factor between strips
int count = 40;
int size = 20;
float factor = 3;


void setup() {
  size(600, 600);
  background(255);

  noLoop();
  beginRecord(PDF, "export.pdf");
}

void draw() {
  // starting point
  int startPosX = 0;
  int startPosY = size;

  // end point of the line
  int endPosX = width;
  int endPosY = size; // height

  for (int i = 0; i<height/size - 1; i++) {
    drawZigZag(count, size,
      startPosX, startPosY + size * i * factor,
      endPosX, endPosY   + size * i * factor);
  }

  endRecord(); // PDF generation
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
    line(oldX, oldY, newX, newY);
    oldX = newX;
    oldY = newY;
  }

  // Render last line
  line(oldX, oldY, bX + ((segments & 1) == 0 ? normalX : -normalX), bY + ((segments & 1) == 0 ? normalY : -normalY));
}
