package{
	
	import away3d.containers.View3D;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.entities.Sprite3D;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Vector3D;
	import flash.system.fscommand;
	import flash.ui.Keyboard;
	
	/**
	 * Main class for the Road Trip Animation demo.
	 * 模拟在山区公路，夜间行车
	 * 
	 * See the demo here: 
	 * http://www.everydayflash.com/blog/index.php/2008/05/15/road-trip-papervision3d
	 * 
	 * Refer to the Downloads section to get a ZIP with the rest of the assets.
	 * 
	 * Author: Bartek Drozdz [ http://www.everydayflash.com ]
	 * 
	 * modify by Kenko, pv3d to away3d
	 */
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class Roadtrip extends Sprite {
		
		[Embed(source="../assets/texture.jpg")]
		private var HighwayTexture:Class;
		private var texture:MovingBitmap;
		private var terrain:MovingBitmap;
		
		[Embed(source="../assets/lightMap.jpg")]
		private var LightMap:Class;
		
		[Embed(source="../assets/map.png")]
		private var HighwayMap:Class;
		
		private var view:View3D;
                
		private var plane:Mesh;

		private var turns:Number = 0;
		private var heights:Number = 0;
		private var sides:Number = 0;
		private var speed:Number = 8;
		
		private var size:int = 41;

		private var verteX:Array;
		private var verteY:Array;
		
		public function Roadtrip() {
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.LOW;
			
			texture = new MovingBitmap((new HighwayTexture() as Bitmap).bitmapData, (new LightMap() as Bitmap).bitmapData);
			terrain = new MovingBitmap((new HighwayMap() as Bitmap).bitmapData);

			initAway3D();
			buildPlane();

			stage.addEventListener(KeyboardEvent.KEY_UP, toggleFs);
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		private function toggleFs(ke:KeyboardEvent):void {
			if (ke.keyCode == Keyboard.SPACE) {
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}
		
        private function initAway3D():void{
			//setup the view
			view = new View3D();
			addChild(view);
			
			//setup the camera
			view.camera.z = -350;
			view.camera.y = 25;
			view.camera.lookAt(new Vector3D());
		}
		
		private function buildPlane():void {
			plane = new Mesh(new PlaneGeometry(512, 512, size-1, size-1), new TextureMaterial(Cast.bitmapTexture(texture.getSnapshot())));
			plane.y = 0;
			plane.z = -60;
			view.scene.addChild(plane);
			
			plane.geometry.subGeometries[0].autoDeriveVertexNormals = false;
			plane.geometry.subGeometries[0].autoDeriveVertexTangents = false;
			var vertexData:Vector.<Number> = plane.geometry.subGeometries[0].vertexData;	//包含所有顶点的坐标值，长度是顶点数*3
			
			verteX = new Array();
			verteY = new Array();
			
			//记录下初始时，每个顶点的xy坐标
			for (var i:int = 0; i < vertexData.length; i+=3) {
				verteX.push(vertexData[i]);
				verteY.push(vertexData[i+1]);
			}
		}
		
		private function render(e:Event):void {
			texture.move(speed);
			terrain.move(speed * -.33);
			
			var vertexData:Vector.<Number> = plane.geometry.subGeometries[0].vertexData;	//包含所有顶点的坐标值，长度是顶点数*3
			var terrainSnapshot:BitmapData = terrain.getSnapshot(size/128);
			
			for (var i:int = 0; i < vertexData.length; i+=3) {
				var px:int = i/3 % size;
				var py:int = i/3 / size;
				var vzpos:Number = terrainSnapshot.getPixel(px, py) & 0xff;
				vertexData[i+1] = vzpos * (Math.sin(sides) + 1) / 3;				//主要控制高度变化
				vertexData[i] = verteX[i/3] + py * Math.sin(turns) * Math.cos(py/8) * 4;	//拐弯效果，cos(py/8)控制弯的大小, sin控制左右变化，py控制眼前位置不变形
			}
			
			plane.geometry.subGeometries[0].updateVertexData(vertexData);
			
			turns += 0.02;
			heights += 0.015;
			sides += 0.005;
			
			var oldMaterial:MaterialBase = plane.material;
			plane.material = new TextureMaterial(Cast.bitmapTexture(texture.getSnapshot()));
			oldMaterial.dispose();	//手工释放显存，否则过几十秒就报错
			
            view.render();
        }
	}
}








