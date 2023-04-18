PImage clef;
PImage mnote;
PImage diesis;

class Staff { 
  
  int dist, linlen; 
  float[] notesgroup = {0, 0.5, 1, 1.5, 2, 3, 3.5, 4, 4.5, 5, 5.5, 6, 7, 7.5, 8, 8.5, 9, 10, 10.5, 11, 11.5, 12, 12.5, 13};

   
  Staff (int d, int l) {  
    dist = d; 
    linlen = l;
  } 
  
  
  void drawstaff() { 
    
    clef = loadImage("clef1.png");
    image(clef, 0, dist-70, width/15, height/3.4);
    
    strokeWeight(3);
    for (int i = 0; i < 5; i = i+1) {
      line(0, (dist * i), 0 + linlen, (dist * i));
    }
    
  } 
  
  
  void makenote(int anote, int between) {
    
    if (anote >= 0) {
           
      int ypos = (dist/2)*10 - (dist/2)*floor(notesgroup[anote%24]) - dist/2;
      mnote = loadImage("whole.png");      
      image(mnote, linlen/2 + between, ypos, width/20, height/20);
      
      if (floor(notesgroup[anote%24]) != notesgroup[anote%24]) { 
        
        diesis = loadImage("d.png");
        image(diesis, linlen/2 - 60 + between, ypos - 20, width/25, height/10);
    }      
   }
  }
} 
