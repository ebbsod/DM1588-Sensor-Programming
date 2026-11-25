import processing.net.*;
import processing.serial.*;
import processing.sound.*;

Server thisNode;
Client otherNode;
Serial myPort;

SoundFile[] strings = new SoundFile[6];
SoundFile wrong;

// chords
// which fret is pressed E A D G B e, -1 means not played
int[] openString = {0, 0, 0, 0, 0, 0};
int[] eMajor = {0, 2, 2, 1, 0, 0};
int[] cMajor = {0, 3, 2, 0, 1, 0};
int[] aMajor = {0, 0, 2, 2, 2, 0};
int[] aMinor = {-1, 0, 2, 2, 1, 0};
int[] gMajor = {3, 2, 0, 0, 0, 3};
int[] dMajor = {-1, -1, 0, 2, 3, 2};
int[] fMajor = {1, 3, 3, 2, 1, 1};
int[] fMinor = {1, 3, 3, 1, 1, 1};

boolean MatchChord = true;
boolean finger0on = false;
boolean finger1on = false;
boolean finger2on = false;

int strumIndex = -1;       // current string
int strumDirection = 0;    // 1 = down, -1 = up
int strumSpeed = 2;   // frames between strings
int lastStrum = 0;

String playedChord;
String Tone;
String SensorVal;
String chord;


float finger0 = 0;
float finger1 = 0;
float finger2 = 0;



// ------------ SETUP ----------------

void setup() {

  size(400, 200);   // NEVER use size(0,0)

  // ---- Server ----
  thisNode = new Server(this, 5204);

  // ---- Serial ----
  println("Available ports:");
  println(Serial.list());

  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];  // change index if wrong
    myPort = new Serial(this, portName, 9600);
  } else {
    println("No serial ports found!");
  }

  // ---- Load sound files (must be inside /data folder) ----
  strings[0] = new SoundFile(this, "E2.wav");
  strings[1] = new SoundFile(this, "A2.wav");
  strings[2] = new SoundFile(this, "D3.wav");
  strings[3] = new SoundFile(this, "G3.wav");
  strings[4] = new SoundFile(this, "B3.wav");
  strings[5] = new SoundFile(this, "E4.wav");
  wrong = new SoundFile(this, "wrong.mp3");
}


// ---------------- MAIN LOOP ----------------

void draw() {
  importData();
  playChord(-1, false);
  RocknRoll();
  RecieveData(otherNode);

  background(30);
  fill(255);
  textSize(12);
  text("Strum Direction: ", 20, 40);
  if (strumDirection == 1) text("DOWN", 105, 40);
  if (strumDirection == -1) text("UP", 105, 40);
  text("finger0 : " + finger0, 20, 60);
  text("finger1 : " + finger1, 20, 80);
  text("finger2 : " + finger2, 20, 100);
  text("Played chord : " + playedChord, 20, 120);
  text("Tone reciever : " + Tone, 20, 140);
  text("Key pressed : " + key, 20, 160);
}


// ---------------- STRUM LOGIC ----------------

void RocknRoll() {

  // Start new strum
  if (strumIndex == -1 && strumDirection != lastStrum) {

    if (strumDirection == -1) { // UP strum
      strumIndex = 5;  // start from high string
      
    } else if (strumDirection == 1) { // DOWN strum
      strumIndex = 0;  // start from low string
    }

    lastStrum = strumDirection;
  }

  // Play strings one by one
  if (strumIndex != -1 && frameCount % strumSpeed == 0) {


    if (MatchChord == true)
    {
      playChord(strumIndex, true);
    } else if (MatchChord == false && !wrong.isPlaying()) {
      playChord(strumIndex, false);
      wrong.play();
    }


    strumIndex += strumDirection;

    // End of strum
    if (strumIndex < 0 || strumIndex > 5) {
      strumIndex = -1;
    }
  }
}


// ---------------- PLAY STRING ----------------

/*
int[] openString = {0, 0, 0, 0, 0, 0};
 int[] eMajor = {0, 2, 2, 1, 0, 0};
 int[] cMajor = {0, 3, 2, 0, 1, 0};
 int[] aMajor = {0, 0, 2, 2, 2, 0};
 int[] aMinor = {0, 0, 2, 2, 1, 0};
 int[] gMajor = {3, 2, 0, 0, 0, 3};
 int[] dMajor = {-1, -1, 0, 2, 3, 2};
 int[] fMajor = {0, 0, 2, 2, 1, 0};
 int[] fMinor = {0, 0, 2, 2, 1, 0};
 */

void playChord(int i, boolean playSound) {

  finger0on = finger0 > 400;
  finger1on = finger1 > 400;
  finger2on = finger2 > 400;

  if (!finger0on && !finger1on && !finger2on) {
    if (playSound) chooseChord(i, openString);
    playedChord = "openString";
  } else if (finger0on && !finger1on && !finger2on) {
    if (playSound) chooseChord(i, cMajor);
    playedChord = "cMajor";
  } else if (!finger0on && finger1on && !finger2on) {
    if (playSound) chooseChord(i, dMajor);
    playedChord = "dMajor";
  } else if (!finger0on && !finger1on && finger2on) {
    if (playSound) chooseChord(i, aMinor);
    playedChord = "aMinor";
  } else if (finger0on  && finger1on && !finger2on) {
    if (playSound) chooseChord(i, fMinor);
    playedChord = "fMinor";
  } else if (finger0on && !finger1on && finger2on) {
    if (playSound) chooseChord(i, fMajor);
    playedChord = "fMajor";
  } else if (!finger0on && finger1on && finger2on) {
    if (playSound) chooseChord(i, gMajor);
    playedChord = "gMajor";
  } else if (finger0on && finger1on && finger2on) {
    if (playSound) chooseChord(i, eMajor);
    playedChord = "eMajor";
  }
  sendData();
}

void chooseChord(int i, int[] chord) {

  // dont play some strings marked -1
  if (chord[i] == -1) return;

  float rateValue = pow(2, chord[i] / 12.0); // calculates the freq of string & fret

  strings[i].stop();
  strings[i].rate(rateValue);
  strings[i].play();
}

// ---------------- SERIAL INPUT ----------------

void importData() {

  if (myPort != null && myPort.available() > 0) {

    SensorVal = myPort.readStringUntil('\n');

    if (SensorVal != null) {

      SensorVal = trim(SensorVal);
      String[] values = split(SensorVal, ",");

      if (values.length == 4) {
        finger0 = float(values[0]);
        finger1 = float(values[1]);
        finger2 = float(values[2]);
        strumDirection = int(values[3]);
      }
    }
  }
}



void serverEvent(Server someServer, Client someClient) {
  println("We have a new client: " + someClient.ip());
  otherNode = someClient;
}




// ---------------- SEND DATA ----------------

void sendData() {
  if (otherNode != null && playedChord != null) {
    otherNode.write(playedChord);
    println("Sent data: " + playedChord);
  }
}

void RecieveData(Client client) {

  if (client == null) {
    MatchChord = true;
    return;
  }

  String receivedVal = client.readStringUntil('\n');
  if (receivedVal != null) {
    receivedVal = trim(receivedVal).toLowerCase();
    Tone = split(receivedVal, ",")[0];
    println("received from " + client.ip() + ": " + Tone);

    if (key == 'a') {
      println("Game mode on");
      if (playedChord != null && playedChord.toLowerCase().startsWith(Tone)) {
        MatchChord = true;
      } else {
        MatchChord = false;
      }
    }
  } else if (key == 's') {
    MatchChord = true;
  }
}
