# Techniques

Notes about how to accomplish various things in the codebase.

## Defining Abilities

Abilities have three parts:

1.  A Resource of type `AbilityData` containing casting properties.
2.  A scene defining what actually appears in game, of whatever type is needed (usually RigidBody3D for projectiles, StaticBody3D for shields, or just Node3D for intangible effects)
3.  A script containing the `Ability` resource for the spell and defining `cast()`:
    ```
    func cast(p_ability: Ability, parent: Node3D, origin: Vector3, p_target: Node) -> void:
    ```

Ability nodes should just be deleted when they have expired.

Abilities that are one at a time should have handles in the casting character's Node, which will be nulled out when the node is deleted by `queue_free()`.
