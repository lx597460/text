package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import haxe.Json;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3';
	public static var curSelected:Int = 0;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];
	
	var bg:FlxSprite;
	var camFollow:FlxObject;
	var blackBars:FlxSprite;
	
	var sideCharacters:Array<FlxSprite> = [];
	
	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		persistentUpdate = persistentDraw = true;
		
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		
		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.scale.set(0.8, 0.8);
			menuItem.updateHitbox();
			menuItems.add(menuItem);
			
			menuItem.scrollFactor.set(0, 0);
			menuItem.screenCenter(X);
		}
		
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		
		loadSideCharacters();
		
		blackBars = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBars.alpha = 0;
		blackBars.scrollFactor.set();
		add(blackBars);
		
		changeItem();
		
		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end
		
		#if mobile
		addTouchPad("UP_DOWN", "A_B_E");
		#end
		
		super.create();
		FlxG.camera.follow(camFollow, null, 9);
	}
	
	function loadSideCharacters()
	{
		var rawJson:String = null;
		
		try
		{
			if (FileSystem.exists(Paths.getPath('images/main_characters.json', TEXT)))
			{
				rawJson = File.getContent(Paths.getPath('images/main_characters.json', TEXT));
			}
		}
		catch(e:Dynamic)
		{
			trace('No main_characters.json found, skipping side characters');
		}
		
		if (rawJson == null)
		{
			try
			{
				if (Paths.fileExists('images/main_characters.json', TEXT))
				{
					rawJson = Paths.getContent('images/main_characters.json');
				}
			}
			catch(e:Dynamic)
			{
				trace('No main_characters.json found in images folder');
			}
		}
		
		if (rawJson != null && rawJson.length > 0)
		{
			try
			{
				var config:Dynamic = Json.parse(rawJson);
				for (side in ['left', 'right'])
				{
					if (Reflect.hasField(config, side))
					{
						var sideConfig = Reflect.field(config, side);
						var characters:Array<Dynamic> = sideConfig.characters;
						if (characters != null && characters.length > 0)
						{
							var randomIndex:Int = FlxG.random.int(0, characters.length - 1);
							var selected = characters[randomIndex];
							createSideCharacter(side, selected, sideConfig);
						}
					}
				}
			}
			catch(e:Dynamic)
			{
				trace('Error parsing main_characters.json: ' + e);
			}
		}
	}
	
	function createSideCharacter(side:String, charData:Dynamic, config:Dynamic)
	{
		var path:String = charData.path;
		var hasAnimation:Bool = charData.hasAnimation == true;
		var offsetX:Float = config.offsetX != null ? config.offsetX : 0;
		var offsetY:Float = config.offsetY != null ? config.offsetY : 0;
		var scaleX:Float = config.scaleX != null ? config.scaleX : 1;
		var scaleY:Float = config.scaleY != null ? config.scaleY : 1;
		var fps:Int = config.fps != null ? config.fps : 24;
		var animationName:String = charData.animationName != null ? charData.animationName : 'idle';
		
		var sprite:FlxSprite = new FlxSprite();
		sprite.antialiasing = ClientPrefs.data.antialiasing;
		
		try
		{
			if (hasAnimation)
			{
				sprite.frames = Paths.getSparrowAtlas(path);
				sprite.animation.addByPrefix('idle', animationName, fps);
				sprite.animation.play('idle');
			}
			else
			{
				sprite.loadGraphic(Paths.image(path));
			}
		}
		catch(e:Dynamic)
		{
			trace('Failed to load side character: ' + path);
			return;
		}
		
		sprite.scale.set(scaleX, scaleY);
		sprite.updateHitbox();
		
		var startX:Float = 0;
		var endX:Float = 0;
		
		if (side == 'left')
		{
			startX = -sprite.width - offsetX;
			endX = offsetX;
		}
		else
		{
			startX = FlxG.width + sprite.width + offsetX;
			endX = FlxG.width - sprite.width - offsetX;
		}
		
		sprite.x = startX;
		sprite.y = offsetY;
		
		add(sprite);
		
		var delay:Float = config.delay != null ? config.delay : 0;
		var duration:Float = config.duration != null ? config.duration : 0.8;
		
		new FlxTimer().start(delay, function(tmr:FlxTimer) {
			FlxTween.tween(sprite, {x: endX}, duration, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween) {
					if (config.loop != null && config.loop == true)
					{
						new FlxTimer().start(config.loopDelay != null ? config.loopDelay : 3, function(loopTimer:FlxTimer) {
							sprite.x = startX;
							FlxTween.tween(sprite, {x: endX}, duration, {ease: FlxEase.backOut});
						});
					}
				}
			});
		});
		
		sideCharacters.push(sprite);
	}
	
	var selectedSomethin:Bool = false;
	var hoverTweens:Array<FlxTween> = [];
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		
		if (!selectedSomethin)
		{
			for (i in 0...menuItems.length)
			{
				var item = menuItems.members[i];
				if (i == curSelected)
				{
					if (item.scale.x < 1.1)
					{
						if (hoverTweens[i] != null) hoverTweens[i].cancel();
						hoverTweens[i] = FlxTween.tween(item.scale, {x: 1.1, y: 1.1}, 0.3, {ease: FlxEase.quartOut});
					}
				}
				else
				{
					if (item.scale.x > 0.8)
					{
						if (hoverTweens[i] != null) hoverTweens[i].cancel();
						hoverTweens[i] = FlxTween.tween(item.scale, {x: 0.8, y: 0.8}, 0.3, {ease: FlxEase.quartOut});
					}
				}
			}
			
			if (controls.UI_UP_P)
				changeItem(-1);
			if (controls.UI_DOWN_P)
				changeItem(1);
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
			
			#if mobile
			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				startTransition();
			}
			else if (controls.justPressed('debug_1') || touchPad.buttonE.justPressed)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#else
			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				startTransition();
			}
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}
		super.update(elapsed);
	}
	
	function startTransition()
	{
		var selectedItem = menuItems.members[curSelected];
		FlxTween.tween(selectedItem.scale, {x: 1.5, y: 1.5}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(selectedItem, {alpha: 0}, 0.5, {ease: FlxEase.quartIn, startDelay: 0.2});
		
		for (i in 0...menuItems.length)
		{
			if (i == curSelected) continue;
			FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
		}
		
		for (char in sideCharacters)
		{
			if (char != null)
			{
				FlxTween.tween(char, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
			}
		}
		
		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			FlxTween.tween(blackBars, {alpha: 1}, 0.3, {
				ease: FlxEase.quartIn,
				onComplete: function(twn:FlxTween) {
					switch (optionShit[curSelected])
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());
						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
					}
				}
			});
		});
	}
	
	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		var oldItem = menuItems.members[curSelected];
		oldItem.animation.play('idle');
		
		curSelected += huh;
		if (curSelected >= menuItems.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuItems.length - 1;
		
		var newItem = menuItems.members[curSelected];
		newItem.animation.play('selected');
		newItem.centerOffsets();
		newItem.screenCenter(X);
		
		camFollow.setPosition(newItem.getGraphicMidpoint().x,
			newItem.getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
