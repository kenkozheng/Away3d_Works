package
{

	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.display.BlendMode;

	/**
	 * This class is responsible for scrolling a bitmap.
	 *
	 * It works a little like BitmapData.scroll, but the difference is that is wraps the image.
	 *
	 * This class is made for the Road Trip example so it is not too general. It only can scroll
	 * on the Y axis.
	 *
	 * It also accepts an optional argument - mask, which is a mask applied to the BitmapData (with
	 * blendmode = multiply). This is used for the pseudo-light casted in the animation on to the
	 * ground texture.
	 *
	 * Author: Bartek Drozdz [ http://www.everydayflash.com ]
	 *
	 */
	public class MovingBitmap extends Sprite
	{

		public var snapshot:BitmapData;

		private var contentBitmap:Bitmap;
		private var maskBitmap:Bitmap;

		private var dismap:BitmapData;
		private var zero:Point = new Point(0, 0);

		public var X:int = 1;
		public var Y:int = 2;
		private var moveBuffer:Number = 0;

		public function MovingBitmap(bmp:BitmapData, mask:BitmapData=null)
		{
			contentBitmap = new Bitmap(bmp);
			addChild(contentBitmap);

			if (mask != null)
			{
				maskBitmap = new Bitmap(mask);
				maskBitmap.blendMode = BlendMode.MULTIPLY;
				addChild(maskBitmap);
			}

			snapshot = new BitmapData(bmp.width, bmp.height);
			snapshot.draw(this);
		}

		public function move(speed:Number):void
		{
			var ct:Number = contentBitmap.bitmapData.width;
			var n:BitmapData = new BitmapData(ct, contentBitmap.bitmapData.height);
			if (speed > 0)
			{
				n.copyPixels(contentBitmap.bitmapData, new Rectangle(0, ct - speed, ct, speed), zero);
				n.copyPixels(contentBitmap.bitmapData, new Rectangle(0, 0, ct, ct), new Point(0, speed));
			}
			else
			{
				speed = Math.abs(speed);
				n.copyPixels(contentBitmap.bitmapData, new Rectangle(0, 0, ct, speed), new Point(0, ct - speed));
				n.copyPixels(contentBitmap.bitmapData, new Rectangle(0, speed, ct, ct), zero);
			}
			contentBitmap.bitmapData.dispose();
			contentBitmap.bitmapData = n;

			snapshot.draw(this);
		}

		public function getSnapshot(scale:Number = 1):BitmapData
		{
			if (scale != 1)
			{
				snapshot = new BitmapData(contentBitmap.bitmapData.width / scale, contentBitmap.bitmapData.height / scale);
				var m:Matrix = new Matrix();
				m.scale(scale, scale);
				snapshot.draw(this, m);
			}
			return snapshot;
		}
	}

}
