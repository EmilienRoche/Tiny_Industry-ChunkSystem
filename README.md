# Tiny Industry: Chunk System

Chunk system from **[Tiny Industry](https://store.steampowered.com/app/5020100?utm_source=github)**, a factory automation game built with **Godot 4** and **GDScript**.

This repository is a **code sample** shared for demonstration purposes. It does not include the assets or the rest of the game, and it cannot run on its own: the script depends on scenes and systems from the main project.

## The problem

In a factory game, the player can build hundreds of buildings connected by conveyor lines. Keeping the whole factory instantiated at all times is expensive for performance.

## The solution

The world is split into **square chunks** (`chunkSize`). Only the chunks around the camera are loaded. The others are **saved, then freed from memory**.

### How it works

- **Chunk change detection**: every frame, the camera's chunk is computed. Loading is only triggered when the camera enters a new chunk.
- **Loaded area**: a square of chunks around the camera, with an adjustable size (`nbChunkLayer`).
- **Unloading**: buildings outside the area are saved, then removed (`queue_free`). This can be toggled with `unloadChunk`.
- **Buildings spanning several chunks**: the size of each building type is tested against the 8 neighboring chunks (rectangle intersection). A building is registered in every chunk it touches.
- **Conveyor lines**: a line is attached to the chunks of the buildings it connects, so it never disappears at a chunk border.
- **`chunkIndex`**: a chunk → buildings index avoids iterating over every building when unloading.

## Main file

| File | Role |
|---|---|
| `chunk_manager.gd` | Loading, unloading and saving of chunks |

## Technical highlights

- Grid-based spatial partitioning
- `Rect2` intersection tests between buildings and neighboring chunks
- Per-chunk index to limit lookups
- Loading triggered only when the camera changes chunk

## Known limitations and possible improvements

- `createNewBuildArray()` re-serializes every building each time the camera changes chunk. An improvement would be to only save the chunks that changed.
- `get_building_from_chunk()` does a linear search: a dictionary indexed by `buildId` would be faster.

## Context

- **Engine**: Godot 4
- **Language**: GDScript
- **Game**: Tiny Industry, in development ([Steam page](https://store.steampowered.com/app/5020100?utm_source=github))
- **Author**: Emilien Roche, [Loominest](https://github.com/EmilienRoche)

## License

Code shared for demonstration purposes only. **All rights reserved**: any reuse requires my permission.
