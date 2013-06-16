package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.Timer;
	
	public class PointBurst extends Sprite {
		// de stijl van het tekstje dat in de pop up box komt
		static const fontFace:String = "Arial";
		static const fontSize:int = 20;
		static const fontBold:Boolean = false;
		static const fontColor:Number = 0xFFFFFF;
		
		// de animatie
		static const animSteps:int = 10;
		static const animStepTime:int = 50;
		static const startScale:Number = 0;
		static const endScale:Number = 2.0;
		
		private var tField:TextField;
		private var burstSprite:Sprite;
		private var parentMC:MovieClip;
		private var animTimer:Timer;		
		
		public function PointBurst(mc:MovieClip, pts:Object, x,y:Number) {
			
			// hier word het tekst formaat aangemaakt
			var tFormat:TextFormat = new TextFormat();
			tFormat.font = fontFace;
			tFormat.size = fontSize;
			tFormat.bold = fontBold;
			tFormat.color = fontColor;
			tFormat.align = "center";
			
			// hier word de text veld aangemaakt
			tField = new TextField();
			tField.embedFonts = true;
			tField.selectable = false;
			tField.defaultTextFormat = tFormat;
			tField.autoSize = TextFieldAutoSize.CENTER;
			tField.text = String(pts);
			tField.x = -(tField.width/2);
			tField.y = -(tField.height/2);
			
			// hier word de sprite aangemaakt
			burstSprite = new Sprite();
			burstSprite.x = x;
			burstSprite.y = y;
			burstSprite.scaleX = startScale;
			burstSprite.scaleY = startScale;
			burstSprite.alpha = 0;
			burstSprite.addChild(tField);
			parentMC = mc;
			parentMC.addChild(burstSprite);
			
			// dit zorgt ervoor dat de animatie van start gaat
			animTimer = new Timer(animStepTime,animSteps);
			animTimer.addEventListener(TimerEvent.TIMER, rescaleBurst);
			animTimer.addEventListener(TimerEvent.TIMER_COMPLETE, removeBurst);
			animTimer.start();
		}
		
		// hier is de animatie
		public function rescaleBurst(event:TimerEvent) {
			// een check van hoe ver we zijn (met de animatie)
			var percentDone:Number = event.target.currentCount/animSteps;
			// hier worde de scale en de alpha goed gezet
			burstSprite.scaleX = (1.0-percentDone)*startScale + percentDone*endScale;
			burstSprite.scaleY = (1.0-percentDone)*startScale + percentDone*endScale;
			burstSprite.alpha = 1.0-percentDone;
		}
		
		// een check of alles klaar is en dan verwijdert dit zichzelf
		public function removeBurst(event:TimerEvent) {
			burstSprite.removeChild(tField);
			parentMC.removeChild(burstSprite);
			tField = null;
			burstSprite = null;
			delete this;
		}
	}
}