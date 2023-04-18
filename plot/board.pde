PImage gest;

class Gesture { 
  
  
  void plotGesture(int gestnum) { 
    
    println(gestnum);
    
    switch(gestnum) {
      case 0: 
        gest = loadImage("0.png");
        break;
      case 1: 
        gest = loadImage("1.png");
        break;
      case 2: 
        gest = loadImage("2.png");
        break;
      case 3: 
        gest = loadImage("3.png"); 
        break;
    }
    
    image(gest, 0, -250, width/8, height/6.5);
  }
}
