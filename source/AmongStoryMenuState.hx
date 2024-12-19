//will probs rewrite this

package;

#if desktop
import Discord.DiscordClient;
#end
import WeekData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.input.mouse.FlxMouseEventManager;
import ClientPrefs;
import ChromaticAbberation;
import openfl.filters.ShaderFilter;
import flixel.math.FlxPoint;
import flixel.input.mouse.FlxMouseEvent;

using StringTools;

class AmongStoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	public static var curDifficulty:Int = 2;

	var txtWeekTitle:FlxText;
	var txtWeekNumber:FlxText;

	public static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var sprDifficultyGroup:FlxTypedGroup<FlxSprite>;
	var selectingDifficulty:Bool = false;
	var panel:FlxSprite;
	var blackPanel:FlxSprite;

	var weekHealthIcon:HealthIcon;
	var weekHealthIconLose:HealthIcon;

	var starsBG:FlxBackdrop;
	var starsFG:FlxBackdrop;
	var ship:FlxSprite;
	var shipAnimOffsets:Map<String, Array<Dynamic>>;
	var weekCircles:FlxTypedGroup<FlxSprite>;
	var weekLines:FlxTypedGroup<FlxSprite>;
	var weekXvalues:Array<Float> = [];
	var weekYvalues:Array<Float> = [];
	var canMove:Bool = true;

	public var camSpace:FlxCamera;
	public var camScreen:FlxCamera;

	var localFinaleState:FinaleState;
	var finaleAura:FlxSprite;

	var caShader:ChromaticAbberation;

	override function create()
	{
		super.create();

		Paths.clearUnusedMemory();

		localFinaleState = ClientPrefs.finaleState;

		WeekData.reloadWeekFiles(true);

		persistentUpdate = persistentDraw = true;

		camSpace = new FlxCamera(0, 100);
		camScreen = new FlxCamera();
		camScreen.bgColor.alpha = 0;

		FlxG.cameras.reset(camSpace);
		FlxG.cameras.add(camScreen,false);
		FlxG.cameras.setDefaultDrawTarget(camSpace,true);

		camSpace.zoom = 0.7;

		starsBG = new FlxBackdrop(Paths.image('freeplay/starBG', 'impostor'));
		starsBG.setPosition(111.3, 67.95);
        starsBG.antialiasing = true;
        starsBG.updateHitbox();
        starsBG.scrollFactor.set();
        add(starsBG);
        
        starsFG = new FlxBackdrop(Paths.image('freeplay/starFG', 'impostor'));
        starsFG.setPosition(54.3, 59.45);
        starsFG.updateHitbox();
        starsFG.antialiasing = true;
        starsFG.scrollFactor.set();
        add(starsFG);

		finaleAura = new FlxSprite(710, -500).loadGraphic(Paths.image('storymenu/finaleAura', 'impostor'));
        finaleAura.updateHitbox();
		finaleAura.antialiasing = true;
		finaleAura.scale.set(2.5,2.5);
        if(localFinaleState == NOT_PLAYED) add(finaleAura);

		shipAnimOffsets = new Map<String, Array<Dynamic>>();

		ship = new FlxSprite(0, 0);
		ship.antialiasing = ClientPrefs.globalAntialiasing;
		//orbyy
		ship.cameras = [camSpace];

		ship.frames = Paths.getSparrowAtlas('storymenu/ship', 'impostor');
		
		ship.animation.addByPrefix('right', 'right', 24, false);
        ship.animation.addByPrefix('down', 'down', 24, false);
        ship.animation.addByPrefix('left', 'left', 24, false);
		ship.animation.addByPrefix('up', 'up', 24, false);

		shipAddOffset('right', 10, 0);
		shipAddOffset('down', -47, 57);
		shipAddOffset('left', -54, 0);
		shipAddOffset('up', -47, -10);

		shipPlayAnim('right');

		weekCircles = new FlxTypedGroup<FlxSprite>();
		add(weekCircles);

		weekLines = new FlxTypedGroup<FlxSprite>();
		add(weekLines);

		scoreText = new FlxText(80, 170, 0, "SCORE: 49324858");
		scoreText.setFormat(Paths.font('AmaticSC-Bold.ttf'), 54, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 2;
		scoreText.cameras = [camScreen];

		txtWeekNumber = new FlxText(FlxG.width / 2.4 - 10, 40, 0, "");
		txtWeekNumber.setFormat(Paths.font('AmaticSC-Bold.ttf'), 111, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtWeekNumber.borderSize = 2.6;
		txtWeekNumber.cameras = [camScreen];

		txtWeekTitle = new FlxText(FlxG.width / 2.6, txtWeekNumber.y + 115, 0, "");
		txtWeekTitle.setFormat(Paths.font('AmaticSC-Bold.ttf'), 64, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtWeekTitle.borderSize = 1;
		txtWeekTitle.cameras = [camScreen];

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		weekHealthIcon = new HealthIcon('impostor', true);
		weekHealthIcon.x = FlxG.width / 2.4 - 115;
		weekHealthIcon.y = 55;
		weekHealthIcon.flipX = true;
		weekHealthIcon.cameras = [camScreen];

		weekHealthIconLose = new HealthIcon('impostor', true);
		weekHealthIconLose.x = FlxG.width / 2.4 + 200;
		weekHealthIconLose.y = 55;
		weekHealthIconLose.flipX = true;
		weekHealthIconLose.cameras = [camScreen];

		blackPanel = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackPanel.antialiasing = false;
        blackPanel.updateHitbox();
        blackPanel.cameras = [camScreen];
        blackPanel.alpha = 0;
        add(blackPanel);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);
		grpWeekText.cameras = [camScreen];

		var border:FlxSprite = new FlxSprite().loadGraphic(Paths.image('storymenu/border', 'impostor'));
		add(border);
		border.cameras = [camScreen];

		var back:FlxSprite = new FlxSprite(85, 65).loadGraphic(Paths.image('storymenu/menuBack', 'impostor'));
		add(back);
		back.cameras = [camScreen];

		FlxMouseEvent.add(back, function onMouseDown(back:FlxSprite){
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
			trace("worked");
		}, null);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i => week in WeekData.weeksList)
		{
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));

			var weekCircle:FlxSprite = new FlxSprite((i * 500), 50).loadGraphic(Paths.image('storymenu/circle', 'impostor'));
			weekCircle.antialiasing = ClientPrefs.globalAntialiasing;

			FlxMouseEvent.add(weekCircle, function onMouseDown(weekCircle:FlxSprite){
				if(curWeek == i && curWeek != 0){
					openDiff();
					FlxG.sound.play(Paths.sound('panelAppear', 'impostor'), 0.5);
					selectingDifficulty = true;
					selectedWeek = true;
					trace("worked2");
				}
			});

			weekCircles.add(weekCircle);
			weekXvalues.push(weekCircle.x - 95);
			weekYvalues.push(weekCircle.y - 50);
			trace(weekYvalues[i]);
		}

		add(ship);

		WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[0]));

		txtTracklist = new FlxText(FlxG.width * 0.75, 55, 0);
		txtTracklist.alignment = CENTER;
		txtTracklist.setFormat(Paths.font('AmaticSC-Bold.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtTracklist.cameras = [camScreen];
		add(txtTracklist);

		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);
		add(txtWeekNumber);

		add(weekHealthIcon);
		add(weekHealthIconLose);

		panel = new FlxSprite();
        panel.frames = Paths.getSparrowAtlas('freeplay/difficultyPanel', 'impostor');
        panel.animation.addByPrefix('idle', 'DifficultyScreenIdle', 24, false);
        panel.animation.addByPrefix('left', 'DifficultyScreenLeft', 24, false);
        panel.animation.addByPrefix('right', 'DifficultyScreenRight', 24, false);
        panel.animation.play('idle');
        panel.antialiasing = true;
        panel.updateHitbox();
        panel.scrollFactor.set();
        panel.cameras = [camScreen];
        panel.screenCenter();
        panel.visible = false;
        panel.scale.set(0, 0);
        add(panel);
		panel.cameras = [camScreen];

		FlxMouseEvent.add(panel, function onMouseDown(panel:FlxSprite){
			changeDifficulty(1);
		}, null);

		sprDifficultyGroup = new FlxTypedGroup<FlxSprite>();
		add(sprDifficultyGroup);

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			var sprDifficulty:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menudifficulties/' + CoolUtil.difficultyStuff[i][0].toLowerCase()));
			sprDifficulty.screenCenter();
			sprDifficulty.x += 15;
			sprDifficulty.ID = i;
			sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
			sprDifficulty.cameras = [camScreen];
			sprDifficultyGroup.add(sprDifficulty);
		}
		sprDifficultyGroup.visible = false;
		
		changeDifficulty();

		FlxG.camera.follow(ship, LOCKON, 1);

		changeWeek();
	
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10)
			lerpScore = intendedScore;

		scoreText.text = "HIGH SCORE:" + lerpScore;

		ship.x = FlxMath.lerp(ship.x, weekXvalues[curWeek], CoolUtil.boundTo(elapsed * 9, 0, 1));
		ship.y = FlxMath.lerp(ship.y, weekYvalues[curWeek], CoolUtil.boundTo(elapsed * 9, 0, 1));
		starsBG.x = FlxMath.lerp(starsBG.x, starsBG.x - 0.5, CoolUtil.boundTo(elapsed * 9, 0, 1));
		starsFG.x = FlxMath.lerp(starsFG.x, starsFG.x - 1, CoolUtil.boundTo(elapsed * 9, 0, 1));

		var accepted = controls.ACCEPT;

		if(localFinaleState == NOT_PLAYED){
			caShader.amount = -2 / (FlxMath.distanceToPoint(ship, FlxPoint.get(1505, 0))/100);
			camSpace.shake(0.5/FlxMath.distanceToPoint(ship, FlxPoint.get(1505, 0))/2, 0.05);
			camScreen.shake(0.3/FlxMath.distanceToPoint(ship, FlxPoint.get(1505, 0))/2, 0.05);

			//trace(caShader.amount);
		}

		if (!movedBack && !selectedWeek)
		{
			if (!selectingDifficulty && canMove)
			{
				if (controls.UI_LEFT_P || FlxG.mouse.wheel < 0)
				{
					changeWeek(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
					shipPlayAnim("left");
				}

				if (controls.UI_RIGHT_P || FlxG.mouse.wheel < 0)
				{
					changeWeek(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
					shipPlayAnim("left");
				}	
			}

				if (controls.ACCEPT && curWeek != 0)
				{
					openDiff();
					FlxG.sound.play(Paths.sound('panelAppear', 'impostor'), 0.5);
					selectingDifficulty = true;
					selectedWeek = true;
				}
				else if (controls.RESET && curWeek != 0)
				{
					persistentUpdate = false;
					openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if (controls.BACK && !movedBack && !selectedWeek && !selectingDifficulty)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					movedBack = true;
					MusicBeatState.switchState(new MainMenuState());
				}
			}
		
		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(curWeek))
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;
			for (i in 0...leWeek.length)
			{
				songArray.push(leWeek[i][0]);
			}
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "-hard";

			PlayState.storyDifficulty = 2;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyStuff.length - 1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], 2);
		#end

		sprDifficultyGroup.forEach(function(spr:FlxSprite)
		{
			spr.visible = false;
			if (curDifficulty == spr.ID)
			{
				spr.visible = true;
				if (change == 1)
				{
					spr.alpha = 0;
					spr.screenCenter();
					spr.x -= 15;
					FlxTween.tween(spr, {x: spr.x + 15, alpha: 1}, 0.1, {ease: FlxEase.circOut});
					panel.animation.play('right', true);
				}
				else if (change == -1)
				{
					spr.alpha = 0;
					spr.screenCenter();
					spr.x += 15;
					panel.animation.play('left', true);
					FlxTween.tween(spr, {x: spr.x - 15, alpha: 1}, 0.1, {ease: FlxEase.circOut});
				}
			}
		});
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if(curWeek >= -1 && curWeek < 5)
		{
			if (curWeek >= 5)
				curWeek = 0;
			if (curWeek < 0)
				curWeek = 4;
		}

		canMove = false;
		
		if (curWeek == 0)
		{
			txtTracklist.visible = false;
			txtWeekNumber.visible = false;
			txtWeekTitle.visible = false;
			weekHealthIcon.visible = false;
			weekHealthIconLose.visible = false;
			scoreText.visible = false;
		}
		else
		{
			txtTracklist.visible = true;
			txtWeekNumber.visible = true;
			txtWeekTitle.visible = true;
			weekHealthIcon.visible = true;
			weekHealthIconLose.visible = true;
			scoreText.visible = true;
		}

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;
		var leWeekName:String = leWeek.weekName;
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.setFormat(Paths.font('AmaticSC-Bold.ttf'), 64, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtWeekNumber.text = leWeekName.toUpperCase();
		if(!leWeekName.startsWith("Week")) 
			txtWeekNumber.x = ((FlxG.width / 2) - (txtWeekNumber.width / 2));
		else
			txtWeekNumber.x = FlxG.width / 2.4;
		txtWeekTitle.borderSize = 2.2;

		if(curWeek == 4) {
			txtTracklist.visible = false;
			if(localFinaleState == NOT_PLAYED){
				txtWeekTitle.color = 0xFFFF0000;
				txtWeekTitle.text = 'FINALE'; 
			}else{
				txtWeekTitle.text = 'DEFEAT';
				txtWeekTitle.color = 0xFFFFFFFF;
			}
		}
		
		

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], 2);
		#end

		weekHealthIcon.changeIcon(leWeek.songs[0][1]);
		weekHealthIconLose.changeIcon(leWeek.songs[0][1]);
		txtWeekNumber.updateHitbox();
		weekHealthIcon.animation.curAnim.curFrame = 0;
		weekHealthIconLose.animation.curAnim.curFrame = 1;

		switch (leWeek.songs.length)
		{
			case 2:
				txtTracklist.setFormat(Paths.font('AmaticSC-Bold.ttf'), 50, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				txtTracklist.borderSize = 1.8;
				txtTracklist.y = 75;
			case 3:
				txtTracklist.setFormat(Paths.font('AmaticSC-Bold.ttf'), 40, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				txtTracklist.borderSize = 1.6;
				txtTracklist.y = 62;
			case 4:
				txtTracklist.setFormat(Paths.font('AmaticSC-Bold.ttf'), 34, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				txtTracklist.borderSize = 1.5;
				txtTracklist.y = 55;
			case 5:
				txtTracklist.setFormat(Paths.font('AmaticSC-Bold.ttf'), 26, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				txtTracklist.borderSize = 1.3;
				txtTracklist.y = 58;
			default:
				txtTracklist.y = 55;
		}

		txtWeekTitle.x = ((FlxG.width / 2) - (txtWeekTitle.width / 2));

		switch(curWeek){
			case 4:
				weekHealthIcon.x = FlxG.width / 2.4 - 115;
				weekHealthIconLose.x = FlxG.width / 2.4 + 180;
				weekHealthIcon.y = 55;
				weekHealthIconLose.y = 55;
			case 5:
				weekHealthIcon.x = FlxG.width / 2.4 - 135;
				weekHealthIconLose.x = FlxG.width / 2.4 + 220;
				weekHealthIcon.y = 45;
				weekHealthIconLose.y = 45;
			case 6:
				weekHealthIcon.x = FlxG.width / 2.4 - 135;
				weekHealthIconLose.x = FlxG.width / 2.4 + 220;
				weekHealthIcon.y = 45;
				weekHealthIconLose.y = 45;
			case 7:
				weekHealthIcon.x = FlxG.width / 2.4 - 135;
				weekHealthIconLose.x = FlxG.width / 2.4 + 220;
				weekHealthIcon.y = 40;
				weekHealthIconLose.y = 40;
			case 9:
				weekHealthIcon.x = FlxG.width / 2.4 - 115;
				weekHealthIconLose.x = FlxG.width / 2.4 + 180;
				weekHealthIcon.y = 40;
				weekHealthIconLose.y = 40;
			case 10:
				weekHealthIcon.x = FlxG.width / 2.4 - 205;
				weekHealthIconLose.x = FlxG.width / 2.4 + 270;
				weekHealthIcon.y = 55;
				weekHealthIconLose.y = 55;
			case 11:
				weekHealthIcon.x = FlxG.width / 2.4 - 115;
				weekHealthIconLose.x = FlxG.width / 2.4 + 170;
				weekHealthIcon.y = 45;
				weekHealthIconLose.y = 45;
			default:
				weekHealthIcon.x = FlxG.width / 2.4 - 115;
				weekHealthIconLose.x = FlxG.width / 2.4 + 200;
				weekHealthIcon.y = 55;
				weekHealthIconLose.y = 55;
		}

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && !weekIsLocked(curWeek))
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		new FlxTimer().start(0.08, function(tmr:FlxTimer)
		{
			canMove = true;
		});
		
		updateText();
	}

	function weekIsLocked(weekNum:Int)
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[weekNum]);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		var weekArray:Array<String> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.x = ((FlxG.width / 2) - (txtTracklist.width / 2)) + 400;

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], 2);
		#end
	}

	function openDiff()
	{
		if(curWeek == 4 && localFinaleState != NOT_PLAYED){
			FlxG.sound.music.fadeOut(1.2, 0);
			camScreen.fade(FlxColor.BLACK, 1.2, false, function()
			{
				selectedWeek = true;
				camScreen.visible = false;
				camSpace.visible = false;
				openSubState(new AmongDeathSubstate());
			});
		}
		else
			selectWeek();
	}

	function shipPlayAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		ship.animation.play(animName, force, reversed, frame);

		var daOffset = shipAnimOffsets.get(animName);
		if (shipAnimOffsets.exists(animName))
		{
			ship.offset.set(daOffset[0], daOffset[1]);
		}
		else
			ship.offset.set(0, 0);
	}

	function shipAddOffset(name:String, x:Float = 0, y:Float = 0)
	{
		shipAnimOffsets[name] = [x, y];
	}
}
