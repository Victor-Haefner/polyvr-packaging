#define GL_GLEXT_PROTOTYPES
#define EGL_EGLEXT_PROTOTYPES

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <emscripten.h>

#include <OpenSG/OSGGL.h>
#include <OpenSG/OSGGLUT.h>
#include <OpenSG/OSGConfig.h>
#include <OpenSG/OSGSimpleGeometry.h>
#include <OpenSG/OSGChunkMaterial.h>
#include <OpenSG/OSGMaterialChunk.h>
#include <OpenSG/OSGPolygonChunk.h>
#include <OpenSG/OSGShaderProgram.h>
#include <OpenSG/OSGShaderProgramChunk.h>
#include <OpenSG/OSGGLUTWindow.h>
#include <OpenSG/OSGPerspectiveCamera.h>
#include <OpenSG/OSGTransform.h>
#include <OpenSG/OSGRenderAction.h>
#include <OpenSG/OSGViewport.h>
#include <OpenSG/OSGSolidBackground.h>
#include <OpenSG/OSGDirectionalLight.h>
#include <OpenSG/OSGSimpleTexturedMaterial.h>
#include <OpenSG/OSGImage.h>
#include <OpenSG/OSGImageFileHandler.h>
#include <OpenSG/OSGPNGImageFileType.h>
#include <OpenSG/OSGJPGImageFileType.h>

using namespace OSG;
using namespace std;

PerspectiveCameraRecPtr camera;
ViewportRecPtr viewport;
WindowRecPtr window;
NodeRecPtr scene, camBeacon, lightBeacon, lightNode;
RenderActionRefPtr renderAction;
ShaderProgramRecPtr vProgram, fProgram;
SolidBackgroundRecPtr background;
//TransformRefPtr trans;
ChunkMaterialRecPtr mat;
ShaderProgramChunkRecPtr shaderChunk;
ShaderProgramChunkRecPtr shaderFailChunk;
bool matVShaderFail = false;
bool matFShaderFail = false;


string vdata = "super vertex shader!";
string fdata = "super fragment shader!";

string vFailData = 
"attribute vec4 osg_Vertex;\n"
"uniform mat4 OSGModelViewProjectionMatrix;\n"
"void main(void) {\n"
"  gl_Position = OSGModelViewProjectionMatrix * osg_Vertex;\n"
"}\n";

string fFailData = 
"precision mediump float;\n"
"void main(void) {\n"
"  gl_FragColor = vec4(0.0,0.8,1.0,1.0);\n"
"}\n";

bool checkShader(int type, string shader, string name) {
    //if (!eglGetCurrentContext()) return;
    GLuint shaderObject = glCreateShader(type);
    int N = shader.size();
    const char* str = shader.c_str();
    glShaderSource(shaderObject, 1, &str, &N);
    glCompileShader(shaderObject);

    GLint compiled;
    glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &compiled);
    if (!compiled) cout << "Shader "+name+" did not compiled!\n";

    GLint blen = 0;
    GLsizei slen = 0;
    glGetShaderiv(shaderObject, GL_INFO_LOG_LENGTH , &blen);
    if (blen > 1) {
        GLchar* compiler_log = (GLchar*)malloc(blen);
        glGetShaderInfoLog(shaderObject, blen, &slen, compiler_log);
        cout << "Shader "+name+" warnings and errors:\n";
        cout << string(compiler_log);
        free(compiler_log);
	return false;
    }
    return true;
}

extern "C" {
EMSCRIPTEN_KEEPALIVE const char* getVertexShader() {
	return vdata.c_str();
}

EMSCRIPTEN_KEEPALIVE const char* getFragmentShader() {
	return fdata.c_str();
}

EMSCRIPTEN_KEEPALIVE void setVertexShader(const char* s) {
	vdata = string(s);
	matVShaderFail = !checkShader(GL_VERTEX_SHADER, vdata, "vertexShader");
	if (matVShaderFail) {
		if (mat->find(shaderChunk) != -1) {
			mat->subChunk(shaderChunk);
			mat->addChunk(shaderFailChunk);
		}
	} else {
		vProgram->setProgram(vdata);
		if (!matFShaderFail && mat->find(shaderFailChunk) != -1) {
			mat->subChunk(shaderFailChunk);
			mat->addChunk(shaderChunk);
		}
	}
}

EMSCRIPTEN_KEEPALIVE void setFragmentShader(const char* s) {
	fdata = string(s);
	matFShaderFail = !checkShader(GL_FRAGMENT_SHADER, fdata, "fragmentShader");
	if (matFShaderFail) {
		if (mat->find(shaderChunk) != -1) {
			mat->subChunk(shaderChunk);
			mat->addChunk(shaderFailChunk);
		}
	} else {
		fProgram->setProgram(fdata);
		if (!matVShaderFail && mat->find(shaderFailChunk) != -1) {
			mat->subChunk(shaderFailChunk);
			mat->addChunk(shaderChunk);
		}
	}
}
}


