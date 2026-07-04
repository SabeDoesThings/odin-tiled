package tiled

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"

/*
    Based on the JSON Map Format for Tiled 1.2.
    https://doc.mapeditor.org/en/stable/reference/json-map-format/

    TODO:
        - This needs to be extensively tested. You can help by e.g.
          sending me your Tiled files (as JSON) in order to give me
          testing material.
        - Comment all fields with the description in the link above.
          Textually separate optional fields and describe them as such.
        - Add the omitempty tag where appropriate.
*/

// parse_tilemap takes a Tiled tilemap JSON file
// and converts it into an Odin data structure.
parse_tilemap :: proc(path: string, alloc: mem.Allocator) -> Map {
	m: Map
	jdata, read_err := os.read_entire_file(path, alloc)
	if read_err != nil {
		fmt.println("ODIN_TILED: Failed to read file: ", path)
		return m
	}

	err := json.unmarshal(jdata, &m, allocator = alloc)
	if err != nil {
		fmt.print("ODIN_TILED: Failed to unmarshal JSON: ", err, "\n")
		ext := filepath.ext(path)
		if ext == ".tmx" || ext == ".tsx" || ext == ".xml" {
			fmt.println("ODIN_TILED: file appears to be XML; only JSON is supported")
		}
		return m
	}
	return m
}


// tries to parse tilemap and all external tilesets.
// should probably be the default
parse_tilemap_and_tilesets :: proc(path: string, alloc: mem.Allocator) -> Map {
	m := parse_tilemap(path, alloc)
	dir := filepath.dir(path)
	for &ts in m.tilesets {
		if ts.source == "" do continue
		ts_path, _ := filepath.join({dir, ts.source}, alloc)
		external_ts := parse_tileset(ts_path, alloc)

		// check could be better
		if external_ts.type == "" {
			fmt.printfln("Couldn't parse tileset %v", ts.source)
		}

		external_ts.first_gid = ts.first_gid
		external_ts.source = ts.source
		ts = external_ts
	}
	return m
}

// parse_tileset takes a Tiled tileset JSON file
// and converts it into an Odin data structure.
parse_tileset :: proc(path: string, alloc: mem.Allocator) -> Tileset {
	ts: Tileset
	jdata, read_err := os.read_entire_file(path, alloc)
	if read_err != nil {
		fmt.print("Failed to read file: ", path, "\n")
		return ts
	}

	err := json.unmarshal(jdata, &ts, allocator = alloc)
	if err != nil {
		fmt.print("ODIN_TILED: Failed to unmarshal JSON from ", path, ": ", err, "\n")
		ext := filepath.ext(path)
		if ext == ".tmx" || ext == ".tsx" || ext == ".xml" {
			fmt.println("ODIN_TILED: File appears to be XML; only JSON is supported")
		}
		return ts
	}
	return ts
}


// parse_template :: proc(path: string, alloc: mem.Allocator = context.allocator) -> Obj

// Array of unsigned int (GIDs) or base64-encoded data
ArrayOrString :: union {
	[]i32,
	string,
}

PropertyData :: union {
	string, // String / file / color
	bool, // Bool
	i32, // Int
	f32, // Float
}

// Map.type (only one entry, "map") and Tileset.type (one entry: "tileset") could also be enum-ified if desired.

MapOrientation :: enum {
	Orthogonal,
	Isometric,
	Staggered,
	Hexagonal,
	orthogonal = Orthogonal,
	isometric = Isometric,
	staggered = Staggered,
	hexagonal = Hexagonal,
}

MapStaggerAxis :: enum {
	x,
	y,
}

// Currently unused because json string includes dashes. "right-down" etc.
// A custom unmarshaller would be needed, or an intermediate type, which is undesirable for this one instance.

// MapRenderOrder :: enum {
//  RightDown,  //"right-down"
//  RightUp,    //"right-up"
//  LeftDown,   //"left-down"
//  LeftUp,     //"left-up"
// }

