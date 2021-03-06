
/*
  *TODO: 
  *  Fix the issue with data not normalizing
  *  Give distance from beacon a functional weight based on distance     
  *  kalman filter previousestimation dependent on time passed since measurment taken
  *    - like for example measure delta time at each measurement taken so that you can change the probabilities    
*/

class Bot
{
  //bot attributes
  float x, y;
  float heading;
  float scalar;
  float botWidth;
  float botHeight;
  float wigRoom;
  float easing;
  float targetX, targetY;
  float dx, dy;
  
  //beacons awareness
  int near1Idx;
  int near2Idx;
  int near3Idx;
  float[][][] intersect;//ab = 0, bc = 1, ac = 2;
  
  //estimated points
  Particle[] p;
  Intersects[] secs;
  int numP;
  int pNumDelta;//number of particles per step
  int pIndx;
  
  //estimated bots
  EstBot Kbot;
  EstBot Pbot;
  float kfX, kfY;
  float pfX, pfY;
   //for kalman
  float x1=0.0;
  float y1=0.0;
  float x2=0.0;
  float y2=0.0;
  
  float px1=0.0;
  float py1=0.0;
  float px2=0.0;
  float py2=0.0;
  
  float kx=0.0;
  float ky=0.0;
  
  Bot(float xpos, float ypos, float headinginit, float scale, float _botWidth, float _botHeight, int _numP, int _pNumDelta)
  {
    x = xpos;
    y = ypos;
    heading = headinginit;
    scalar = scale/100.0;
    botWidth = _botWidth;
    botHeight = _botHeight;
    near1Idx = -1;
    near2Idx = -1;
    near3Idx = -1;
    easing = 0.05;
    numP = _numP;
    p = new Particle[numP];
    for(int i =0; i < p.length; i++)
    { 
      p[i] = new Particle(); 
    }
    pNumDelta = _pNumDelta;
    pIndx = 0;
    intersect = new float[3][2][2];
    wigRoom = 30;
    for(int i = 0; i < intersect.length; i++)
    {
      for(int j = 0; j < intersect[0].length; j++)
      {
        for(int k = 0; j < intersect[0][0].length; j++)
        {
          intersect[i][j][k] = 0;
        }
      }
    }
   
    secs = new Intersects[6];
    for(int i= 0; i < secs.length; i++)
    {
      secs[i] = new Intersects();
    }
    Kbot = new EstBot("Kalman", x, y, botWidth, botHeight, heading);
    Pbot = new EstBot("Particle", x, y, botWidth, botHeight, heading);
    
  }
  void move()
  { //<>//
    if(mousePressed) //<>//
    {
      targetX = mouseX;
      targetY = mouseY;
    }
    dx = targetX - x;
    dy = targetY - y; //<>//
    x += dx*easing; //<>//
    y += dy*easing;
  }
  void display()
  {
    
    fill(0,255,222);
    strokeWeight(3);
    stroke(155, 153);
    //rotate(heading);
    rect(x, y, botWidth, botHeight); 
    
    
  }
  void kNearestBeacon(Beacon be[])
  { //<>//
    near1Idx = -1; //<>// //<>// //<>//
    near2Idx = -1;
    near3Idx = -1;
    for (int i = 0; i < be.length; i++)
    {
      be[i].updateDistance(x, y);
      be[i].display(); //<>//
      // check which are the two nearest neighbor //<>// //<>// //<>//
      //check if beacon can get distances
      if (be[i].detected)
      {
        if((near1Idx > -1) && (near2Idx > -1) && (near3Idx > -1))/// the first one is always going to be the smallest distance
        {
          if (be[i].noiseDis < be[near1Idx].noiseDis)
          {
            near3Idx = near2Idx;
            near2Idx = near1Idx;
            near1Idx = i;
          }
          else if (be[i].noiseDis < be[near2Idx].noiseDis)
          {
            near3Idx = near2Idx;
            near2Idx = i;
          }
          else if (be[i].noiseDis < be[near3Idx].noiseDis)
          {
            near3Idx = i;
          }
        }
        else if((near1Idx > -1) && (near2Idx > -1) && (near3Idx == -1)) // might not need to test the first idx
        {
          if(be[i].noiseDis < be[near1Idx].noiseDis)
          {
            near3Idx = near2Idx;
            near2Idx = near1Idx;
            near1Idx = i;
          }
          else if(be[i].noiseDis < be[near2Idx].noiseDis)
          {
            near3Idx = near2Idx;
            near2Idx = i;
          }
          else
          {
            near3Idx = i;
          }
        }
        else if((near1Idx > -1) && (near2Idx == -1) && (near3Idx == -1))
        {
          if(be[i].noiseDis < be[near1Idx].noiseDis)
          {
            near2Idx = near1Idx;
            near1Idx = i;
          }
          else
          {
            near2Idx = i;
          }
        }
        else if(near1Idx == -1)
        {
          near1Idx = i;
        }
    }
  }
  if ((near1Idx > -1) && (near2Idx > -1) && (near3Idx > -1))
  {
    be[near1Idx].near = true;
    be[near2Idx].near = true;
    be[near3Idx].near = true;
    be[near1Idx].display();
    be[near2Idx].display();
    be[near3Idx].display();
  }
  else if((near1Idx > -1) && (near2Idx > -1))
  {
    be[near1Idx].near = true;
    be[near2Idx].near = true;
    be[near1Idx].display();
    be[near2Idx].display();
  }
  
  }
  /*
   * getParticles uses the beacons that are closest
   * triagulates and displays the particles on the window
   */
  void getParticles(Beacon beacon[])
  { 
    //while?
    if((near1Idx > -1) && (near2Idx > -1)) //<>//
    {
      int i = pIndx;
      while((i < (pIndx + pNumDelta)) && (i < p.length))
      {
        if (near3Idx > -1)
        {
          triangulate(beacon[near1Idx], beacon[near2Idx], beacon[near3Idx], i);
        }
        else
        {
          triangulate(beacon[near1Idx], beacon[near2Idx], i);
        }
        i++;
      }
      pIndx = i;
      if (pIndx == p.length)
      {
        pIndx = 0; 
        getPFpos();   //<>//
        getKFpos(); //<>//
        //might set show for all particles to false
      }
      //display used to be here //<>// //<>//
    }
    
  }
  /*
   * Triangulate method used when utilizing 
   * 3 beacons. 
   */
  void triangulate(Beacon beA, Beacon beB, Beacon beC, int pIdx)
  {
    beA.updateNoiseDistance();
    beB.updateNoiseDistance();
    beC.updateNoiseDistance();
    if(isIntersect(beA.myX, beA.myY, beB.myX, beB.myY, (beA.noiseDis+wigRoom), (beB.noiseDis+wigRoom)))
    {
      CircleIntersects(beA.myX, beA.myY, beB.myX, beB.myY, (beA.noiseDis+wigRoom), (beB.noiseDis+wigRoom), 1);
      if(isIntersect(beB.myX, beB.myY, beC.myX, beC.myY, (beB.noiseDis+wigRoom), (beC.noiseDis+wigRoom)))
      {
        CircleIntersects(beB.myX, beB.myY, beC.myX, beC.myY, (beB.noiseDis+wigRoom), (beC.noiseDis+wigRoom), 2);
        if(isIntersect(beA.myX, beA.myY, beC.myX, beC.myY, (beC.noiseDis+wigRoom), (beC.noiseDis+wigRoom)))
        {
           CircleIntersects(beA.myX, beA.myY, beC.myX, beC.myY, (beC.noiseDis+wigRoom), (beC.noiseDis+wigRoom), 3);
           //ab = 0, bc = 1, ac = 2;
           float a_BC1 = dist(beA.myX ,beA.myY,intersect[1][0][0], intersect[1][0][1]);//pr1
           float a_BC2 = dist(beA.myX ,beA.myY,intersect[1][1][0], intersect[1][1][1]);//pr2
           if(a_BC1 <= a_BC2)
           {
             secs[0].x = intersect[1][0][0];//0
             secs[0].y = intersect[1][0][1];
             secs[5].x = intersect[1][1][0];
             secs[5].y = intersect[1][1][1];
           }
           else
           {
             secs[0].x = intersect[1][1][0];
             secs[0].y = intersect[1][1][1];
             secs[5].x = intersect[1][0][0];
             secs[5].y = intersect[1][0][1];
           }
           secs[0].inner = true;
           
           float b_AC1= dist(beB.myX ,beB.myY,intersect[2][0][0], intersect[2][0][1]);
           float b_AC2= dist(beB.myX ,beB.myY,intersect[2][1][0], intersect[2][1][1]);
           if(b_AC1 <= b_AC2)
           {
             secs[1].x = intersect[2][0][0];
             secs[1].y = intersect[2][0][1];
             secs[4].x = intersect[2][1][0];
             secs[4].y = intersect[2][1][1];
           }
           else
           {
             secs[1].x = intersect[2][1][0];
             secs[1].y = intersect[2][1][1];
             secs[4].x = intersect[2][0][0];
             secs[4].y = intersect[2][0][1];
           }
           secs[1].inner = true;
           
           float c_AB1= dist(beC.myX ,beC.myY,intersect[0][0][0], intersect[0][0][1]);
           float c_AB2= dist(beC.myX ,beC.myY,intersect[0][1][0], intersect[0][1][1]);
           if(c_AB1 <= c_AB2)
           {
             secs[2].x = intersect[0][0][0];
             secs[2].y = intersect[0][0][1];
             secs[3].x = intersect[0][1][0];
             secs[3].y = intersect[0][1][1];
           }
           else
           {
             secs[2].x = intersect[0][1][0];
             secs[2].y = intersect[0][1][1];
             secs[3].x = intersect[0][0][0];
             secs[3].y = intersect[0][0][1];
           }
           secs[2].inner = true;
           
           
           float avgX = (secs[0].x + secs[1].x + secs[2].x)/3;// this can improve
           float avgY = (secs[0].y + secs[1].y + secs[2].y)/3;
           p[pIdx].x = avgX;
           p[pIdx].y = avgY;
           p[pIdx].show = true;
           
           for(int i = 0; i < secs.length; i++)
           {
             secs[i].show = true;
           }  
        }
      }
    }
  }
  /*
   * Triangulates when two beacons are used
   * it also sets the partcle to show on the window
   */
  void triangulate(Beacon beA, Beacon beB, int pIdx)
  {
    beA.updateNoiseDistance();
    beB.updateNoiseDistance();
    if(isIntersect(beA.myX, beA.myY, beB.myX, beB.myY, (beA.noiseDis+wigRoom), (beB.noiseDis+wigRoom)))
    {
      CircleIntersects(beA.myX, beA.myY, beB.myX, beB.myY, (beA.noiseDis+wigRoom), (beB.noiseDis+wigRoom),1);
      //float a_BC1 = dist(beA.myX ,beA.myY,intersect[1][0][0], intersect[1][0][1]);//pr1// will use this as a ratio to determine x and y
      //float a_BC2 = dist(beA.myX ,beA.myY,intersect[1][1][0], intersect[1][1][1]);//pr2
      
      float avgX = ((intersect[0][0][0] + intersect[0][1][0])/2);
      float avgY = ((intersect[0][0][1] + intersect[0][1][1])/2);
      p[pIdx].x = avgX;
      p[pIdx].y = avgY;
      p[pIdx].show = true;
      secs[0].x = intersect[0][0][0];
      secs[1].x = intersect[0][1][0];
      secs[0].y = intersect[0][0][1];
      secs[1].y = intersect[0][1][1];
      secs[0].show = true;
      secs[1].show = true;
      secs[0].inner = true;
      secs[1].inner = true;
      for(int i = 2; i < secs.length; i++)
      {
        secs[i].show = false;
      }
    }
  }
  /**
 * Finds the intersections of two beacons, if they exist.
 *
 * Given two circle equations:
 *   Cirlce 1: r1^2 = (x - x1)^2 + (y - y1)^2
 *   Circle 2: r2^2 = (x - x2)^2 + (y - y2)^2
 *
 * Returns coordinates (2 sets of 2 floats) or else returns null if intersections do not exist.
 *
 * Rarely this function may return null if the circles are tangental or very close to tangental.
 */
  void CircleIntersects(float x1, float y1, float x2, float y2, float r1, float r2, int num)
  {
    // Use change of coordinates to get:
    //   Cirlce 1: r1^2 = x^2 + y^2
    //   Circle 2: r2^2 = (x - a)^2 + (y - b)^2
    float a = x2 - x1;
    float b = y2 - y1;
     
    // Find distance between circles.
    float ds = a*a + b*b;
    float d = sqrt( ds );
     
    // Find the intersections (formula derivations not shown here).
    float t = sqrt( (d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (-d + r1 + r2) );
    float ratio;
    float sx1;
    float sx2;
    float sy1;
    float sy2;
    if (r1 > r2)
    {
      ratio = 0.5;//(r2/r1*1)/2; 
      sx1 = (ratio) * (a + (a*(r1*r1 - r2*r2) + b*t)/ds);//0.5 instead of ratio
      sx2 =  (ratio) * (a + (a*(r1*r1 - r2*r2) - b*t)/ds);
     
      sy1 = ratio * (b + (b*(r1*r1 - r2*r2) - a*t)/ds);
      sy2 = ratio * (b + (b*(r1*r1 - r2*r2) + a*t)/ds);
      
    }
    else
    {
      ratio = 0.5;//(r1/r2*1)/2;
      sx1 = (ratio) * (a + (a*(r1*r1 - r2*r2) + b*t)/ds);//0.5 instead of ratio
      sx2 = ratio * (a + (a*(r1*r1 - r2*r2) - b*t)/ds);
     
      sy1 = (1-ratio) * (b + (b*(r1*r1 - r2*r2) - a*t)/ds);
      sy2 = ratio * (b + (b*(r1*r1 - r2*r2) + a*t)/ds);
    }
    
     
    // Translate to get the intersections in the original reference frame.
    sx1 += x1;
    sy1 += y1;
     
    sx2 += x1;
    sy2 += y1;
     
    //float[][] r = new float[2][2];
    /*r[0][0] = sx1;
    r[0][1] = sy1;
    r[1][0] = sx2;
    r[1][1] = sy2;*/
    if(num == 1)//AB
    {
      intersect[0][0][0] = sx1;
      intersect[0][0][1] = sy1;
      intersect[0][1][0] = sx2;
      intersect[0][1][1] = sy2;
    }
    else if(num == 2)//BC
    {
      intersect[1][0][0] = sx1;
      intersect[1][0][1] = sy1;
      intersect[1][1][0] = sx2;
      intersect[1][1][1] = sy2;
    }
    else if(num == 3)//AC
    {
      intersect[2][0][0] = sx1;
      intersect[2][0][1] = sy1;
      intersect[2][1][0] = sx2;
      intersect[2][1][1] = sy2;
    }
  }
  /**
   * checks if the the two beacons intercept
   * Utilized before finding the intercepts
   * returns true if the beacons intercept
   */
  boolean isIntersect(float cx1, float cy1,  float cx2, float cy2, float cr1, float cr2) 
  {
    if (dist(cx1, cy1, cx2, cy2) < cr1 + cr2) 
    {
      return true;
    } 
    else 
    {
      return false;
    }
  }

  void getPFpos()
  {
    float beX[] = {-1.00, -1.00, -1.00}; 
    float beY[] = {-1.00, -1.00, -1.00}; 
    if((secs[2].inner == true) && (secs[1].inner == true) && (secs[0].inner == true))
    {
      beX[0] = secs[0].x;
      beX[1] = secs[1].x;
      beX[2] = secs[2].x;
      beY[0] = secs[0].y;
      beY[1] = secs[1].y;
      beY[2] = secs[2].y;
    }
    else if(secs[3].inner == true)
    {
      beX[0] = secs[0].x;
      beX[1] = secs[1].x;
      beY[0] = secs[0].y;
      beY[1] = secs[1].y;
    }
    float sigma = 1.0;
   
    pfX = parzensWindow(p, sigma, beX, true) - (Pbot.botWidth*0.5); 
    pfY = parzensWindow(p, sigma, beY, false) - (Pbot.botHeight*0.5); 
    if((!Float.isNaN(pfX)) && (!Float.isNaN(pfY)))
    {
      Pbot.move(pfX, pfY);
    }
    //Pbot.display();
   
  }
  float parzensWindow(Particle p[], float sigma, float beaconPos[], Boolean axis) // axis true=x, false=y
  {
    // chosing values for range and position of window
    float min = min(beaconPos);
    float max = max(beaconPos);
    if(beaconPos[2] < 0)
    {
      min = min(beaconPos[0], beaconPos[1]);
      max = max(beaconPos[0], beaconPos[1]);
    }
    
    
    int windowSize = p.length*2;
    float valRange = max-min;
    float windowStepSize = valRange/(windowSize-1);
    float[] particleWindow;
    particleWindow = new float[windowSize];
    float[] pdf;
    pdf = new float[windowSize];
    float expected;
    
    // fill in the values that make up the range convered in window
    particleWindow[0] = min;
    for(int i=1; i < windowSize; i++)
    {
      particleWindow[i] = particleWindow[i-1]+windowStepSize; //i*windowStepSize + min; //
    }
    /*
    if(particleWindow[windowSize-1] < (max))
    {
      print("fix the particle window values    max: ");
      print(max);
      print("    window: ");
      println(particleWindow[windowSize-1]);
      
    }
    else if(particleWindow[1] > (min))
    {
      print("fix the particle window values    min: ");
      print(min);
      print("    window: ");
      println(particleWindow[1]);
    }*/
    
    //Creating the density function
    if(axis)
    {
      for(int i = 0; i < windowSize; i++)
      {
        float px = 0.00;
        for(int j=0; j < p.length; j++)
        {
          float w = p[j].x;
          float x = particleWindow[i];
          float dif = w-x;
          float egain = exp(-(dif*dif)/(2*(sigma * sigma)));
          float u = egain/(sqrt(2*PI)*sigma);
          px += u;
        }
        px = px/p.length;
        pdf[i] = px;
       }
    }
    else
    {
      for(int i = 0; i < windowSize; i++)
      {
        float py = 0.00;
        for(int j=0; j < p.length; j++)
        {
          float w = p[j].y;
          float y = particleWindow[i];
          float dif = w-y;
          float egain = exp(-(dif*dif)/(2*(sigma * sigma)));
          float u = egain/(sqrt(2*PI)*sigma);
          py += u;
        }
        py = py/p.length;
        pdf[i] = py;
       }
    }
     
     // normalizing parzens density function(distribution)
     float prePdfSum = 0.00;
     for(int i=0; i < windowSize; i++)
     {
        prePdfSum += pdf[i]; 
     }
     for(int i=0; i < windowSize; i++)
     {
        pdf[i] = pdf[i]/prePdfSum; 
     }
     float afterSum = 0.00;
     for(int i=0; i < windowSize; i++)
     {
        afterSum += pdf[i]; 
     }
     if(afterSum <= 1.10 && afterSum >= 0.99)
     {
       print("density funtion normalized: ");
       println(afterSum);
     }
     else
     {
       print("not normalized  :");
       println(afterSum);
     }
     // gathering expected value
     expected= 0.00;
     for(int i=0; i < windowSize; i++)
     {
        expected += particleWindow[i] *pdf[i]; 
     }
     
     return expected;
    
  }
  
  void getKFpos()
  {
    /*//println("needs to be implemented");
    kfX = x + random(-20, 20);
    kfY = y + random(-20, 20);
    Kbot.move(kfX, kfY);
    //Kbot.display();*/
    float tempx = 0.00;
    float tempy = 0.00;
    for(int i=0; i < p.length; i++)
    {
      tempx += p[i].x;
      tempy += p[i].y;
    }
    tempx = tempx/p.length;
    tempy = tempy/p.length; //<>//
    //tempx = p[0].x;
    //tempy = p[0].y;
    
    
    
    if((!Float.isNaN(tempx)) && (!Float.isNaN(tempy))) // still goes to nan
    {
      /*if(Float.isNaN(px1) || Float.isNaN(py1) || Float.isNaN(px2) || Float.isNaN(py2) || Float.isNaN(x1) || Float.isNaN(x2) || Float.isNaN(y1) || Float.isNaN(y2) || Float.isNaN(kx) || Float.isNaN(ky))
      {
        x1=0.0;
        y1=0.0;
        x2=0.0;
        y2=0.0;
        px1=0.0;
        py1=0.0;
        px2=0.0;
        py2=0.0;
        kx=0.0;
        ky=0.0;
        
      }*/
      x1=x2;
      px1=px2+1.0;
      kx=px1/(2.0+px1);
      x2=x1+kx*(tempx-x1);
      px2=(1-kx)*px1;
      
      //y
      y1=y2;
      py1=py2+1.0;
      ky=py1/(2.0+py1);
      y2=y1+ky*(tempy-1*y1);
      py2=(1-ky)*py1;
      
      kfX= x2 - (Kbot.botWidth*0.5); 
      kfY= y2 - (Pbot.botHeight*0.5);
      Kbot.move(kfX, kfY);
    }
    
    
    
  }
}

 
  
 




    