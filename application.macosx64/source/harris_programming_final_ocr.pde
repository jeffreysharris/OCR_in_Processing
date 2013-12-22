import processing.video.*;
import gab.opencv.*;

Capture video;
OpenCV opencv1, archetype;
PImage findings, templt;

int[] archVertHist, archHorzHist;
ArrayList<Contour> contours, polygons;

int threshold = 1;
int targetWidth;
int targetHeight;

void setup() {
  int wdth = 640;
  int hght = 480;
  size(wdth, hght, P2D);
  //load source image to compare, template/archetype
  PImage letter = loadImage("B.jpg");
  OpenCV templtCV = new OpenCV(this, letter);
  ArrayList<Contour> templtContours = templtCV.findContours(false, true);
  Contour templtContour = templtContours.get(0);
  templt = letter.get(templtContour.getBoundingBox().x, templtContour.getBoundingBox().y, templtContour.getBoundingBox().width, templtContour.getBoundingBox().height);
  //build template histogram
  Histogram hist = new Histogram(templt);
  archVertHist = hist.yhist;
  archHorzHist = hist.xhist;
  //load webcam
  video = new Capture(this, 640, 480, 30);
  opencv1 = new OpenCV(this, video);
  video.start();
}

void draw() {
  background(0);
  //access video, switch to grayscale
  set(0, 0, video);
  opencv1.loadImage(video);
  opencv1.gray();
  opencv1.threshold(70);
  findings = opencv1.getOutput();
  findings.loadPixels();
  //find edges, shapes
  contours = opencv1.findContours();
	strokeWeight(3);
  //cycle through all found shapes
  int maxScore = 0;
	for (Contour c : contours) {
    if (c.area() > 10000) {
      //create PImage to pass to Histogram()
      PImage img = createImage(c.getBoundingBox().width, c.getBoundingBox().height, RGB);
      img.loadPixels();
      //iterate through opencv image (do it like pixels, y then x
      int pixCount = 0;
      for (int y = c.getBoundingBox().y; y < c.getBoundingBox().y + c.getBoundingBox().height; y++) {
        for (int x = c.getBoundingBox().x; x < c.getBoundingBox().x + c.getBoundingBox().width; x++) {
          int loc = x + (y * findings.width);
          img.pixels[pixCount] = findings.pixels[loc];
          pixCount++;
        }
      }
      
      /*//or use PImage get();
      PImage img = findings.get(c.getBoundingBox().x, c.getBoundingBox().y, c.getBoundingBox().width, c.getBoundingBox().height);
      */
      //resize img for normalized comparison to template
      //use the smaller difference as guide for resize
      if (templt.width - img.width > templt.height - img.height) {
        img.resize(0, templt.height);
      }
      else {
        img.resize(templt.width, 0);
      }
      //calc histogram x and y
      Histogram h = new Histogram(img);
      int[] histy = h.yhist;
      int[] histx = h.xhist;
      int score = 0;
      for (float i = 0; i < 1; i += 0.01) {
        int archy = floor(i  * archVertHist.length);
        int archx = floor(i * archHorzHist.length);
        int hy = floor(i * histy.length);
        int hx = floor(i * histx.length);
        //compare histograms
        if (archVertHist[archy] - histy[hy] < threshold && archVertHist[archy] - histy[hy] > (-1*threshold) && archHorzHist[archx] - histx[hx] < threshold && archHorzHist[archx] - histx[hx] > (-1*threshold)) {
          score++;
        }
      }
      if (score > maxScore) {
        maxScore = score;
        //outline bounding box of closest match
        pushStyle();
        noFill();
        stroke(255, 0, 0);
        rect(c.getBoundingBox().x, c.getBoundingBox().y, c.getBoundingBox().width, c.getBoundingBox().height);
        
        popStyle();
      }
    }
	}
}

class Histogram {
    int[] yhist;
    int[] xhist;
  Histogram(PImage src) {
    src.loadPixels();
    yhist = new int[src.height];
    xhist = new int[src.width];
    //default is 0
    for (int i = 0; i < yhist.length; i++) {
      yhist[i] = 0;
    }
    for (int i = 0; i < xhist.length; i++) {
      xhist[i] = 0;
    }
    //cycle through pixels of archetype, row by column
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        int loc = x + (y * src.width);
        //look for black
        if (src.pixels[loc] == 0) {
          //add to spot in histograms
          yhist[y]++;
          xhist[x]++;
        }
      }
    }
  }
}