LayerType :: enum {
	TileLayer,
	ObjectLayer,
	ImageLayer,
	LayerGroup,
	tilelayer = TileLayer,
	objectgroup = ObjectLayer,
	imagelayer = ImageLayer,
	group = LayerGroup,
}

LayerCompression :: enum {
	None,
	zlib,
	gzip,
	zstd,
}

LayerEncoding :: enum {
	csv,
	base64,
}

ObjectLayerDrawOrder :: enum {
	TopDown,
	Index,
	topdown = TopDown,
	index = Index,
}

GridOrientation :: enum {
	Orthogonal,
	Isometric,
	orthogonal = Orthogonal,
	isometric = Isometric,
}

// Map describes a Tiled map.
Map :: struct {
	background_color: string `json:"backgroundcolor"`, // Hex-formatted color (#RRGGBB or #AARRGGBB) (optional).
	height:           i32 `json:"height"`, // Number of tile rows.
	hex_side_length:  i32 `json:"hexsidelength"`, // Length of the side of a hex tile in pixels.
	infinite:         bool `json:"infinite"`, // Whether the map has infinite dimensions.
	layers:           []Layer `json:"layers"`, // Array of Layers.
	next_layer_id:    i32 `json:"nextlayerid"`, // Auto-increments for each layer.
	next_object_id:   i32 `json:"nextobjectid"`, // Auto-increments for each placed object.
	orientation:      MapOrientation `json:"orientation"`, // "orthogonal", "isometric", "staggered" or "hexagonal".
	properties:       []Property `json:"properties"`, // A list of properties (name, value, type).
	render_order:     string `json:"renderorder"`, // Rendering direction (orthogonal maps only).
	stagger_axis:     MapStaggerAxis `json:"staggeraxis"`, // "x" or "y" (staggered / hexagonal maps only).
	stagger_index:    string `json:"staggerindex"`, // "odd" or "even" (staggered / hexagonal maps only).
	tiled_version:    string `json:"tiledversion"`, // The Tiled version used to save the file.
	tile_height:      i32 `json:"tileheight"`, // Map grid height.
	tilesets:         []Tileset `json:"tilesets"`, // Array of Tilesets.
	tile_width:       i32 `json:"tilewidth"`, // Map grid width.
	type:             string `json:"type"`, // "map" (since 1.0).
	class:            string `json:"class"`,
	version:          f32 `json:"version"`, // The JSON format version.
	width:            i32 `json:"width"`, // Number of tile columns.
}

Property :: struct {
	name:  string `json:"name"`, // Name of property
	type:  string `json:"type"`, // Type of property value
	value: PropertyData `json:"value"`, // Value of property
}

Layer :: struct {
	// Common
	id:                i32 `json:"id"`, // Incremental id - unique across all layers
	name:              string `json:"name"`, // Name assigned to this layer
	type:              LayerType `json:"type"`, // "tilelayer, "objectgroup, "imagelayer or "group"
	visible:           bool `json:"visible"`, // Whether layer is shown or hidden in editor
	width:             i32 `json:"width"`, // Column count. Same as map width for fixed-size maps
	height:            i32 `json:"height"`, // Row count. Same as map height for fixed-size maps
	x:                 i32 `json:"x"`, // Horizontal layer offset in tiles. Always 0
	y:                 i32 `json:"y"`, // Vertical layer offset in tiles. Always 0
	offset_x:          f32 `json:"offsetx"`, // Horizontal layer offset in pixels (default: 0)
	offset_y:          f32 `json:"offsety"`, // Vertical layer offset in pixels (default: 0)
	parallax_x:        Maybe(f32) `json:"parallaxx"`, // Horizontal layer parallax, default to 1
	parallax_y:        Maybe(f32) `json:"parallaxy"`, // Vertical layer parallax, default to 1
	opacity:           f32 `json:"opacity"`, // Value between 0 and 1
	properties:        []Property `json:"properties"`, // A list of properties (name, value, type)

	// TileLayer only
	chunks:            []Chunk `json:"chunks"`, // Array of chunks (optional, for ininite maps)
	compression:       LayerCompression `json:"compression"`, // "zlib", "gzip" or empty (default)
	// data:              ArrayOrString `json:"data"`,
	data:              []i32 `json:"data"`,
	encoding:          LayerEncoding `json:"encoding"`, // "csv" (default) or "base64"

	// ObjectGroup only
	objects:           []Object `json:"objects"`, // Array of objects
	drawOrder:         ObjectLayerDrawOrder `json:"drawOrder"`, // "topdown" (default) or "index"

	// Group only
	layers:            []Layer `json:"layers"`, // Array of layers

	// ImageLayer only
	image:             string `json:"image"`, // Image used by this layer
	transparent_color: string `json:"transparentcolor"`, // Hex-formatted color (#RRGGBB) (optional)
}

