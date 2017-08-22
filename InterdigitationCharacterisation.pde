int[] Xs  =  {0, 100, 200, 300,  400, 500, 600, 700}; // positions
int[][] Y = {
    {10, 10, 100, 300, 400, 200, 100, 10},  // sensor amplitude easy to process
    {10, 10, 100, 200, 400, 400, 100, 10},  // probem
    {10, 10, 10,  10,  100, 200, 300, 400}, // probem
};

int select = 0;

int size = Xs.length;
float step = 150.0;

/////////////////////////////////////////////////////////////////
void setup() {
  size(700, 500);
}

/////////////////////////////////////////////////////////////////
void draw() {
  clear();
  int[] Ys = Y[select]; // select sensor data example
  int x, y;

  for (int s = 0; s < size-1; s++) {

    // avoid overflow
    int s0 = (s-1 < 0)? s : s-1;
    int s1 = s;
    int s2 = (s+1 >= size)? s : s+1;
    int s3 = (s+2 >= size)? s : s+2;

    for (int i = 0; i < step; i++) {
      // cubic interpolation
      y = int(CubicInterpolate(Ys[s0], Ys[s1], Ys[s2], Ys[s3], i/step));
      x = int(LinearInterpolate(Xs[s1], Xs[s2], i/step));
      stroke(0, 200, 255);
      ellipse(x, height-y, 1, 1);
    }
  }

  // draw a line where the linear interpolation guess is:
  int pos = getLinInterpoCentroid(Ys);
  stroke(0, 255, 0);                    // green for the 1st
  if (select != 0) stroke(255, 0, 0);   // red for the others
  line(pos,0 , pos,height);

  for (int s = 0; s < size-1; s++) {
    for (int i = 0; i < step; i+=8) {
      // linear interpolation
      y = int(LinearInterpolate(Ys[s], Ys[s+1], i/step));
      x = int(LinearInterpolate(Xs[s], Xs[s+1], i/step));
      stroke(255, 0, 0);
      ellipse(x, height-y, 3, 3);
    }
    // data points
    stroke(255, 255, 255);
    ellipse(Xs[s], height-Ys[s], 9, 9);
  }

  fill(255);
  textSize(18);
  int xPos = 20;
  int yPos = 0;
  int yOffset = 25;
  text("Press right/left to change data set", xPos, yPos += yOffset);
  text("* blue curve = cubic interpolation", xPos, yPos += yOffset);
  text("* yellow dots = linear interpolation", xPos, yPos += yOffset);
  text("* vertical bar = centroid estimation", xPos, yPos += yOffset);
  text("    from linear interpolation", xPos, yPos += yOffset*0.8);
  text("    (green = OK)", xPos, yPos += yOffset*0.8);
  text("    (red = not OK)", xPos, yPos += yOffset*0.8);
  noLoop();
}

/////////////////////////////////////////////////////////////////
void keyPressed() {
  // change sensor data simulation
  if (key == CODED) {
    saveFrame("interpolations_set" + select + ".png");

    if (keyCode == RIGHT && select < Y.length-1)
      ++select;

    if (keyCode == LEFT && select > 0)
      --select;

    loop(); // re-enable loop
  }
}

/////////////////////////////////////////////////////////////////
int getLinInterpoCentroid(int[] niceData) {
  // Get
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

  // Did we reach one of the extremities?
  int prev = (maxIndex == 0)?
             0 : niceData[maxIndex - 1];

  int next = (maxIndex >= niceData.length-1)?
             0 : niceData[maxIndex + 1];

  retrievedPos = 0.5 + maxIndex + 0.5 * (next - prev) / niceData[maxIndex];
  retrievedPos *= width / size;

  return int(retrievedPos);
}

/////////////////////////////////////////////////////////////////
float CubicInterpolate( float y0, float y1,
                        float y2, float y3,
                        float mu) {
  // source: paulbourke.net/miscellaneous/interpolation
  boolean breeuwsma = true; // smarter approach

  float a0, a1, a2, a3, mu2;
  mu2 = mu*mu;

  if (breeuwsma) {
    a0 = -0.5*y0 + 1.5*y1 - 1.5*y2 + 0.5*y3;
    a1 = y0 - 2.5*y1 + 2*y2 - 0.5*y3;
    a2 = -0.5*y0 + 0.5*y2;
    a3 = y1;
  } else {
    a0 = y3 - y2 - y0 + y1;
    a1 = y0 - y1 - a0;
    a2 = y2 - y0;
    a3 = y1;
  }

  return(a0*mu*mu2 + a1*mu2 + a2*mu + a3);
}

/////////////////////////////////////////////////////////////////
float LinearInterpolate(float y1, float y2, float mu) {
  return(y1*(1-mu)+y2*mu);
}
