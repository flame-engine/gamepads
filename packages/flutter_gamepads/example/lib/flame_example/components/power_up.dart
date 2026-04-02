
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class PowerUp extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('power_up.png');
    anchor = Anchor.center;
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}