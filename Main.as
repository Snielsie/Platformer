package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.getTimer;
	
	public class Main extends MovieClip {
		// constante bewegingen (zwaartekracht)
		static const gravity:Number = .004;

		// scherm bewegingen (hoever je het scherm kan zien)
		static const edgeDistance:Number = 100;

		// hier worden objecten toegevoegd
		private var fixedObjects:Array;
		private var otherObjects:Array;
		
		// hier word de held en de vijanden toegevoegd
		private var hero:Object;
		private var enemies:Array;
		
		// Hier word de standaard instellingen van de game gedefinieerd
		private var playerObjects:Array;
		private var gameScore:int;
		private var gameMode:String = "start";
		private var playerLives:int;
		private var lastTime:Number = 0;
		
		// hier word de game gestart
		public function startPlatformGame() {
			playerObjects = new Array();
			gameScore = 0;
			gameMode = "play";
			playerLives = 3;
		}
		
		// hier word apart het level gestart 
		public function startGameLevel() {
			
			// hier worden de karakters gecreërd
			createHero();
			addEnemies();
			
			// hier word alles van het level nog eens bekeken en gechekt
			examineLevel();
			
			// hier worde de "listeners" toegevoegd, zodat de game runt en je ook input kan geven
			this.addEventListener(Event.ENTER_FRAME,gameLoop);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
			
			// hier word het begin van de game aangegeven, en ook waar hij moet starten
			gameMode = "play";
			addScore(0);
			showLives();
		}
		
		// Hier word de held gemaakt en gedefinieërd ( dus wat hij allemaal kan en wat de parameters ervan zijn)
		public function createHero() {
			hero = new Object();
			hero.mc = gamelevel.hero;
			hero.dx = 0.0;
			hero.dy = 0.0;
			hero.inAir = false;
			hero.direction = 1;
			hero.animstate = "stand";
			hero.walkAnimation = new Array(2,3,4,5,6,7,8);
			hero.animstep = 0;
			hero.jump = false;
			hero.moveLeft = false;
			hero.moveRight = false;
			hero.jumpSpeed = .8;
			hero.walkSpeed = .15;
			hero.width = 20.0;
			hero.height = 40.0;
			hero.startx = hero.mc.x;
			hero.starty = hero.mc.y;
		}
		
		// Deze functie vind alle vijanden en maakt objecten van de vijanden en definieërd ook de parameters van de vijanden
		public function addEnemies() {
			enemies = new Array();
			var i:int = 1;
			while (true) {
				if (gamelevel["enemy"+i] == null) break;
				var enemy = new Object();
				enemy.mc = gamelevel["enemy"+i];
				enemy.dx = 0.0;
				enemy.dy = 0.0;
				enemy.inAir = false;
				enemy.direction = 1;
				enemy.animstate = "stand"
				enemy.walkAnimation = new Array(2,3,4,5);
				enemy.animstep = 0;
				enemy.jump = false;
				enemy.moveRight = true;
				enemy.moveLeft = false;
				enemy.jumpSpeed = 1.0;
				enemy.walkSpeed = .08;
				enemy.width = 30.0;
				enemy.height = 30.0;
				enemies.push(enemy);
				i++;
			}
		}
		
		// Deze kijkt naar alles van het leven ook de "children" maar ook de muren, vloeren & objecten
		public function examineLevel() {
			fixedObjects = new Array();
			otherObjects = new Array();
			for(var i:int=0;i<this.gamelevel.numChildren;i++) {
				var mc = this.gamelevel.getChildAt(i);
				
				// hier worden de muren en de statichse objecten toegevoegt
				if ((mc is Floor) || (mc is Wall)) {
					var floorObject:Object = new Object();
					floorObject.mc = mc;
					floorObject.leftside = mc.x;
					floorObject.rightside = mc.x+mc.width;
					floorObject.topside = mc.y;
					floorObject.bottomside = mc.y+mc.height;
					fixedObjects.push(floorObject);
					
				// hier word "treasure" de "key", de "Door" aan other objects toegevoegd
				} else if ((mc is Treasure) || (mc is Key) || (mc is Door) || (mc is Chest)) {
					otherObjects.push(mc);
				}
			}
		}
		
		// hieronder word gedefinieërd wat er gebeurd als er een knop word ingedrukt, en zet de parameters ervan
		public function keyDownFunction(event:KeyboardEvent) {
			if (gameMode != "play") return; // hij beweegt niet tot de play mode van de game word aangeroepen
			
			if (event.keyCode == 37) {
				hero.moveLeft = true;
			} else if (event.keyCode == 39) {
				hero.moveRight = true;
			} else if (event.keyCode == 32) {
				if (!hero.inAir) {
					hero.jump = true;
				}
			}
		}
		
		public function keyUpFunction(event:KeyboardEvent) {
			if (event.keyCode == 37) {
				hero.moveLeft = false;
			} else if (event.keyCode == 39) {
				hero.moveRight = false;
			}
		}
		
		// hieronder worden taken van de game uitgevoerd
		public function gameLoop(event:Event) {
			
			// hier haalt hij het tijdverschil op
			if (lastTime == 0) lastTime = getTimer();
			var timeDiff:int = getTimer()-lastTime;
			lastTime += timeDiff;
			
			// hier word gecheckt of de taken allen worden uitgevoerd in de play mode van het spel
			if (gameMode == "play") {
				moveCharacter(hero,timeDiff);
				moveEnemies(timeDiff);
				checkCollisions();
				scrollWithHero();
			}
		}
		
		// hier zoekt hij alle vijanden op en zorgt hij ervoor dat alle vijanden gaan bewegen (dit doet hij via een loop)
		public function moveEnemies(timeDiff:int) {
			for(var i:int=0;i<enemies.length;i++) {
				
				// standaard beweging
				moveCharacter(enemies[i],timeDiff);
				
				// hieronder word gechekt dat als hij een muur raakt dat hij omkeert
				if (enemies[i].hitWallRight) {
					enemies[i].moveLeft = true;
					enemies[i].moveRight = false;
				} else if (enemies[i].hitWallLeft) {
					enemies[i].moveLeft = false;
					enemies[i].moveRight = true;
				}
			}
		}
		
		// hieronder word de primare functie van karakter beweging gedefinieërd
		public function moveCharacter(char:Object,timeDiff:Number) {
			if (timeDiff < 1) return;

			// hier word nagebootst dat het karakter naar benden word getrokken met zwaartekracht
			var verticalChange:Number = char.dy*timeDiff + timeDiff*gravity;
			if (verticalChange > 15.0) verticalChange = 15.0;
			char.dy += timeDiff*gravity;
			
			// hier word gecheckt of er een knop word ingedrukt en zoja dan moet het karakter er op reageren
			var horizontalChange = 0;
			var newAnimState:String = "stand";
			var newDirection:int = char.direction;
			if (char.moveLeft) {
				// loop naar links defintie
				horizontalChange = -char.walkSpeed*timeDiff;
				newAnimState = "walk";
				newDirection = -1;
			} else if (char.moveRight) {
				// loop naar rechts defintie
				horizontalChange = char.walkSpeed*timeDiff;
				newAnimState = "walk";
				newDirection = 1;
			}
			if (char.jump) {
				// start sprong definitie
				char.jump = false;
				char.dy = -char.jumpSpeed;
				verticalChange = -char.jumpSpeed;
				newAnimState = "jump";
			}
			
			// Hier word uitgegaan dat er geen muur is en dat hij in de lucht is.
			char.hitWallRight = false;
			char.hitWallLeft = false;
			char.inAir = true;
					
			// hieronder vind de game de verticale positie
			var newY:Number = char.mc.y + verticalChange;
		
			// hieronder word gechekt (door middel van een loopje die door alle objecten gaat) of het karakter geland is
			for(var i:int=0;i<fixedObjects.length;i++) {
				if ((char.mc.x+char.width/2 > fixedObjects[i].leftside) && (char.mc.x-char.width/2 < fixedObjects[i].rightside)) {
					if ((char.mc.y <= fixedObjects[i].topside) && (newY > fixedObjects[i].topside)) {
						newY = fixedObjects[i].topside;
						char.dy = 0;
						char.inAir = false;
						break;
					}
				}
			}
			
			// hieronder vind hij de nieuwe horizontale positie
			var newX:Number = char.mc.x + horizontalChange;
		
			// hier gaat hij weer via een loopje checken met alle objecten om te zien of de char een muur heeft geraakt
			for(i=0;i<fixedObjects.length;i++) {
				if ((newY > fixedObjects[i].topside) && (newY-char.height < fixedObjects[i].bottomside)) {
					if ((char.mc.x-char.width/2 >= fixedObjects[i].rightside) && (newX-char.width/2 <= fixedObjects[i].rightside)) {
						newX = fixedObjects[i].rightside+char.width/2;
						char.hitWallLeft = true;
						break;
					}
					if ((char.mc.x+char.width/2 <= fixedObjects[i].leftside) && (newX+char.width/2 >= fixedObjects[i].leftside)) {
						newX = fixedObjects[i].leftside-char.width/2;
						char.hitWallRight = true;
						break;
					}
				}
			}
			
			// dit definieërt de positie van het karakter
			char.mc.x = newX;
			char.mc.y = newY;
			
			// hieronder word de karakter animatie gedefinieërd
			if (char.inAir) {
				newAnimState = "jump";
			}
			char.animstate = newAnimState;
			
			// hier word de "walk" cycle geprompt (dus dat die moet beginnen)
			if (char.animstate == "walk") {
				char.animstep += timeDiff/60;
				if (char.animstep > char.walkAnimation.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.walkAnimation[Math.floor(char.animstep)]);
				
			// hieronder word gecheckt dat als hij niet loopt dat de "stand" of "jump" state aanstaat
			} else {
				char.mc.gotoAndStop(char.animstate);
			}
			
			// hieronder veranderd hij de directie van het karakter
			if (newDirection != char.direction) {
				char.direction = newDirection;
				char.mc.scaleX = char.direction;
			}
		}
		
		// hieronder checkt hij of het scherm lings of rechts moet scrollen
		public function scrollWithHero() {
			var stagePosition:Number = gamelevel.x+hero.mc.x;
			var rightEdge:Number = stage.stageWidth-edgeDistance;
			var leftEdge:Number = edgeDistance;
			if (stagePosition > rightEdge) {
				gamelevel.x -= (stagePosition-rightEdge);
				if (gamelevel.x < -(gamelevel.width-stage.stageWidth)) gamelevel.x = -(gamelevel.width-stage.stageWidth);
			}
			if (stagePosition < leftEdge) {
				gamelevel.x += (leftEdge-stagePosition);
				if (gamelevel.x > 0) gamelevel.x = 0;
			}
		}
		
		// hieronder checkt hij de "collision" met vijanden of objecten
		public function checkCollisions() {
			
			// vijanden via een for loop
			for(var i:int=enemies.length-1;i>=0;i--) {
				if (hero.mc.hitTestObject(enemies[i].mc)) {
					
					// hier word geckeckt of het karakter op de vijand is geland of ernaast (dus of de vijand doodgaat of de hero
					if (hero.inAir && (hero.dy > 0)) {
						enemyDie(i);
					} else {
						heroDie();
					}
				}
			}
			
			// hieronder word gechekt naar de items ook via een for loop
			for(i=otherObjects.length-1;i>=0;i--) {
				if (hero.mc.hitTestObject(otherObjects[i])) {
					getObject(i);
				}
			}
		}
		
		// Hieronder word de vijand weggehaald als hij gedood is door de held
		public function enemyDie(enemyNum:int) {
			var pb:PointBurst = new PointBurst(gamelevel,"Got Em!",enemies[enemyNum].mc.x,enemies[enemyNum].mc.y-20);
			gamelevel.removeChild(enemies[enemyNum].mc);
			enemies.splice(enemyNum,1);
		}
		
		// hieronder word gedefinieërd wat er gebeurd als de held doodgaat door een vijand
		public function heroDie() {
			// hier word het text vak met het game over tekstje gegenereerd
			var dialog:Dialog = new Dialog();
			dialog.x = 175;
			dialog.y = 100;
			addChild(dialog);
		
			if (playerLives == 0) {
				gameMode = "gameover";
				dialog.message.text = "Give it another go!";
			} else {
				gameMode = "dead";
				dialog.message.text = "You are totally dead!";
				playerLives--;
			}
			
			hero.mc.gotoAndPlay("die");
		}
		
		
		// hieronder word gechekct wat er gebeurd als de speler tegen een object komt
		public function getObject(objectNum:int) {
			// hieronder worden de punten toegegeven voor het vinden van een chest
			if (otherObjects[objectNum] is Treasure) {
				var pb:PointBurst = new PointBurst(gamelevel,100,otherObjects[objectNum].x,otherObjects[objectNum].y);
				gamelevel.removeChild(otherObjects[objectNum]);
				otherObjects.splice(objectNum,1);
				addScore(100);
				
			// hieronder word gedefinieërd wat er gebeurt als de speler de "key oppakt (deze gaat de inventory in)
			} else if (otherObjects[objectNum] is Key) {
				pb = new PointBurst(gamelevel,"Got Key!" ,otherObjects[objectNum].x,otherObjects[objectNum].y);
				playerObjects.push("Key");
				gamelevel.removeChild(otherObjects[objectNum]);
				otherObjects.splice(objectNum,1);
				
			// hieronder word gecheckt of de speler de deur heeft geraakt en of hij de sleutel heeft
			} else if (otherObjects[objectNum] is Door) {
				if (playerObjects.indexOf("Key") == -1) return;
				if (otherObjects[objectNum].currentFrame == 1) {
					otherObjects[objectNum].gotoAndPlay("open");
					levelComplete();
				}
				
			//hieronder word gechekt of de speler de "chest" heeft en daarmee stopt de game
			} else if (otherObjects[objectNum] is Chest) {
				otherObjects[objectNum].gotoAndStop("open");
				gameComplete();
			}
					
		}
		
		// hieronder word de score toegevoegd
		public function addScore(numPoints:int) {
			gameScore += numPoints;
			scoreDisplay.text = String(gameScore);
		}
		
		// hier worden de speler zijn levens gedefinieerd
		public function showLives() {
			livesDisplay.text = String(playerLives);
		}
		
		// hieronder word gedefinieërd wat er gebeurt als het level voorbij is
		public function levelComplete() {
			gameMode = "done";
			var dialog:Dialog = new Dialog();
			dialog.x = 175;
			dialog.y = 100;
			addChild(dialog);
			dialog.message.text = "U made it! Well done!";
		}
		
		// hieronder word gedefinieerd wat er gebeurt als de gehele game over is
		public function gameComplete() {
			gameMode = "gameover";
			var dialog:Dialog = new Dialog();
			dialog.x = 175;
			dialog.y = 100;
			addChild(dialog);
			dialog.message.text = "You go the loot, very good of you!";
		}
		
		// een kleine check om te zien of er op de button van het dialog venster is geklikt
		public function clickDialogButton(event:MouseEvent) {
			removeChild(MovieClip(event.currentTarget.parent));
			
			// Hieronder word gedefinieërde voor een nieuw leven/level of een restart
			if (gameMode == "dead") {
				// hieronder word de hero gereset (naar de originele positie)
				showLives();
				hero.mc.x = hero.startx;
				hero.mc.y = hero.starty;
				gameMode = "play";
			} else if (gameMode == "gameover") {
				cleanUp();
				gotoAndStop("start");
			} else if (gameMode == "done") {
				cleanUp();
				nextFrame();
			}
			
			// Hier word ervoor gezorgd dat de "stage" de keyboard funtie weer krijgt
			stage.focus = stage;
		}			
		
		// hier word de game opgeschoond en word alles weggehaald
		public function cleanUp() {
			removeChild(gamelevel);
			this.removeEventListener(Event.ENTER_FRAME,gameLoop);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
		}
		
	}
	
}