NodeTransitPtr createEmptyScene(void) {
	// camera
	Matrix camM;
	camM.setTransform(Vec3f(0,  0, 8));

	TransformRecPtr camTrans  = Transform::create();
	camTrans->setMatrix(camM);

	camBeacon = Node::create();
	camBeacon->setCore(camTrans);

	// light
	Matrix lightM;
	lightM.setTransform(Vec3f( 1, 10,  2));

	TransformRecPtr lightTrans = Transform::create();
	lightTrans->setMatrix(lightM);

	lightBeacon = Node::create();
	lightBeacon->setCore(lightTrans);
	DirectionalLightRecPtr dLight = DirectionalLight::create();
	dLight->setDirection(Vec3f(0,1,2));
	dLight->setDiffuse(Color4f(1,1,1,1));
	dLight->setAmbient(Color4f(0.2,0.2,0.2,1));
	dLight->setSpecular(Color4f(1,1,1,1));
	dLight->setBeacon(lightBeacon);

	lightNode = Node::create();
	lightNode->setCore(dLight);

	// scene
	NodeRecPtr root = Node::create();
	root->setCore(Group::create());
	root->addChild(camBeacon);
	root->addChild(lightNode);
	root->addChild(lightBeacon);
	return NodeTransitPtr(root);
}

string constructShaderVP() {
	string vp;
	vp += "attribute vec4 osg_Vertex;\n";
	vp += "attribute vec3 osg_Normal;\n";
	vp += "attribute vec2 osg_MultiTexCoord0;\n";
	vp += "uniform mat4 OSGModelViewProjectionMatrix;\n";
	vp += "uniform mat4 OSGNormalMatrix;\n";
	vp += "varying vec4 vertPos;\n";
	vp += "varying vec3 vertNorm;\n";
	vp += "varying vec4 color;\n";
	vp += "varying vec2 texCoord;\n";
	vp += "void main(void) {\n";
	vp += "  vertNorm = (OSGNormalMatrix * vec4(osg_Normal,1.0)).xyz;\n";
	vp += "  color = vec4(1.0,1.0,1.0,1.0);\n";
	vp += "  texCoord = osg_MultiTexCoord0;\n";
	vp += "  gl_Position = OSGModelViewProjectionMatrix * osg_Vertex;\n";
	vp += "}\n";
	return vp;
}

string constructShaderFP(bool doTex) {
	string fp;
	fp += "precision mediump float;\n";
	fp += "uniform sampler2D texture;\n";
	fp += "varying vec3 vertNorm;\n";
	fp += "varying vec4 color;\n";
	fp += "varying vec2 texCoord;\n";

	fp += "void main(void) {\n";
	fp += " vec3  n = normalize(vertNorm);\n";
	fp += " vec3  light = normalize( vec3(0.8,1.0,0.5) );\n";// directional light
	fp += " float NdotL = max(dot( n, light ), 0.0);\n";
	fp += " vec4  ambient = vec4(0.2,0.2,0.2,1.0) * color;\n";
	fp += " vec4  diffuse = vec4(1.0,1.0,0.9,1.0) * NdotL * color;\n";
	if (doTex) fp += " diffuse = diffuse * texture2D(texture, texCoord) * 0.1;\n";
	fp += " vec4  specular = vec4(1.0,1.0,1.0,1.0) * 0.0;\n";
        fp += " gl_FragColor = ambient + diffuse + specular;\n";
	//fp += " gl_FragColor = texture2D(texture, texCoord);\n";
	//fp += " gl_FragColor = vec4(texCoord.x, texCoord.y, 1.0, 1.0);\n";
	fp += "}\n";
	return fp;
}

