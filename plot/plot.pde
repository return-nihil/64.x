import oscP5.*;
import netP5.*;


OscP5 oscP5;
NetAddress myRemoteLocation;


int x1 = 150;
int x2 = 750;
int y1 = 350;
int y2 = 350;
int dist = 40;
int linlen = 400;
int root = 36;



int[] notes1 = {-1,-1};
int[] notes2 = {-1,-1};
Staff s1 = new Staff(dist, linlen); 
Staff s2 = new Staff(dist, linlen); 
Gesture g1 = new Gesture();
Gesture g2 = new Gesture();
int movecount = 0;
int[][] notes_on_board = new int[8][8];
int[] scale = new int[16];
int[] gestures = new int[100];
String oscmsg;
 

void setup() {
  
  size(1280, 820);
  frameRate(20);
  oscP5 = new OscP5(this, 5007);
  myRemoteLocation = new NetAddress("127.0.0.1",5007);
  
  String displacement[] = loadStrings("displacement");
  String scales[] = loadStrings("scale");
  String gestures_list[] = loadStrings("gestures");
  
  for (int i = 0 ; i < displacement.length; i++) {
    int ds[] = int(displacement[i].split(", "));
    for (int j = 0; j < ds.length; j++) {
      notes_on_board[i][j] = ds[j];
    }
  }
  
  for (int i = 0; i < scales.length; i++) {
    int sc[] = int(scales[i].split(", "));
    for (int j = 0; j < sc.length; j++) {
      scale[j] = sc[j];
    }   
  }
  
  
  for (int i = 0; i < gestures_list.length; i++) {
    int gs[] = int(gestures_list[i].split(", "));
    for (int j = 0; j < gs.length; j++) {
      gestures[j] = gs[j];
    } 
  }
}


void draw() { 

  background(255);
  
  // BLACK
  pushMatrix();
  translate(x1,y1);
  s1.drawstaff(); 
  s1.makenote(notes1[0], 0); 
  s1.makenote(notes1[1], linlen/3); 
  
  if (movecount%2 == 0) {
    fill(255, 0, 0, 126);
    rect(0, 0, linlen, dist*5);
  }
  if (movecount%2 == 1) {
   g1.plotGesture(gestures[movecount]);
  }
  fill(0);
  ellipse(-50, 0, 40, 40);
  
  popMatrix();
  
  // WHITE
  pushMatrix();
  translate(x2,y2);
  s2.drawstaff(); 
  s2.makenote(notes2[0], 0);
  s2.makenote(notes2[1], linlen/3);
  
  if (movecount%2 == 1) {
    fill(255, 0, 0, 126);
    rect(0, 0, linlen, dist*5);
  }
  if (movecount%2 == 0) {
   g2.plotGesture(gestures[movecount]);
  }
  
  fill(255);
  ellipse(-50, 0, 40, 40);
  
  popMatrix();
 
  

} 


void oscEvent(OscMessage theOscMessage) {
  
  oscmsg = theOscMessage.get(0).stringValue();
  
  println("received: "+oscmsg);
  int oscvalues[] = int(oscmsg.split(","));

  int note1 = scale[notes_on_board[oscvalues[0]][oscvalues[1]]];
  int note2 = scale[notes_on_board[oscvalues[2]][oscvalues[3]]];
  
  if (movecount%2 == 0) {
    notes1[0] = min(note1, note2) + root;
    notes1[1] = max(note1, note2) + root;
  }
  else {
    notes2[0] = min(note1, note2) + root;
    notes2[1] = max(note1, note2) + root;
  }
  
  movecount++;
  
}
 