// Chunk is used to store the tile layer data for infinite maps.
Chunk :: struct {
	// data:              ArrayOrString `json:"data"`,
	data:   []i32 `json:"data"`,
	height: i32 `json:"height"`, // Height in tiles
	width:  i32 `json:"width"`, // Width in tiles
	x:      i32 `json:"x"`, // X coordinate in tiles
	y:      i32 `json:"y"`, // Y coordinate in tiles
}

Object :: struct {
	id:         i32 `json:"id"`, // Incremental id - unique across all objects
	gid:        i32 `json:"gid"`, // GID, only if object comes from a Tilemap
	name:       string `json:"name"`, // String assigned to name field in editor
	type:       string `json:"type"`, // String assigned to type field in editor
	x:          f64 `json:"x"`, // X coordinate in pixels
	y:          f64 `json:"y"`, // Y coordinate in pixels
	width:      f64 `json:"width"`, // Width in pixels, ignored if using a gid
	height:     f64 `json:"height"`, // Height in pixels, ignored if using a gid
	visible:    bool `json:"visible"`, // Whether object is shown in editor
	ellipse:    bool `json:"ellipse"`, // Used to mark an object as an ellipse
	point:      bool `json:"point"`, // Used to mark an object as a point
	polygon:    []Coordinate `json:"polygon"`, // A list of x,y coordinates in pixels
	polyline:   []Coordinate `json:"polyline"`, // A list of x,y coordinates in pixels
	properties: []Property `json:"properties"`, // A list of properties (name, value, type)
	rotation:   f64 `json:"rotation"`, // Angle in degrees clockwise
	template:   string `json:"template"`, // Reference to a template file, in case object is a template instance
	text:       map[string]i32 `json:"text"`, // String key-value pairs
}

Coordinate :: struct {
	x: f32 `json:"x"`,
	y: f32 `json:"y"`,
}

Offset :: struct {
	x: f32 `json:"x"`,
	y: f32 `json:"y"`,
}

// A Tileset that associates information with each tile, like its image
// path or terrain type, may include a Tiles array property. Each tile
// has an ID property, which specifies the local ID within the tileset.
//
// For the terrain information, each value is a length-4 array where
// each element is the index of a terrain on one corner of the tile.
// The order of indices is: top-left, top-right, bottom-left, bottom-right.
Tileset :: struct {
	first_gid:         i32 `json:"firstgid"`, // GID corresponding to the first tile in the set
	source:            string `json:"source"`, // Only used if an external tileset is referred to
	name:              string `json:"name"`, // Name given to this tileset
	type:              string `json:"type"`, // "tileset" (for tileset files, since 1.0)
	columns:           i32 `json:"columns"`, // The number of tile columns in the tileset
	image:             string `json:"image"`, // Image used for tiles in this set
	image_width:       i32 `json:"imagewidth"`, // Width of source image in pixels
	image_height:      i32 `json:"imageheight"`, // Height of source image in pixels
	margin:            i32 `json:"margin"`, // Buffer between image edge and first tile (pixels)
	spacing:           i32 `json:"spacing"`, // Spacing between adjacent tiles in image (pixels)
	tile_count:        i32 `json:"tilecount"`, // The number of tiles in this tileset
	tile_width:        i32 `json:"tilewidth"`, // Maximum width of tiles in this set
	tile_height:       i32 `json:"tileheight"`, // Maximum height of tiles in this set
	transparent_color: string `json:"transparentcolor"`, // Hex-formatted color (#RRGGBB) (optional)
	tile_offset:       Offset `json:"tileoffset"`, // https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tmx-tileoffset
	grid:              Grid `json:"grid"`, // (Optional) https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tmx-grid
	properties:        []Property `json:"properties"`, // A list of properties (name, value, type)
	terrains:          []Terrain `json:"terrains"`, // Array of Terrains (optional)
	tiles:             []Tile `json:"tiles"`, // Array of Tiles (optional)
	wang_sets:         []WangSet `json:"wangsets"`, // Array of Wang sets (since 1.1.5)
}