ChunkMaterialRecPtr createDataMaterial() {
	mat = ChunkMaterial::create();
        MaterialChunkRecPtr colChunk = MaterialChunk::create();
        colChunk->setBackMaterial(false);
        mat->addChunk(colChunk);

	// texture
	Color3ub* data = new Color3ub[4];
	data[0] = Color3ub(255,0,255);
	data[1] = Color3ub(255,150,255);
	data[2] = Color3ub(255,150,255);
	data[3] = Color3ub(255,0,255);

	Color3f* dataF = new Color3f[4];
	dataF[0] = Color3f(10,0,10);
	dataF[1] = Color3f(10,5,10);
	dataF[2] = Color3f(10,5,10);
	dataF[3] = Color3f(10,0,10);

	OSG::ImageRecPtr image = OSG::Image::create();
	//image->set( Image::OSG_RGB_PF, 2, 2, 1, 1, 1, 0, (const uint8_t*)&data[0], Image::OSG_UINT8_IMAGEDATA, true, 1);
	image->set( Image::OSG_RGB_PF, 2, 2, 1, 1, 1, 0, (const uint8_t*)&dataF[0], Image::OSG_FLOAT32_IMAGEDATA, true, 1);
	TextureObjChunkRecPtr texChunk = TextureObjChunk::create();
	TextureEnvChunkRecPtr envChunk = TextureEnvChunk::create();
	texChunk->setImage(image);
	texChunk->setInternalFormat(GL_RGB); // GL_RGB32F
	mat->addChunk(texChunk);
	mat->addChunk(envChunk);

	// shader
	shaderChunk = ShaderProgramChunk::create(); 
	mat->addChunk(shaderChunk);

	vProgram = ShaderProgram::createVertexShader  ();
	fProgram = ShaderProgram::createFragmentShader();
	vProgram->createDefaulAttribMapping();
	vProgram->addOSGVariable("OSGNormalMatrix");
	vProgram->addOSGVariable("OSGModelViewProjectionMatrix");

	vdata = constructShaderVP().c_str();
	fdata = constructShaderFP(true).c_str();
	checkShader(GL_VERTEX_SHADER, vdata, "vertex shader");
	checkShader(GL_FRAGMENT_SHADER, fdata.c_str(), "fragment shader");
	vProgram->setProgram(vdata);
	fProgram->setProgram(fdata.c_str());
	shaderChunk->addShader(vProgram);
	shaderChunk->addShader(fProgram);
	return mat;
}

ChunkMaterialRecPtr createMaterial(bool cull, string tex) {
	mat = ChunkMaterial::create();
        MaterialChunkRecPtr colChunk = MaterialChunk::create();
        colChunk->setBackMaterial(false);
        mat->addChunk(colChunk);

	bool doTex = false;

	// texture
	if (tex != "") {
		OSG::ImageRecPtr image = OSG::Image::create();
		image->read(tex.c_str());
		TextureObjChunkRecPtr texChunk = TextureObjChunk::create();
		TextureEnvChunkRecPtr envChunk = TextureEnvChunk::create();
		texChunk->setImage(image);
		mat->addChunk(texChunk);
		mat->addChunk(envChunk);

		/*texChunk->setMinFilter (GL_LINEAR);
		texChunk->setMagFilter (GL_LINEAR);
		texChunk->setWrapS (GL_CLAMP_TO_EDGE);
		texChunk->setWrapT (GL_CLAMP_TO_EDGE);*/
		doTex = true;
	}

	// face culling
	PolygonChunkRecPtr polyChunk = PolygonChunk::create();
	if (cull) polyChunk->setCullFace(GL_FRONT);
	else polyChunk->setCullFace(GL_NONE);
	mat->addChunk(polyChunk);

	// shader
	shaderChunk = ShaderProgramChunk::create(); 
	mat->addChunk(shaderChunk);

	vProgram = ShaderProgram::createVertexShader  ();
	fProgram = ShaderProgram::createFragmentShader();
	vProgram->createDefaulAttribMapping();
	vProgram->addOSGVariable("OSGNormalMatrix");
	vProgram->addOSGVariable("OSGModelViewProjectionMatrix");

	vdata = constructShaderVP().c_str();
	fdata = constructShaderFP(doTex).c_str();
	checkShader(GL_VERTEX_SHADER, vdata, "vertex shader");
	checkShader(GL_FRAGMENT_SHADER, fdata.c_str(), "fragment shader");
	vProgram->setProgram(vdata);
	fProgram->setProgram(fdata.c_str());
	shaderChunk->addShader(vProgram);
	shaderChunk->addShader(fProgram);
	return mat;
}

void createGeo(GeometryRecPtr geo, Vec3f pos, ChunkMaterialRecPtr mat, NodeRecPtr parent) {
	geo->setMaterial(mat);

	NodeRecPtr torusN = Node::create();
	torusN->setCore(geo);
	TransformRecPtr trans = Transform::create();
	NodeRecPtr transN = Node::create();
	transN->setCore(trans);
	transN->addChild(torusN);
	parent->addChild(transN);

	Matrix m;
	m.setTransform( pos, Quaternion( OSG::Vec3f(0,1,0), 0 ) );
	trans->setMatrix(m);
}

