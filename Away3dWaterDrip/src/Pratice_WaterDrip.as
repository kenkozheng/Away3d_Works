/*

这个是自己的练习，模拟水滴滴到水面

*/

package
{

	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.SubGeometry;
	import away3d.core.pick.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.*;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Max3DSParser;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.geom.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.*;
	import flash.utils.*;
	
	import shallowwater.*;

	[SWF(backgroundColor="#000000", frameRate="30")]
	public class Pratice_WaterDrip extends Sprite
	{
		// Environment map.
		[Embed(source="../embeds/skybox/sky_posX.jpg")]
		private var EnvPosX:Class;
		[Embed(source="../embeds/skybox/sky_posY.jpg")]
		private var EnvPosY:Class;
		[Embed(source="../embeds/skybox/sky_posZ.jpg")]
		private var EnvPosZ:Class;
		[Embed(source="../embeds/skybox/sky_negX.jpg")]
		private var EnvNegX:Class;
		[Embed(source="../embeds/skybox/sky_negY.jpg")]
		private var EnvNegY:Class;
		[Embed(source="../embeds/skybox/sky_negZ.jpg")]
		private var EnvNegZ:Class;
		
		//stats
		private var stats:AwayStats;
		
		//water drip model
		[Embed(source="/../embeds/waterDrip/drip.3ds",mimeType="application/octet-stream")]
		public static var Drip1:Class;
//		[Embed(source="/../embeds/waterDrip/under.3ds",mimeType="application/octet-stream")]
//		public static var Drip2:Class;
//		[Embed(source="/../embeds/waterDrip/zhu.3ds",mimeType="application/octet-stream")]
//		public static var Drip3:Class;
//		[Embed(source="/../embeds/waterDrip/break.3ds",mimeType="application/octet-stream")]
//		public static var Drip4:Class;
//		[Embed(source="/../embeds/waterDrip/reach.3ds",mimeType="application/octet-stream")]
//		public static var Drip5:Class;
		private static var DripClasses:Array = [Drip1];
		
		//the edge of pool
		[Embed(source="../embeds/desertsand.jpg")]
		private var PoolWall:Class;

		// Disturbance brushes.
		[Embed(source="../embeds/assets.swf", symbol="Brush3")]
		private var Brush3:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//light objects
		private var skyLight:PointLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var liquidMaterial:ColorMaterial;
		private var waterDripMaterial:ColorMaterial;
		private var poolMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//fluid simulation variables
		private var gridDimension:uint = 200;
		private var gridSpacing:uint = 2;
		private var planeSize:Number;
		
		//scene objects
		private var text:TextField;
		public var fluid:ShallowFluid;
		private var plane:Mesh;
		private var fluidDisturb:FluidDisturb;
		private var dripDisturb:DisturbanceBrush;
		private var waterDrips:Array;
		private var waterDripModels:Vector.<Mesh>;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 2;
		private var panSpeed:Number = 2;
		private var distanceSpeed:Number = 2;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;
		
		/**
		 * Constructor
		 */
		public function Pratice_WaterDrip()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initText();
			initLights();
			initMaterials();
			initObjects();
			initFluid();
			initListeners();
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			view = new View3D();
			scene = view.scene;
			camera = view.camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 180, 20, 320, 5);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			stats = new AwayStats(view);
			addChild(stats);
		}
		
		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Author: kenkofox@qq.com\n" + 
				"Mouse click and drag - rotate\n" + 
				"Cursor keys / WSAD - move\n" + 
				"R - create a drip\n";
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			skyLight = new PointLight();
			skyLight.color = 0xAAAAFF;
			skyLight.specular = 0.5;
			skyLight.diffuse = 2;
			scene.addChild(skyLight);
			
			lightPicker = new StaticLightPicker([skyLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(0, 2500, 0x000000);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));
			
			liquidMaterial = new ColorMaterial(0xFFFFFF);
			liquidMaterial.specular = 0.5;
			liquidMaterial.ambient = 0.25;
			liquidMaterial.addMethod(new EnvMapMethod(cubeTexture, 1));
			liquidMaterial.lightPicker = lightPicker;
			liquidMaterial.alpha = 0.7;
			
			waterDripMaterial = new ColorMaterial(0xFFFFFF);
			waterDripMaterial.specular = 10;
			waterDripMaterial.ambient = 0.25;
			waterDripMaterial.addMethod(new EnvMapMethod(cubeTexture, 0.5));
			waterDripMaterial.lightPicker = lightPicker;
			waterDripMaterial.alpha = 0.7;
			
			poolMaterial = new TextureMaterial(Cast.bitmapTexture(new PoolWall()));
			poolMaterial.addMethod(fogMethod);
			poolMaterial.lightPicker = lightPicker;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{		
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));

			//create water plane.
			var planeSegments:uint = (gridDimension - 1);
			planeSize = planeSegments*gridSpacing;
			plane = new Mesh(new PlaneGeometry(planeSize, planeSize, planeSegments, planeSegments), liquidMaterial);
			plane.rotationX = 90;
			plane.x -= planeSize/2;
			plane.z -= planeSize/2;
			plane.y = 0;
			plane.mouseEnabled = true;
			plane.pickingCollider = PickingColliderType.BOUNDS_ONLY;
			plane.geometry.convertToSeparateBuffers();
			plane.geometry.subGeometries[0].autoDeriveVertexNormals = false;
			plane.geometry.subGeometries[0].autoDeriveVertexTangents = false;
			scene.addChild(plane);

			//create pool
			var poolHeight:Number = 50;
			var poolThickness:Number = 10; 
			var poolVOffset:Number = 15 - poolHeight/2;
			var poolHOffset:Number = planeSize/2 + poolThickness/2;
			
			var left:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness*2), poolMaterial);
			left.x = -poolHOffset;
			left.y = poolVOffset;
			scene.addChild(left);
			
			var right:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness*2), poolMaterial);
			right.x = poolHOffset;
			right.y = poolVOffset;
			scene.addChild(right);
			
			var back:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			back.z = poolHOffset;
			back.y = poolVOffset;
			scene.addChild(back);
			
			var front:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			front.z = -poolHOffset;
			front.y = poolVOffset;
			scene.addChild(front);
			
			var buttom:Mesh = new Mesh(new CubeGeometry(planeSize + poolThickness*2, poolThickness, planeSize + poolThickness*2), poolMaterial);
			buttom.y = -poolHeight + 15 - poolThickness/2;
			scene.addChild(buttom);
			
			//load water drip
			AssetLibrary.enableParser(Max3DSParser);
			waterDripModels = new Vector.<Mesh>();
			for (var i:int = 0; i < DripClasses.length; i++) 
			{
				loadWaterDripModel(i);
			}
		}
		
		/**
		 * Initialise the fluid
		 */
		private function initFluid():void
		{		
			// Fluid.
			var dt:Number = 1 / stage.frameRate;
			var viscosity:Number = 0.3;
			var waveVelocity:Number = 0.99; // < 1 or the sim will collapse.
			fluid = new ShallowFluid(gridDimension, gridDimension, gridSpacing, dt, waveVelocity, viscosity);

			// Disturbance util.
			fluidDisturb = new FluidDisturb(fluid);
			
			//init Disturbance brush
			dripDisturb = new DisturbanceBrush();
			dripDisturb.fromSprite(new Brush3() as Sprite);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}
		
		private function loadWaterDripModel(index:int):void
		{
			var loader3d:Loader3D = new Loader3D();
			loader3d.addEventListener(AssetEvent.ASSET_COMPLETE, function(event:AssetEvent):void
			{
				if (event.asset.assetType == AssetType.MESH) {
					waterDripModels[index] = event.asset as Mesh;
				}
			});
			loader3d.loadData(new DripClasses[index]());
		}
		
		private function createDrip():void
		{
			if(!waterDripModels || waterDripModels.length == 0)
				return;
			if(!waterDrips)
				waterDrips = new Array();
			var waterDrip:Mesh = waterDripModels[0].clone() as Mesh;
			waterDrip.material = waterDripMaterial;
			waterDrip.y = 50;
			waterDrip.x = (planeSize - 50) * Math.random() - (planeSize - 50)/2;
			waterDrip.z = (planeSize - 50) * Math.random() - (planeSize - 50)/2;
			waterDrip.scale(2);
			waterDrips.push({mesh:waterDrip, status:0, step:0, initHeight:waterDrip.y});
			scene.addChild(waterDrip);
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			// Update fluid.
			fluid.evaluate();
			
			//update water drips
			evaluateWaterDrips();

			// Update plane to fluid.
			var subGeometry:SubGeometry = plane.geometry.subGeometries[0] as SubGeometry;
			subGeometry.updateVertexData(fluid.points);
			subGeometry.updateVertexNormalData(fluid.normals);
			subGeometry.updateVertexTangentData(fluid.tangents);

			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;
			
			// Update light.
			skyLight.transform = camera.transform.clone();
			
			view.render();
		}
		
		private function evaluateWaterDrips():void
		{
			if(!waterDrips)
				return;
			var g:Number = 0.5;
			for (var i:int = waterDrips.length - 1; i >= 0 ; i--) 
			{
				switch(waterDrips[i].status)
				{
					case 0:
						var dy:Number = -g * waterDrips[i].step;
						waterDrips[i].mesh.y += dy;
						if(waterDrips[i].mesh.y <= 0)
						{
							waterDrips[i].status = 1;
							waterDrips[i].step = 0;
							
							fluidDisturb.disturbBitmapInstant((waterDrips[i].mesh.x - plane.x)/planeSize, (waterDrips[i].mesh.z - plane.z)/planeSize, 3, dripDisturb.bitmapData);
							scene.removeChild(waterDrips[i].mesh);
							waterDrips.splice(i, 1);
							
//							Mesh(waterDrips[i].mesh).geometry = waterDripModels[1].geometry.clone();
						}
						else
						{
							waterDrips[i].step++;
						}
						break;
					
					//预留接口加入更多状态，不过暂时效果挺好的，不需要加入更多状态了
				}
			}
			
		}
		
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
					tiltIncrement = tiltSpeed;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = -tiltSpeed;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					panIncrement = panSpeed;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = -panSpeed;
					break;
				case Keyboard.Z:
					distanceIncrement = distanceSpeed;
					break;
				case Keyboard.X:
					distanceIncrement = -distanceSpeed;
					break;
				case Keyboard.R:
					createDrip();
					break;
			}
		}
		
		/**
		 * Key up listener for camera control
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = 0;
					break;
				case Keyboard.Z:
				case Keyboard.X:
					distanceIncrement = 0;
					break;
			}
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			stats.x = stage.stageWidth - stats.width;
		}
		
	}
}
