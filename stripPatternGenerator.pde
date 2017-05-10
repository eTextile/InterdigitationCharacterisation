// 

import processing.pdf.*;

int count = 54;   // zig-zag count (how many segments on the X axis)
int size = 20;    // zig-zag height 
int STROKE = 3;
float factor = 2; // zig-zag vertical spacing factor between strips


void setup() {

  size(600, 600);
  noLoop();
  beginRecord(PDF, "export.pdf");
}

void draw() {
  background(0);

  // starting point
  int startPosX = 0;
  int startPosY = size;

  // end point of the line
  int endPosX = width;
  int endPosY = size; // height

  for (int i = 0; i<height/size - 1; i++) {
    drawZigZag(count, size, startPosX, startPosY + size * i * factor, endPosX, endPosY + size * i * factor);
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