NodeTransitPtr createScene(void) {
	// fail material
	shaderFailChunk = ShaderProgramChunk::create();
	ShaderProgramRefPtr vFProgram = ShaderProgram::createVertexShader  ();
	ShaderProgramRefPtr fFProgram = ShaderProgram::createFragmentShader();
	vFProgram->createDefaulAttribMapping();
	vFProgram->addOSGVariable("OSGModelViewProjectionMatrix");
	vFProgram->setProgram(vFailData);
	fFProgram->setProgram(fFailData);
	shaderFailChunk->addShader(vFProgram);
	shaderFailChunk->addShader(fFProgram);
	NodeRecPtr root = createEmptyScene();

	ChunkMaterialRecPtr mat1 = createMaterial(false, "texture.jpg"); // NPOT
	ChunkMaterialRecPtr mat2 = createMaterial(false, "texture.png"); // POT, rect, chars, trans
	ChunkMaterialRecPtr mat0 = createMaterial(false, ""); // no texture
	ChunkMaterialRecPtr mat3 = createMaterial(false, "texture2.png"); // POT
	ChunkMaterialRecPtr mat4 = createDataMaterial(); // float texture

	//createGeo(makeTorusGeo(0.5,1.5,8,16), OSG::Vec3f(-4,-2,0), mat3, lightNode);
	//createGeo(makeTorusGeo(0.5,1.5,8,16), OSG::Vec3f(-4, 2,0), mat2, lightNode);
	//createGeo(makeBoxGeo(3,3,3,1,1,1), OSG::Vec3f(0,-2,0), mat3, lightNode);
	createGeo(makeBoxGeo(3,3,3,1,1,1), OSG::Vec3f(0, 2,1), mat4, lightNode);
	//createGeo(makeBoxGeo(3,3,3,1,1,1), OSG::Vec3f(4,-2,0), mat0, lightNode);
	//createGeo(makeBoxGeo(3,3,3,1,1,1), OSG::Vec3f(4, 2,0), mat1, lightNode);
	
	//createGeo(makeBoxGeo(128,1,3,1,1,1), OSG::Vec3f(64,0,0), mat2, lightNode);

	return NodeTransitPtr(root);
}

void display(void) {
	static float f = 0;
	static float d = 1;
	f += d*0.005;
	if (abs(f) > 1) d *= -1;

	//background->setColor(Color3f(1,f,-f));
	//Matrix m;
	//m.setTransform( Vec3f(), Quaternion( OSG::Vec3f(0,1,0), f ) );
	//trans->setMatrix(m);
   
	if (window) {
		commitChanges();
		window->render(renderAction);
	}
}

void idle(void) {
	glutPostRedisplay();
}

void reshape(int w, int h) {
	//cout << "glut reshape " << glutGetWindow() << endl;
	if (window) {
		window->resize(w, h);
		glutPostRedisplay();
	}
}

void glutMouse(int b, int s, int x, int y) { cout << "glutMouse " << b << " " << s << " " << x << " " << y << endl; }
void glutMotion(int x, int y) { cout << "glutMotion " << x << " " << y << endl; }
void glutKeyboard(unsigned char k, int x, int y) { cout << "glutKeyboard " << k << " " << x << " " << y << endl; }
void glutKeyboard2(int k, int x, int y) { cout << "glutKeyboard2 " << k << " " << x << " " << y << endl; }

int main(int argc, char *argv[]) {
	osgInit(argc,argv);



	PNGImageFileType::the();
	JPGImageFileType::the();

	std::map<std::string, ImageFileType *> sMap = OSG::ImageFileHandler::the()->getSuffixTypeMap();
	std::map<std::string, ImageFileType *> mMap = OSG::ImageFileHandler::the()->getMimeTypeMap();
	cout << "supported image suffixes: " << endl;
	for (auto s : sMap) cout << " supported image suffix: " << s.first << endl;
	cout << "supported image mimes: " << endl;
	for (auto s : mMap) cout << " supported image mime: " << s.first << endl;



	glutInit(&argc, argv);
	glutInitWindowSize(300, 300);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
	int winid = glutCreateWindow("PolyVR");
	glutIdleFunc(idle);
	glutReshapeFunc(reshape);
	glutDisplayFunc(display);
	/*glutKeyboardFunc(glutKeyboard);
	glutSpecialFunc(glutKeyboard2);
	glutMotionFunc(glutMotion);
	glutMouseFunc(glutMouse);*/

	{
		scene = createScene();

		camera  = PerspectiveCamera::create();
		camera->setBeacon(camBeacon);
		camera->setFov(osgDegree2Rad(90));
		camera->setNear(0.1);
		camera->setFar(100);

		background = SolidBackground::create();
		background->setColor(Color3f(1,1,0));

		viewport  = Viewport::create();
		viewport->setCamera(camera);
		viewport->setBackground(background);
		viewport->setRoot(scene);
		viewport->setSize(0,0,1,1);

		renderAction = RenderAction::create();

		GLUTWindowRecPtr gwin = GLUTWindow::create();
		gwin->setGlutId(winid);
		gwin->setSize(300,300);
		window = gwin;
		window->addPort(viewport);
		window->init(); // black screen? needed? what does it actually do?

		commitChanges();
	}

	glutMainLoop();
	return 0;
}
