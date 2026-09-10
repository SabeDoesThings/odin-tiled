> [!WARNING]
> This repository is archived. I appreciate the pull requests submitted but honestly I don't even have the project files anymore so I can't even really work on.
> If you wanna fork it and work on it yourself you are more than welcome.
> I appreciate the support I've gotten so far.

# odin-tiled
A simple [Tiled](https://www.mapeditor.org) map loader. Uses Odin's `core:json` to unmarshal data into structs.

## How to use
Put the `tiled.odin` file into a `tiled` folder somewhere in your project. Then you can just do this (the path might be different):
```odin
import "../tiled"
```
And then:
```odin
tiled_map := tiled.parse_tilemap("path/to/your/map.json")
```
and/or
```odin
tileset_data := tiled.parse_tileset("path/to/your/tileset.json")
```
Thats all you need.

Note: Base64 is not supported, only CSV is.

## Example
There are 2 examples in the [example](example/) folder. The topdown example include spritesheet animations and wall collision. They both use raylib for the tilemap rendering.

## Contributing
Contributions are welcome!