// The Grid element is only used in case of isometric orientation,
// and determines how tile overlays for terrain and collision information are rendered.
Grid :: struct {
	orientation: GridOrientation `json:"orientation"`, // "orthogonal" or "isometric"
	width:       i32 `json:"width"`, // Width of a grid cell
	height:      i32 `json:"height"`, // Height of a grid cell
}

Tile :: struct {
	id:           i32 `json:"id"`, // Local ID of the tile
	type:         string `json:"type"`, // The type of the tile (optional)
	properties:   []Property `json:"properties"`, // A list of properties (name, value, type)
	animation:    []Frame `json:"animation"`, // Array of Frames
	terrain:      []i32 `json:"terrain"`, // Index of terrain for each corner of tile
	image:        string `json:"image"`, // Image representing this tile (optional)
	image_height: i32 `json:"imageheight"`, // Height of the tile image in pixels
	image_width:  i32 `json:"imagewidth"`, // Width of the tile image in pixels
	object_group: Layer `json:"objectgroup"`, // Layer with type "objectgroup" (optional)
}

Frame :: struct {
	duration: i32 `json:"duration"`, // Frame duration in milliseconds
	tile_id:  i32 `json:"tileid"`, // Local tile ID representing this frame
}

Terrain :: struct {
	name: string `json:"name"`, // Name of terrain
	tile: i32 `json:"tile"`, // Local ID of tile representing terrain
}

WangSet :: struct {
	corner_colors: []WangColor `json:"cornercolors"`, // Array of Wang colors
	edge_colors:   []WangColor `json:"edgecolors"`, // Array of Wang colors
	name:          string `json:"name"`, // Name of the Wang set
	tile:          i32 `json:"tile"`, // Local ID of tile representing the Wang set
	wang_tiles:    []WangTile `json:"wangtiles"`, // Array of Wang tiles
}

WangColor :: struct {
	color:       string `json:"color"`, // Hex-formatted color (#RRGGBB or #AARRGGBB)
	name:        string `json:"name"`, // Name of the Wang color
	probability: f32 `json:"probability"`, // Probability used when randomizing
	tile:        i32 `json:"tile"`, // Local ID of tile representing the Wang color
}

WangTile :: struct {
	tile_id: i32 `json:"tileid"`, // Local ID of tile
	wang_id: [8]byte `json:"wangid"`, // Array of Wang color indexes (uchar[8])
	d_flip:  bool `json:"dflip"`, // Tile is flipped diagonally
	h_flip:  bool `json:"hflip"`, // Tile is flipped horizontally
	v_flip:  bool `json:"vflip"`, // Tile is flipped vertically
}

// An ObjectTemplate is written to its own file
// and referenced by any instances of that template.
ObjectTemplate :: struct {
	type:    string `json:"type"`, // "template"
	tileset: Tileset `json:"tileset"`, // External tileset used by the template (optional)
	object:  Object `json:"object"`, // The object instantiated by this template
}
