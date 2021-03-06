//
//  ofAppUtils.cpp
//  videoMappingPreview
//
//  Created by 麦 on 1/20/15.
//
//

#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setGUI() {
	
	vector<string> emptyList;
	
	// setup widget
	gui = new ofxUICanvas(0, 0, 200, 600);
	
	gui->setPadding(3);
	gui->setColorBack(ofxUIColor(80, 80, 80, 200));
	gui->setColorFillHighlight(ofxUIColor(5, 140, 190, 255));
	gui->setFont(FONT_NAME);
	
	gui->addLabel("Screen");
	lblScreenName = gui->addLabel("file:", OFX_UI_FONT_SMALL);
	gui->addLabelButton("3D LOAD", false)->setLabelText("select 3d file..");
	gui->addSpacer();
	
	gui->addLabel("Source");
	ddlSyphon = gui->addDropDownList("SYPHON LIST", emptyList);
	ddlSyphon->setAllowMultiple(false);
	ddlSyphon->setAutoClose(true);
	ddlSyphon->setShowCurrentSelected(true);
	ddlSyphon->setLabelText("");
	gui->addSpacer();
	
	gui->addLabel("Display");
	gui->addToggle("show wireframe", &isShowWireframe);
	gui->addToggle("make window on top",&isWindowOnTop);
	gui->addSpacer();

	
	gui->addLabel("Camera");
	
	gui->setWidgetFontSize(OFX_UI_FONT_SMALL);
	gui->addWidgetDown(new ofxUILabelButton("add cam", false));
	gui->addWidgetRight((new ofxUILabelButton("remove cam", false)));
	
	ndCamX = gui->addNumberDialer("x", -10000.0f, 10000.0f, 0.0f, 2);
	ndCamX->setName("CAMERA X");
	ndCamY = gui->addNumberDialer("y", -10000.0f, 10000.0f, 0.0f, 2);
	ndCamY->setName("CAMERA Y");
	ndCamZ = gui->addNumberDialer("z", -10000.0f, 10000.0f, 0.0f, 2);
	ndCamZ->setName("CAMERA Z");
	
	msCamH = gui->addMinimalSlider("h", -180.0f, 180.0f, 0.0f);
	msCamH->setName("CAMERA H");
	msCamP = gui->addMinimalSlider("p", -180.0f, 180.0f, 0.0f);
	msCamP->setName("CAMERA P");
	msCamB = gui->addMinimalSlider("b", -180.0f, 180.0f, 0.0f);
	msCamB->setName("CAMERA B");
	
	msCamFov = gui->addMinimalSlider("fov", 10.0f, 170.0f, 45.0f);
	msCamFov->setName("CAMERA FOV");
	
	gui->autoSizeToFitWidgets();
	gui->loadSettings("gui.xml");
	
	// set cam values
	camPos = grabCam.getPosition();
	ndCamX->setValue(camPos.x);
	ndCamY->setValue(camPos.y);
	ndCamZ->setValue(camPos.z);
	
	camEuler = grabCam.getOrientationEuler();
	msCamH->setValue(camEuler.x);
	msCamP->setValue(camEuler.y);
	msCamB->setValue(camEuler.z);
	
	ofAddListener(gui->newGUIEvent, this, &ofApp::guiEvent);
}

//--------------------------------------------------------------
bool ofApp::loadScreen(string path, string name) {

	// screen loader
	screen.loadModel( path );
	
	if ( screen.getMeshCount() == 0 ) {
		
		// default plane
		ofPlanePrimitive plane;
		plane.set(500, 500, 10, 10);
		mesh = plane.getMesh();
		
		name = "null";
	
	} else {
		
		mesh = screen.getMesh(0);
	}
	
	// duplicate original uv
	vector< ofVec2f >& coords = mesh.getTexCoords();
	texCoordsOrigin = coords;
	
	// save settings
	lblScreenName->setLabel("file: " + name);
	settings.setValue("settings:screenPath", path);
	settings.setValue("settings:screenName", name);
	
	return screen.getMeshCount() == 0;
}

//--------------------------------------------------------------
void ofApp::scaleScreenUV(int width, int height) {
	
	vector< ofVec2f >& coords = mesh.getTexCoords();
	
	for ( int i = 0; i < coords.size(); i++ ) {
		
		coords[i].x = texCoordsOrigin[i].x * width;
		coords[i].y = (1.0f - texCoordsOrigin[i].y) * height;
		
	}
}

//--------------------------------------------------------------
void ofApp::loadCams() {
	
	settings.pushTag("cameras");
	int numOfCams = settings.getNumTags("camera");
	
	if ( numOfCams > 0 ) {
		
		for ( int i = 0; i < numOfCams; i++ ) {
			settings.pushTag("camera", i);
			
			Camera c;
			
			c.name = settings.getValue("name", "camera");
			
			c.position.x = settings.getValue("x", 0);
			c.position.y = settings.getValue("y", 0);
			c.position.z = settings.getValue("z", 0);
			
			c.euler.x = settings.getValue("h", 0);
			c.euler.y = settings.getValue("p", 0);
			c.euler.z = settings.getValue("b", 0);
			
			c.fov = settings.getValue("fov", 55);
			
			cams.push_back( c );
			
			settings.popTag();
		}
	}
	settings.popTag();
}

void ofApp::saveCams() {
	
	if ( !settings.tagExists("cameras") ) {
		settings.addTag("cameras");
	}
	settings.clearTagContents("cameras");
	settings.pushTag("cameras");
	
	for ( int i = 0; i < cams.size(); i++ ) {
		
		settings.addTag("camera");
		settings.pushTag("camera", i);
		
		settings.addValue("name", cams[i].name);
		settings.addValue("x", cams[i].position.x);
		settings.addValue("y", cams[i].position.y);
		settings.addValue("z", cams[i].position.z);
		settings.addValue("h", cams[i].euler.x);
		settings.addValue("p", cams[i].euler.y);
		settings.addValue("b", cams[i].euler.z);
		settings.addValue("fov", cams[i].fov);
		
		settings.popTag();
	}
	
	settings.popTag();
}

void ofApp::changeCam(int index) {
	
	if (index < 0 || cams.size() <= index)
		return;
	
	Camera c = cams[index];
	
	grabCam.setPosition(c.position);
	grabCam.setOrientation(c.euler);
	grabCam.setFov(c.fov);
	
	camIndex = index;
}

void ofApp::resetCam() {
	
	grabCam.reset();
	grabCam.setFov(55);
	grabCam.setFixUpwards(true);
	grabCam.setPosition(500, 500, -500);
	
	camIndex = CAM_INDEX_DEFAULT;
}

//--------------------------------------------------------------
void ofApp::setWindowOnTop(bool flag) {
	
	NSWindow * window = (NSWindow *)ofGetWindowPtr()->getCocoaWindow();
	
	if ( flag ) {
		
		[window setLevel:CGShieldingWindowLevel()];
		
	} else {
		
		[window setLevel:NSNormalWindowLevel];
		
	}
}