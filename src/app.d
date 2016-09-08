
import spine;
import spine.dsfml;
import std.stdio;
import std.algorithm;
import dsfml.graphics;

class EventHandler
{
    void onStart(AnimationState state, int index)
    {
        writeln("start ", index);
    }

    void onEnd(AnimationState state, int index)
    {
        writeln("end ", index);
    }

    void onEvent(AnimationState state, int index, spine.Event e)
    {
        writefln("%s(%s,%s,%s)", e, e.get!int, e.get!float, e.get!string);
    }

    void onComplete(AnimationState state, int index, int count)
    {
        writeln("completed ", count, " times");
    }
}

void main(string[] args)
{
    string name = "spineboy";
    TextureLoader loader = new Loader;
    Atlas atlas = new Atlas("data/"~name~".atlas", loader);
    SkeletonJson json = new SkeletonJson(atlas);
    json.scale = 0.5f;
    SkeletonData skeletonData = json.readSkeletonData("data/"~name~".json");
    SkeletonDrawable drawable = new SkeletonDrawable(skeletonData);
    drawable.timeScale = 1f;

    Skeleton skeleton = drawable.skeleton;
    skeleton.setSkin("default");
    skeleton.setToSetupPose();
    skeleton.x = 320;
    skeleton.y = 590;
    skeleton.updateWorldTransform();

    auto handler = new EventHandler();
    drawable.state.start.connect(&handler.onStart);
    drawable.state.end.connect(&handler.onEnd);
    drawable.state.event.connect(&handler.onEvent);
    drawable.state.complete.connect(&handler.onComplete);

    auto track = drawable.state.setAnimation(0, "test", false);
    drawable.state.setAnimation(1, "walk", false);

    auto window = new RenderWindow(VideoMode(640,640), "Spine SFML");
    window.setFramerateLimit(60);
	window.setKeyRepeatEnabled(false);
    dsfml.window.event.Event event;
    Clock deltaClock = new Clock();
	int anim, skin;
	writeln(skeleton.data.skins);
	writeln(skeleton.data.animations);
    writeln(skeleton.data.events);
    while (window.isOpen())
    {
        while(window.pollEvent(event))
		{
            if(event.type == event.EventType.Closed)
                window.close();
			if(event.type == event.EventType.KeyPressed)
			{
				if(event.key.code == Keyboard.Key.Space)
				{
					++anim %= skeleton.data.animations.length;
					skeleton.setToSetupPose();
					auto animation = skeleton.data.animations[anim];
					foreach(timeline; animation.timelines)
					{
						auto ik = cast(IkConstraintTimeline)timeline;
						auto ffd = cast(FFDTimeline)timeline;
						if(ik !is null)
						{
							writeln(ik.frames);
						}
						if(ffd !is null)
						{
							writeln(ffd.attachment);
							writeln(ffd.frames);
							writeln(ffd.vertices.length);
						}
					}
					drawable.state.setAnimation(0, animation, true);
				}

				if(event.key.code == Keyboard.Key.S)
				{
					++skin %= skeleton.data.skins.length;
					skeleton.setSkin(skeleton.data.skins[skin]);
				}
			}
		}

        float delta = deltaClock.restart().asSeconds();//to!("seconds", float)(deltaClock.restart().to!TickDuration()); //HACKS

        drawable.update(delta);

        window.clear(Color.White);
        window.draw(drawable);
        window.display();
    }
}
