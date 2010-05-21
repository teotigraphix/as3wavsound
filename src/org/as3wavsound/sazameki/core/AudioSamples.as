package org.as3wavsound.sazameki.core {
	
	/**
	 * ...
	 * @author Takaaki Yamazaki(zk design), modified by b.bottema [Codemonkey]
	 */
	public class AudioSamples {
		public var left:Vector.<Number>;
		public var right:Vector.<Number>;
		private var _setting:AudioSetting;
		
		public function AudioSamples(setting:AudioSetting, length:Number = 0) {
			this._setting = setting;
			this.left = new Vector.<Number>(length, length > 0);
			if (setting.channels == 2) {
				this.right = new Vector.<Number>(length, length > 0);
			}
		}
		
		public function get length():int {
			return left.length;
		}
		
		public function get setting():AudioSetting {
			return _setting;
		}
		
		public function clearSamples():void {
			left = new Vector.<Number>(length, true);
			if (setting.channels == 2) {
				right = new Vector.<Number>(length, true);
			}
		}
	}
}